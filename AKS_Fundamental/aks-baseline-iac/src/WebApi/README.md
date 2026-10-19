# WebApi

A sample .NET 8 Web API for the AKS baseline architecture.

## Features

- RESTful API for managing products
- Entity Framework Core with SQL Server
- Health check endpoints
- Swagger/OpenAPI documentation
- Docker support

## Endpoints

- `GET /api/products` - Get all products
- `GET /api/products/{id}` - Get product by ID
- `POST /api/products` - Create a new product
- `PUT /api/products/{id}` - Update a product
- `DELETE /api/products/{id}` - Delete a product
- `GET /health` - Health check
- `GET /health/ready` - Readiness check

## Running Locally

```bash
dotnet run
```

## Building Docker Image

```bash
docker build -t webapi:latest .
```

## Configuration

Set the connection string in appsettings.json or via environment variable:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=...;Database=...;User Id=...;Password=...;"
  }
}
```
