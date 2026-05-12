# ARO MCP

## install

Install the Azure MCP Server binary
# Option A: Install from the official Azure MCP NuGet tool
dotnet tool install --global Azure.Mcp

Authenticate with Azure
On Windows, the Azure CLI may fail with AADSTS or token cache errors on first use. Run this once to fix:

az account clear
az config set core.enable_broker_on_windows=false
az login
az account set --subscription <YOUR_SUBSCRIPTION_ID>
Note: The az account clear and az config set steps are only needed once. After that, az login works reliably.

Configure VS Code MCP Server
The repo includes .vscode/mcp.json which auto-registers the server when you open the workspace. No manual setup needed.

To add it to another workspace or globally, add this to your VS Code settings.json:

{
  "mcp": {
    "servers": {
      "aro-mcp-server": {
        "type": "stdio",
        "command": "dotnet",
        "args": [
          "run", "--project",
          "/path/to/aro-mcp-server/tools/Azure.Mcp.Tools.Aro/src/Azure.Mcp.Tools.Aro.csproj",
          "--", "server", "start", "--transport", "stdio"
        ]
      }
    }
  }
}