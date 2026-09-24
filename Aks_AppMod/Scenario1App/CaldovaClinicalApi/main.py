"""FastAPI service for the Caldova clinical material inventory."""

from __future__ import annotations

import logging
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import date

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import Date, ForeignKey, Integer, String, select, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
LOGGER = logging.getLogger(__name__)

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://caldova:caldova@localhost:5432/drugs",
)
ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv("ALLOWED_ORIGINS", "http://localhost:5173").split(",")
    if origin.strip()
]

engine = create_async_engine(DATABASE_URL, pool_pre_ping=True)
SessionFactory = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    """Base class for database models."""


class MaterialRecord(Base):
    """Clinical material definition shared by one or more inventory lots."""

    __tablename__ = "materials"
    __table_args__ = {"schema": "pharmacy"}

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    category_id: Mapped[int] = mapped_column(
        ForeignKey("pharmacy.categories.id"), nullable=False
    )
    unit: Mapped[str] = mapped_column(String(30), nullable=False)
    reorder_level: Mapped[int] = mapped_column(Integer, nullable=False)
    image_url: Mapped[str] = mapped_column(String(500), nullable=False)


class CategoryRecord(Base):
    """Material classification used for filtering and reporting."""

    __tablename__ = "categories"
    __table_args__ = {"schema": "pharmacy"}

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)


class LocationRecord(Base):
    """Physical storage location for a clinical inventory lot."""

    __tablename__ = "locations"
    __table_args__ = {"schema": "pharmacy"}

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    storage_type: Mapped[str] = mapped_column(String(30), nullable=False)


class InventoryLotRecord(Base):
    """Stock level and expiry information for one received material lot."""

    __tablename__ = "inventory_lots"
    __table_args__ = {"schema": "pharmacy"}

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    material_id: Mapped[int] = mapped_column(
        ForeignKey("pharmacy.materials.id"), nullable=False
    )
    location_id: Mapped[int] = mapped_column(
        ForeignKey("pharmacy.locations.id"), nullable=False
    )
    lot_number: Mapped[str] = mapped_column(String(40), unique=True, nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(30), nullable=False)
    expiry_date: Mapped[date] = mapped_column(Date, nullable=False)


class StudyRecord(Base):
    """Clinical study that consumes materials from the shared inventory."""

    __tablename__ = "studies"
    __table_args__ = {"schema": "pharmacy"}

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    protocol_code: Mapped[str] = mapped_column(String(40), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    status: Mapped[str] = mapped_column(String(30), nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date)


class StudyMaterialRecord(Base):
    """Quantity of a material reserved for a clinical study."""

    __tablename__ = "study_materials"
    __table_args__ = {"schema": "pharmacy"}

    study_id: Mapped[int] = mapped_column(
        ForeignKey("pharmacy.studies.id"), primary_key=True
    )
    material_id: Mapped[int] = mapped_column(
        ForeignKey("pharmacy.materials.id"), primary_key=True
    )
    required_quantity: Mapped[int] = mapped_column(Integer, nullable=False)


class Material(BaseModel):
    """Public clinical material representation."""

    id: int
    name: str
    category: str
    lot_number: str
    quantity: int
    unit: str
    status: str
    location: str
    expiry_date: date
    image_url: str


class HealthStatus(BaseModel):
    """Health probe response."""

    status: str
    database: str


async def get_session() -> AsyncIterator[AsyncSession]:
    """Yield a database session for one request."""

    async with SessionFactory() as session:
        yield session


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    """Release database connections when the service stops."""

    yield
    await engine.dispose()


app = FastAPI(
    title="Caldova Clinical API",
    summary="Clinical material inventory service",
    version="1.0.0",
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["Content-Type"],
)


@app.get("/health", response_model=HealthStatus, tags=["health"])
async def health(session: AsyncSession = Depends(get_session)) -> HealthStatus:
    """Report service and database readiness."""

    try:
        await session.execute(text("SELECT 1"))
    except SQLAlchemyError as error:
        raise HTTPException(status_code=503, detail="Database is unavailable") from error
    return HealthStatus(status="healthy", database="connected")


@app.get("/materials", response_model=list[Material], tags=["inventory"])
async def list_materials(
    session: AsyncSession = Depends(get_session),
) -> list[Material]:
    """Return the clinical inventory stored in PostgreSQL."""

    try:
        statement = (
            select(
                MaterialRecord.id,
                MaterialRecord.name,
                CategoryRecord.name.label("category"),
                InventoryLotRecord.lot_number,
                InventoryLotRecord.quantity,
                MaterialRecord.unit,
                InventoryLotRecord.status,
                LocationRecord.name.label("location"),
                InventoryLotRecord.expiry_date,
                MaterialRecord.image_url,
            )
            .join(CategoryRecord, CategoryRecord.id == MaterialRecord.category_id)
            .join(
                InventoryLotRecord,
                InventoryLotRecord.material_id == MaterialRecord.id,
            )
            .join(LocationRecord, LocationRecord.id == InventoryLotRecord.location_id)
            .order_by(MaterialRecord.name, InventoryLotRecord.expiry_date)
        )
        records = (await session.execute(statement)).mappings().all()
    except SQLAlchemyError as error:
        LOGGER.exception("Material query failed")
        raise HTTPException(
            status_code=503,
            detail="Clinical inventory is unavailable. Check the PostgreSQL connection.",
        ) from error

    return [Material.model_validate(record) for record in records]