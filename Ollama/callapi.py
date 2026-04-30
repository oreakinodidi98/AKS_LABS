import os
import requests

# Use [::1] to reach AKS Ollama via port-forward (IPv6 loopback)
# Your local Ollama occupies 127.0.0.1:11434 (IPv4), so we target IPv6 explicitly
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://[::1]:11434")

# Generate a response
response = requests.post(f"{OLLAMA_URL}/api/generate", json={
    "model": "tinyllama",
    "prompt": "Explain the concept of GitOps in one paragraph",
    "stream": False,
})

data = response.json()
if "response" in data:
    print(data["response"])
else:
    print("Error:", data.get("error", data))

# Chat completion
response = requests.post(f"{OLLAMA_URL}/api/chat", json={
    "model": "tinyllama",
    "messages": [
        {"role": "user", "content": "Write a Python function to parse JSON safely"}
    ],
    "stream": False,
})

data = response.json()
if "message" in data:
    print(data["message"]["content"])
else:
    print("Error:", data.get("error", data))

# can also use OpenAI compatible endpoints
# from openai import OpenAI

# client = OpenAI(
#     base_url="http://ollama.default.svc:11434/v1",
#     api_key="not-needed",
# )

# response = client.chat.completions.create(
#     model="llama3.1:8b",
#     messages=[{"role": "user", "content": "Hello!"}],
# )