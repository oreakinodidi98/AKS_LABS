# Download the Windows amd64 binary
Invoke-WebRequest -Uri "https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility/releases/download/v1.0.0/agc-migration-1.0.0-windows-amd64.exe" -OutFile "agc-migration.exe"
write-Output "Downloaded AGC Migration Utility binary"

# Run it
.\agc-migration.exe --help

# run in dry-run mode to see what the migration report looks like directly from cluster
./agc-migration cluster --provider nginx --ingress-class nginx --dry-run

# run in dry-run mode to see what the migration report looks like
./agc-migration files --provider nginx --ingress-class nginx --dry-run ./manifests/*.yaml

# Review migration report