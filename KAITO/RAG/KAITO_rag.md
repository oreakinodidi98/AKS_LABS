# RAG Applications with KAITO RAGEngine

**RAG** — Retrieval Augmented Generation

RAG combines LLMs with external knowledge sources so the model can retrieve real data before generating a response. Instead of relying purely on what the model was trained on, RAG pulls relevant information from a knowledge base or database and feeds it into the LLM — giving you more accurate, contextually relevant answers.

---

## Demo

Build a RAG application on AKS using KAITO's RAGEngine, backed by a sample e-commerce store.

### Prerequisites

- AKS cluster with GPU node pool
- KAITO installed via Helm

### Deploy the Workspace

Deploy the KAITO workspace and check the status:

```bash
kubectl get workspace workspace-phi-4-mini-instruct
```

### Deploy the Sample Application

Deploy the AKS Store Demo — a simple online store that sells pet supplies. We'll use this application and its product data to build a RAG application that can answer questions about the products available in the store.

```bash
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/refs/heads/main/aks-store-quickstart.yaml
```

Get the external IP for the store front:

```bash
kubectl get service store-front -ojsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Deploy RAGRngine file. This will take a few minutes to complete. Wait until the RAGEngine instance is in the Ready state and the Pods are running before proceeding.

```bash
kubectl apply -f C:\Demo_AKS_Mod\KAITO\RAG\ragengine.yaml
```

---

## What is the KAITO RAGEngine?

A custom resource that simplifies the deployment and management of RAG workloads on Kubernetes. It lets you deploy RAG applications that retrieve information from external knowledge sources and use it to enhance responses from LLMs.

### How a RAG Workflow Works

In a RAG workflow, you have a knowledge base (like a database or an index) and an LLM. Data is indexed in a vector database, which allows for efficient retrieval of relevant information based on the user's query.

### Key Components

| Component | What It Does |
|---|---|
| **Knowledge Base** | A source of information that can be indexed and queried to retrieve relevant data |
| **Vector Database** | Stores indexed data in a format that allows for efficient similarity search |
| **Embedding Model** | Converts text into vector representations, which are then stored in the vector database |
| **Inference Service** | Provides access to an LLM for generating responses based on the retrieved information |

### How KAITO RAGEngine Simplifies This

KAITO RAGEngine wraps all of these components into a single CRD — the vector database, embedding model, and inference service are all configured in one place. By default, it uses the **Faiss** vector database and the **BAAI general embedding (bge)** model, but you can configure it to use other embedding models as needed.

When building your RAG application, instead of calling the inference service directly, you interact with the `/query` endpoint of the RAGEngine instance. This endpoint handles retrieving relevant information from the knowledge base, passes it to the inference service, and returns the generated response.

---

## Data Prep

To use the RAGEngine, your data must be indexed in a specific format. Here's the JSON schema the RAGEngine expects:

```json
{
  "index_name": "<your-index-name>",
  "documents": [
    {
      "text": "<document content>",
      "metadata": {
        "author": "<author name>",
        "category": "<category>",
        "url": "http://<store-ip>/product/<product-id>"
      }
    }
  ]
}
```

| Field | What It Does |
|---|---|
| `index_name` | The name of the index where documents will be stored |
| `documents[].text` | The content to be embedded and searched against — in our case, the product description |
| `documents[].metadata` | Additional context passed to the LLM prompt — things like category, author, URL |

The `metadata` field is flexible — you can include whatever additional information you want the LLM to have access to when generating responses.

---

## Fetch Data

Get the external IP address of the store front service:

```bash
STORE_IP=$(kubectl get service store-front -ojsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Fetch the product data:

```bash
curl http://${STORE_IP}/api/products | jq
```

You should see a JSON response containing the product data with fields like `id`, `name`, `description`, and `price`.

---

## Transform Data

Transform the product data into a format suitable for indexing with the RAGEngine. We extract the relevant fields and format them according to the schema using `jq`:

```bash
curl http://${STORE_IP}/api/products | jq --arg store_ip "$STORE_IP" '{
  index_name: "store_index",
  documents: [
    .[] | {
      text: "\(.name) - \(.description) Price: $\(.price)",
      metadata: {
        author: "Contoso Pet Supply",
        category: (
          if (.name | test("cat|Cat|feline|kitty"; "i")) then "Cat Toys"
          elif (.name | test("dog|Dog|Doggy"; "i")) then "Dog Toys"
          elif (.name | test("Bed|bed"; "i")) then "Pet Beds"
          elif (.name | test("Life Jacket|Jacket"; "i")) then "Pet Accessories"
          else "Pet Toys"
          end
        ),
        url: "http://\($store_ip)/product/\(.id)"
      }
    }
  ]
}' > store_products.json
```

Verify the transformed data:

```bash
cat store_products.json | jq
```

---

## Index Data

Now that the data is in the correct format, index it by sending a POST request to the `/index` endpoint of the RAGEngine instance.

Port-forward the RAGEngine service to your local machine:

```bash
kubectl port-forward svc/<ragengine-service-name> 8080:80 &
```

> **Note:** This runs the port-forward in the background. Press `ctrl+c` to stop it.

Index the product data:

```bash
curl -X POST http://localhost:8080/index \
  -H "Content-Type: application/json" \
  -d @store_products.json | jq
```

You should see a JSON response listing the products that were indexed as documents in the vector database.

### Verify Indexing

List all available indexes:

```bash
curl http://localhost:8080/indexes
```

List the documents in a specific index:

```bash
curl http://localhost:8080/indexes/<your-index-name>/documents | jq
```

---

## Querying with RAGEngine

Query the indexed data and generate responses using your deployed model.

```bash
curl -s http://localhost:8080/query \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "index_name": "<your-index-name>",
    "query": "<your question>",
    "top_k": 5,
    "llm_params": {
      "temperature": 0.7,
      "max_tokens": 2048
    }
  }' | jq
```

| Parameter | What It Controls |
|---|---|
| `index_name` | Which index to search against |
| `query` | The user's natural language question |
| `top_k` | Number of relevant documents to retrieve from the vector database |
| `llm_params.temperature` | Controls randomness of the LLM response (0 = deterministic, 1 = creative) |
| `llm_params.max_tokens` | Maximum length of the generated response |

The response is tailored to the user's query using the indexed data — the RAGEngine retrieves relevant documents, passes them as context to the inference service, and returns a grounded answer. Responses can include metadata like product URLs so users can click through to the source.

---

## Why This Matters

With KAITO, the complexity of managing vector databases, embedding models, and inference services is abstracted away — you focus on building applications, not infrastructure. By default, your models, logs, and data stores are secured with in-cluster RAG, preventing exposure of real-time sensitive data to external LLM services.

This foundation opens doors to:

- **Enterprise knowledge management** — internal docs, policies, runbooks
- **Multi-modal applications** — images, documents, structured data
- **Real-time data integration** — live product catalogs, inventory, pricing
- **Personalized user experiences** — recommendations tailored to user context
- **Automated content generation** — summaries, reports, responses

What starts as a simple product recommendation system can scale into a comprehensive AI platform that transforms how users interact with organizational knowledge.