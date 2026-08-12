import logging
import os

from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import SystemMessage, UserMessage
from azure.identity import DefaultAzureCredential
from mcp.server.fastmcp import FastMCP
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Read environment variables
TITLE = os.getenv("TITLE", "MCP server running on AKS Automatic, powered by Microsoft Foundry")
AGENT_INSTRUCTIONS = os.getenv("SYSTEM_PROMPT", "You are a helpful assistant reachable through the Model Context Protocol.")
TEMPERATURE = float(os.getenv("TEMPERATURE", "0.5"))
MODEL_ENDPOINT = os.getenv("MODEL_ENDPOINT", "https://ore-mcp-foundry.services.ai.azure.com/models")
MODEL_DEPLOYMENT = os.getenv("MODEL_DEPLOYMENT", "gpt-5.4-mini")
PORT = int(os.environ.get("PORT", 8080))

credential = DefaultAzureCredential()
model_client = ChatCompletionsClient(
    endpoint=MODEL_ENDPOINT,
    credential=credential,
    credential_scopes=["https://ai.azure.com/.default"],
)

# stateless_http lets replicas serve requests independently, since AKS load balances across pods with no session affinity.
mcp = FastMCP(TITLE, host="0.0.0.0", port=PORT, stateless_http=True)

@mcp.tool()
def ask_foundry(prompt: str) -> str:
    """Send a prompt to the Microsoft Foundry model deployment and return the model's response."""
    try:
        completion = model_client.complete(
            model=MODEL_DEPLOYMENT,
            messages=[SystemMessage(content=AGENT_INSTRUCTIONS), UserMessage(content=prompt)],
            temperature=TEMPERATURE,
        )
        return completion.choices[0].message.content
    except Exception as e:
        logging.exception(f"Exception in ask_foundry: {e}")
        raise


if __name__ == "__main__":
    mcp.run(transport="streamable-http")