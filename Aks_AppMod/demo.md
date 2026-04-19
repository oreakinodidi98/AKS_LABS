# Spring PetClinic Demo - AKS Modernization

A step-by-step guide to running the Spring PetClinic application locally before deploying to Azure Kubernetes Service.

---

## Prerequisites

Before starting, ensure the following are configured:

1. **Docker Desktop** - Switch to Linux containers:
   ```powershell
   & "C:\Program Files\Docker\Docker\DockerCli.exe" -SwitchLinuxEngine
   ```

2. **Java 17+** installed and available in PATH

3. **Native PostgreSQL stopped** (if installed):
   ```powershell
   Stop-Service -Name "postgresql*"
   ```

---

## Running PetClinic Locally

### Option A: Quick Start with H2 (In-Memory Database)

Best for quick testing - no database setup required.

```powershell
cd spring-petclinic
.\mvnw spring-boot:run
```

Access the app at: **http://localhost:8080**

---

### Option B: With PostgreSQL (Docker)

Use this to match the production environment.

#### Step 1: Start PostgreSQL Container

```powershell
docker run -d --name petclinic-postgres `
  -e POSTGRES_USER=petclinic `
  -e POSTGRES_PASSWORD=petclinic `
  -e POSTGRES_DB=petclinic `
  -p 5432:5432 `
  postgres:15
```

#### Step 2: Wait for Database to Initialize

```powershell
Start-Sleep -Seconds 10
```

#### Step 3: Run the Application

```powershell
cd spring-petclinic
.\mvnw spring-boot:run "-Dspring-boot.run.profiles=postgres"
```

Access the app at: **http://localhost:8080**

#### Step 4: Explore the Application

- Once running try features like find owners, View owner details , Edit pet information or review Veterinarians

### App Mod

- Will use GitHub Copilot app modernization to assess, remediate, and modernize the Spring Boot application in preparation to migrate the workload to AKS

1. Select GitHub Copilot app modernization extension
2. Run Assesment
3. can follow the progress of the assesment by looking at the output Terminal in VS Code.
4. Assessment results are consumed by GitHub Copilot App Modernization . 
   1. This examines the scan findings and produces targeted modernization recommendations to prepare the application for containerization and migration to Azure.
      1. **target**: the desired runtime or Azure compute service you plan to move the app to.
         1. **azure-aks**: Best practices for deploying an app to Azure Kubernetes Service.
         2. **azure-appservice**: Best practices for deploying an app to Azure App Service.
         3. **azure-container-apps**: Best practices for deploying an app to Azure Container Apps.
      2. **capability**: what technology to modernize the apps towards.
         1. **containerization**: Best practices for containerizing applications.
      3. **mode**: Choose how deep AppCAT should inspect the project.
         1. **issue-only**: Analyze source code to only detect issues
         2. **source-only**: Fast analysis that examines source code only.
         3. **full**: Full analysis -> inspects source code and scans dependencies (slower, more thorough).
      4. **os**: best practices tailored for specific operating systems that AppCAT should use when migrating applications (windows or Linux). 
5. You Ean edit the file at ```.github/appmod-java/appcat/assessment-config.yaml``` to change targets and modes.
6. Review Results:
   1. The assessment analyzed the Spring Boot Petclinic application for cloud migration readiness and identified the following: **X** cloud readiness issues requiring attention
   2. **Resolution Approach**: More than **30%** of the identified issues can be automatically resolved through code and configuration updates using GitHub Copilot's built-in app modernization capabilities.
   3. **Issue Prioritization**: Issues are categorized by urgency level to guide remediation efforts:
      1. **Mandatory** (Purple) - Critical issues that must be addressed before migration.
      2. **Potential** (Blue) - Performance and optimization opportunities.
      3. **Optional** (Gray) - Nice-to-have improvements that can be addressed later.
      4. prioritization framework ensures teams focus on blocking issues first while identifying opportunities for optimization and future enhancements.
7. Review task and take action on finding
   1. Migrate to azure DB for postgressSQLModernization change: This will update the Java code to work with PostgreSQL Flexible Server using Entra ID authentication
   2. Tool will execute the appmod-run-task command for mi-postgresql-spring, which will examine the workspace structure and initiate the migration task 
   3. Generates a comprehensive migration plan
   4. The plan outlines the specific changes needed to implement Azure Managed Identity authentication for PostgreSQL connectivity

---

## Troubleshooting

### Port 8080 Already in Use

1. Find the process using the port:
   ```powershell
   netstat -ano | findstr :8080
   ```

2. Get process details (replace `<PID>` with the ID from step 1):
   ```powershell
   Get-Process -Id <PID>
   ```

3. Stop the process:
   ```powershell
   Stop-Process -Id <PID> -Force
   ```

**Alternative:** Run PetClinic on a different port:
```powershell
.\mvnw spring-boot:run "-Dspring-boot.run.profiles=postgres" "-Dserver.port=8081"
```

---

### PostgreSQL Connection Issues

**Reset the Docker container:**

```powershell
docker stop petclinic-postgres
docker rm petclinic-postgres
```

Then restart from [Step 1](#step-1-start-postgresql-container).

**Check if native PostgreSQL is running:**

```powershell
netstat -ano | findstr :5432
```

If occupied, stop the native service:
```powershell
Stop-Service -Name "postgresql*"
```

---

## Archive (Legacy Commands)

<details>
<summary>Click to expand alternative configurations</summary>

### Manual Database Configuration

```powershell
.\mvnw clean compile; .\mvnw spring-boot:run `
  "-Dspring-boot.run.arguments=--spring.messages.basename=messages/messages --spring.datasource.url=jdbc:postgresql://localhost/petclinic --spring.sql.init.mode=always --spring.sql.init.schema-locations=classpath:db/postgres/schema.sql --spring.sql.init.data-locations=classpath:db/postgres/data.sql --spring.jpa.hibernate.ddl-auto=none"
```

### Simplified PostgreSQL Profile

```powershell
.\mvnw spring-boot:run "-Dspring-boot.run.arguments=--spring.datasource.url=jdbc:postgresql://localhost/petclinic --spring.sql.init.mode=always --spring.profiles.active=postgres"
```

</details>