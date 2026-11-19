# Caldova Bakery

An **ASP.NET Core 8.0 MVC** workshop application using **Entity Framework Core
8.0.34**. Local runs default to **SQLite**; **SQL Server** is available for
Docker/AKS. No authentication is included.

> .NET 8 reached [end of support](https://dotnet.microsoft.com/platform/support/policy/dotnet-core)
> on November 10, 2026. This application is for isolated, local workshop demos only.
> Do not expose it publicly, enter real customer information, or use it for a
> real business. Anyone who can reach the app can change or delete products.

## Included

- Home, Our Bakes, product details, Our Story, Contact and Find Us pages.
- Persistent product CRUD at `/Admin`, with create, edit and delete views.
- Product ID primary key, name, decimal USD price, image path, description and category.
- Search and category filters, session basket, quantity updates and removal.
- Pickup checkout and a database-backed order summary scoped to the current session.
- Server-side validation, antiforgery protection on POSTs and server-side totals.
- Six sample products and locally bundled bakery photos and Lucide icons.
- Multi-stage Linux Dockerfile and Docker Compose with persistent SQL storage.

Checkout records a **demo pickup order only**. It does not collect payments,
calculate tax, send email, reserve stock, schedule pickup or arrange delivery.
The contact address and store location are illustrative.

For Module 3, [run without Docker](#run-without-docker). Containerization is
covered in the next module.

## Run With Docker (Next Module)

Prerequisites: Docker Desktop running **Linux containers**, Docker Compose v2,
an internet connection for the initial image pulls, and at least 4 GB of free
Docker memory. SQL Server requires an x86-64 Linux environment. Both services
specify `linux/amd64`; ARM hosts require working x86-64 emulation, which is not a
supported SQL Server production configuration. Use an x86-64 host if it fails.

From this directory in PowerShell, set `BAKERY_SQL_PASSWORD` privately in your
terminal to a strong disposable demo password, or put it in a local `.env`
using the variable names in [.env.example](.env.example). Never commit it.
SQL Server requires at least eight characters with uppercase, lowercase,
numeric and symbol characters. Avoid semicolons, quotes and dollar signs in
this demo password because it is interpolated into a connection string.

```powershell
docker compose up --build -d --wait --wait-timeout 240
```

Open **http://localhost:5080**. Admin: **http://localhost:5080/Admin**.
Set `BAKERY_PORT` before starting if 5080 is already in use.

SQL Server is private to the Compose network; it has no published host port.
Compose explicitly sets `DatabaseProvider=SqlServer` and supplies its connection
string. The local SQLite file is excluded from Docker builds and is not used.
The app waits for SQL health, creates a fresh database schema with
`EnsureCreatedAsync`, and seeds products only if the product table is empty.
SQL Server and application health checks report startup status.

```powershell
docker compose ps
docker compose logs bakery sql
docker compose down
```

`docker compose down` preserves data. To intentionally erase all demo orders,
products and data-protection keys, use `docker compose down --volumes`.
Changing the password environment variable does not change the SA password in
an existing database volume: retain the original value or intentionally reset
the disposable data volume.

The Dockerfile uses the .NET 8 SDK and ASP.NET Core 8 runtime images, with a
non-root runtime user and HTTP listening on port 8080 inside the container.
Its SDK stage runs on the builder's native CPU, even when targeting an x64
runtime image from ARM64. NuGet.org is the default package feed. If Docker
restore fails with `NU1301`, see the
[Module 4 troubleshooting steps](../../04.Dockerfile.md#if-package-restore-fails-with-nu1301)
to supply an approved mirror with the `NUGET_SOURCE` build argument. For Compose,
build first with that argument, then start without rebuilding:

```powershell
docker compose build --build-arg NUGET_SOURCE=https://packagefeedproxy.microsoft.io/nuget/v3/index.json
docker compose up --no-build -d --wait --wait-timeout 240
```

The example mirror is specific to this lab environment. Use your organization's
approved feed elsewhere. Build arguments must not contain credentials.

## Run Without Docker

Install the [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0), which
includes the ASP.NET Core 8 runtime. Choose the installer matching your machine:
**Arm64** on Windows ARM or **x64** on Intel/AMD Windows. A newer SDK can build
`net8.0`, but you still need **Microsoft.AspNetCore.App 8.0.x** and
**Microsoft.NETCore.App 8.0.x** to run it; .NET 10 runtimes alone are insufficient.

No database installation, Docker, login or connection string is required.
The app uses SQLite by default and creates `caldova-bakery.db` in the app's
working directory on first startup. Run these commands from this directory:

```powershell
dotnet --list-runtimes
dotnet restore
dotnet run --urls http://localhost:5080
```

Open **http://localhost:5080**. Products and orders persist in the database file.
The app directory must be writable. SQLite's `-wal`, `-shm` and `-journal` files
are working files; do not remove or copy them independently while the app runs.
Local database files are excluded from Git and Docker build contexts.

An old `ConnectionStrings__BakeryDatabase` value is ignored in SQLite mode.
If you previously selected SQL Server, remove the `DatabaseProvider` environment
override to return to the default. The [Module 3 guide](../../03.AppSetUp.md)
includes local cleanup and reset instructions.

No credentials are stored in the repository. `AllowedHosts` permits only
localhost/127.0.0.1 by default. Deliberate use of a different hostname requires
an explicit `AllowedHosts` configuration override.

## Optional SQL Server

Keep the default SQLite setup for Module 3. Docker Compose selects SQL Server
automatically. For a manually configured Docker/AKS deployment, explicitly set
`DatabaseProvider=SqlServer` and provide `ConnectionStrings__BakeryDatabase`
through the deployment's secret configuration. A connection string alone does
not switch providers. Unknown provider names are rejected rather than silently
falling back to SQLite.

For native SQL Server runs, provide SQL Server 2016 or newer and a login allowed
to create the demo database and tables. Database compatibility level must be
**130 or higher** because EF Core 8 uses `OPENJSON` for the basket's product-ID
query. See [EF Core 8 SQL Server compatibility](https://learn.microsoft.com/ef/core/what-is-new/ef-core-8.0/breaking-changes#contains-in-linq-queries-may-stop-working-on-older-sql-server-versions).
SQL Server 2022 Express LocalDB is an option on x64 Windows, but it is not
available natively on Windows ARM64. ARM64 clients need SQL Server running on
another supported machine.

Use this connection-string shape with your own values:

```text
Server=YOUR_SQL_HOST;Database=CaldovaBakery;User Id=YOUR_USER;Password=YOUR_PASSWORD;Encrypt=True;TrustServerCertificate=True
```

In PowerShell 7.1 or later, enter the connection string privately at the prompt
so its value does not appear in command history:

```powershell
$env:DatabaseProvider = 'SqlServer'
$env:ConnectionStrings__BakeryDatabase = Read-Host 'SQL Server connection string' -MaskInput
dotnet run --urls http://localhost:5080
```

`TrustServerCertificate=True` is for an isolated demo's self-signed SQL
certificate only. Configure a trusted certificate for any real environment.
To return to SQLite, stop the app and clear these terminal overrides:

```powershell
Remove-Item Env:DatabaseProvider -ErrorAction SilentlyContinue
Remove-Item Env:ConnectionStrings__BakeryDatabase -ErrorAction SilentlyContinue
dotnet run --urls http://localhost:5080
```

The providers use separate databases. Switching providers does not copy data or
delete the previous database. Back up any existing demo data before changes.

## Exercise the Demo

1. Browse Our Bakes and filter by category or search by name.
2. Open a product and add it to the basket. Change quantity or remove it.
3. Check out using fictional contact details. Review the saved order summary.
4. Open Manage Products in the footer, add a product, edit it and delete it.
5. Revisit Last Order: saved line-item names and prices remain unchanged.

Local image paths include `/images/croissant.jpg`, `/images/sourdough.jpg`,
`/images/cake.jpg`, `/images/cookie.jpg`, `/images/bun.jpg` and `/images/muffin.jpg`.
Admins can also use HTTPS image URLs. Images are referenced, not uploaded.

## Validate

```powershell
dotnet build CaldovaBakery.csproj
./tests/SmokeTest.ps1 -BaseUrl http://localhost:5080
```

The smoke test requires PowerShell 7 and a running application with either provider.
It checks page availability, validation, antiforgery enforcement, create/edit/
delete, basket quantity bounds, checkout, order snapshots and session isolation.
It creates and deletes a uniquely named product, and leaves one fictional order
as evidence in the database. Run it only against disposable demo data.

For visual checks, browse at desktop and mobile widths, confirm every photo
loads, and exercise the basket, checkout and admin forms with keyboard navigation.

## Design and Limitations

The project file builds the entire application; no solution file is required.
Controllers, models and Razor views follow MVC. EF Core maps `Products`,
`Orders` and `OrderItems` to the selected provider. Prices use .NET `decimal`,
stored as text in SQLite and as `decimal(10,2)` in SQL Server. Totals are
calculated in .NET. Orders snapshot names and prices, so product deletion does not
delete receipts. Missing products are removed from baskets on the next read.
The current database price is used when checkout is submitted. The optional
`ConnectionStrings__SqliteDatabase` setting can override the default SQLite
connection string (`Data Source=caldova-bakery.db`).

Schema initialization uses `EnsureCreated`, not migrations. It is suitable for
a fresh demo database only. The SQL Server schema is unchanged by the SQLite
option. Schema changes require an intentional database reset or a
separately designed migration strategy; do not point at an unrelated app DB.
If all products are deleted, a restart seeds the sample products again.

The in-memory session cart expires after 60 idle minutes and is lost on app
restart. Use one app replica only. Persistent database orders survive restarts, but
the session-only Last Order link does not. Checkout is not idempotent under
concurrent submissions or an ambiguous network failure; do not blindly retry
orders. The demo uses SA for initial database creation, not least-privilege
production access. Store and map embeds require internet access; Google Fonts
has local font fallbacks. See [ASSETS.md](ASSETS.md) for asset provenance.