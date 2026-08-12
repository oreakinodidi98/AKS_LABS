# Foundry Chatbot (Streamlit) on AKS Automatic

This folder (`AKS_Automatic/FoundryChatbot`) contains a **Streamlit** chatbot web app (`chatbot.py`) that talks to a chat model deployed in **Microsoft Foundry**. It's designed to run locally for development and to be containerized and deployed on an **AKS Automatic** cluster.

Instead of storing a model API key, the app authenticates with `DefaultAzureCredential` — so locally it uses your Azure CLI login, and in the cluster each pod exchanges its Kubernetes service account token for a Microsoft Entra token at runtime (workload identity). No secrets sit in your cluster config.

## Contents

| File | Purpose |
| --- | --- |
| `chatbot.py` | Streamlit chatbot app powered by a Microsoft Foundry model |
| `requirements.txt` | Python dependencies (matches the container build) |
| `.env` | Local environment variables (title, prompt, model endpoint/deployment, etc.) |
| `Dockerfile` | Builds the container image (runs `streamlit run chatbot.py`) |
| `deployment.yaml` / `service.yaml` | Kubernetes manifests for AKS |
| `setup.ps1` | Provisioning helper script |
| `image/chatbot.png` | Logo shown in the UI |

## Prerequisites

- Python 3.11+ (a local `.venv` is already present in this folder)
- Azure CLI logged in (`az login`) with access to the Microsoft Foundry resource and model deployment
- For deployment: Azure CLI that supports `az aks create --sku automatic`, plus `kubectl` and `yq`

## Configuration

The app reads its settings from environment variables (loaded from `.env` via `python-dotenv`):

| Variable | Default | Description |
| --- | --- | --- |
| `TITLE` | `Foundry chatbot` | Header shown in the UI |
| `SYSTEM_PROMPT` | helpful-assistant prompt | System prompt sent to the model |
| `TEMPERATURE` | `0.5` | Sampling temperature |
| `MODEL_ENDPOINT` | Foundry models endpoint | Your Foundry `.../models` endpoint |
| `MODEL_DEPLOYMENT` | `gpt-5.4-mini` | Name of the deployed model |
| `PORT` | `8080` | Port used when containerized |
| `IMAGE_NAME` | `chatbot.png` | Logo file inside the `image/` folder |

Update `.env` so `MODEL_ENDPOINT` and `MODEL_DEPLOYMENT` point at your own Foundry resource.

## Run the app locally

From this folder (`AKS_Automatic/FoundryChatbot`):

1. Sign in to Azure so `DefaultAzureCredential` can get a token:

   ```powershell
   az login
   ```

2. Activate the virtual environment and install dependencies:

   ```powershell
   .\.venv\Scripts\Activate.ps1
   python -m pip install -r requirements.txt
   ```

3. Launch the Streamlit app (use `streamlit run`, **not** `python chatbot.py`):

   ```powershell
   streamlit run chatbot.py
   ```

   Streamlit prints a local URL (default `http://localhost:8501`) and opens it in your browser.

To match the container's port, run:

```powershell
streamlit run chatbot.py --server.port 8080
```

## Test the app

- **Smoke test the UI** — open the browser URL, type a question in the input box, press **Post**, and confirm a response comes back. Each answer is tagged with the hostname that served it (useful for confirming which pod replied once deployed). Use **Clean** to reset the conversation.
- **Verify dependencies are installed** in the active venv:

  ```powershell
  python -c "import streamlit, dotenv, azure.ai.inference, azure.identity; print('deps OK')"
  ```

- **Check the app imports without runtime errors:**

  ```powershell
  python -c "import chatbot; print('import OK')"
  ```

- **Confirm Azure auth works** (should return a token silently):

  ```powershell
  az account get-access-token --scope https://ai.azure.com/.default --query expiresOn -o tsv
  ```

If a request fails, check the terminal running Streamlit — exceptions from the model call are logged there via `logging.exception`.

## Build and run the container

```powershell
docker build -t foundry-chatbot .
docker run -p 8080:8080 foundry-chatbot
```

Then browse to `http://localhost:8080`.

## Deploy to AKS Automatic

AKS Automatic handles node provisioning, autoscaling, and workload identity for you. After building and pushing the image, apply the manifests:

```powershell
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Wait for the `EXTERNAL-IP` on the service to be populated, then open it in a browser. For production, add ingress with authentication, TLS, and rate limiting.