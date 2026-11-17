# Caldova Bakery

A deliberately legacy **ASP.NET Core 3.0 MVC** workshop application backed by
**SQL Server** and **Entity Framework Core 3.0.3**. No authentication is included.

> ASP.NET Core 3.0, EF Core 3.0 and the container operating system are out of
> support. This application is for isolated, local modernization demos only.
> Do not expose it publicly, enter real customer information, or use it for a
> real business. Anyone who can reach the app can change or delete products.

## Included

- Home, Our Bakes, product details, Our Story, Contact and Find Us pages.
- SQL Server product CRUD at `/Admin`, with create, edit and delete views.
- Product ID primary key, name, decimal USD price, image path, description and category.
- Search and category filters, session basket, quantity updates and removal.
- Pickup checkout and a SQL-backed order summary scoped to the current session.
- Server-side validation, antiforgery protection on POSTs and server-side totals.
- Six sample products and locally bundled bakery photos and Lucide icons.
- Multi-stage Linux Dockerfile and Docker Compose with persistent SQL storage.

Checkout records a **demo pickup order only**. It does not collect payments,
calculate tax, send email, reserve stock, schedule pickup or arrange delivery.
The contact address and store location are illustrative.

## Run With Docker (Recommended)

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

The archived .NET 3.0 images may not be available in every environment. The
Dockerfile uses historical `dotnet/core` image repositories intentionally.
Do not silently substitute a modern runtime if the purpose is a legacy demo.

## Run Without Docker

Install the archived .NET Core 3.0 SDK (3.0.103), or a newer SDK capable of
compiling `netcoreapp3.0`, **and the ASP.NET Core 3.0 runtime**. Installing only
a modern SDK/runtime is not enough to run this app. Provide a running SQL Server
instance and a login allowed to create the demo database and tables.
ASP.NET Core 3.0 has no native Windows ARM64 runtime. On Windows ARM, use the
Linux x86-64 container route with working emulation or a separate x86-64 host;
the installed ARM64 .NET 10 runtime cannot run this application.

Set `ConnectionStrings__BakeryDatabase` privately in your terminal, using this
connection-string shape with your own values:

```text
Server=YOUR_SQL_HOST;Database=CaldovaBakery;User Id=YOUR_USER;Password=YOUR_PASSWORD;Encrypt=True;TrustServerCertificate=True
```

`TrustServerCertificate=True` is for the isolated demo's self-signed SQL
certificate only. Configure a trusted certificate for any real environment.

```powershell
dotnet restore
dotnet build --no-restore
dotnet run --urls http://localhost:5080
```

No credentials are stored in the repository. `AllowedHosts` permits only
localhost/127.0.0.1 by default. Deliberate use of a different hostname requires
an explicit `AllowedHosts` configuration override.

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

The smoke test requires PowerShell 7 and a running application with SQL Server.
It checks page availability, validation, antiforgery enforcement, create/edit/
delete, basket quantity bounds, checkout, order snapshots and session isolation.
It creates and deletes a uniquely named product, and leaves one fictional order
as evidence in the database. Run it only against disposable demo data.

For visual checks, browse at desktop and mobile widths, confirm every photo
loads, and exercise the basket, checkout and admin forms with keyboard navigation.

## Design and Limitations

The project file builds the entire application; no solution file is required.
Controllers, models and Razor views follow MVC. EF Core maps `Products`,
`Orders` and `OrderItems` to SQL Server. Product prices and order prices use
`decimal(10,2)`. Orders snapshot names and prices, so product deletion does not
delete receipts. Missing products are removed from baskets on the next read.
The current SQL price is used when checkout is submitted.

Schema initialization uses `EnsureCreated`, not migrations. It is suitable for
a fresh demo database only. Schema changes require an intentional database reset
or a separately designed migration strategy; do not point at an existing app DB.
If all products are deleted, a restart seeds the sample products again.

The in-memory session cart expires after 60 idle minutes and is lost on app
restart. Use one app replica only. Persistent SQL orders survive restarts, but
the session-only Last Order link does not. Checkout is not idempotent under
concurrent submissions or an ambiguous network failure; do not blindly retry
orders. The demo uses SA for initial database creation, not least-privilege
production access. Store and map embeds require internet access; Google Fonts
has local font fallbacks. See [ASSETS.md](ASSETS.md) for asset provenance.