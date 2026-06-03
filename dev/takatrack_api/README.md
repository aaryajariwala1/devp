# TakaTrack API

**Real-time textile inventory tracking with AI-powered fabric pattern recognition.**

Built with FastAPI, PostgreSQL + pgvector, and a ResNet18 PyTorch vision pipeline to identify jacquard fabric designs from camera images.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start (Docker)](#quick-start-docker)
4. [Manual Setup](#manual-setup)
5. [API Endpoints](#api-endpoints)
6. [WebSocket Usage](#websocket-usage)
7. [Vision Pipeline](#vision-pipeline)
8. [Registering a Design Embedding](#registering-a-design-embedding)

---

## Project Overview

TakaTrack tracks how many **takas** (rolls/units) of each jacquard fabric design are in stock.

Key features:

| Feature | Details |
|---|---|
| Design CRUD | Create, read, update, delete fabric designs |
| Inventory Adjustment | Atomic INWARD / OUTWARD taka adjustments (SELECT FOR UPDATE) |
| Low-Stock Alerts | Configurable per-design threshold |
| AI Scan | Upload a fabric photo → get matched design + confidence |
| Real-Time Updates | WebSocket push after every inventory change |
| Dashboard Stats | Aggregated totals, today's movements, low-stock list |

---

## Prerequisites

| Tool | Version |
|---|---|
| Docker + Docker Compose | Latest stable |
| Python | 3.12+ (for manual setup) |
| PostgreSQL with pgvector | 16 (via Docker image) |

---

## Quick Start (Docker)

```bash
# 1. Clone / enter the project directory
cd takatrack_api

# 2. Copy the example env file
copy .env.example .env    # Windows
# cp .env.example .env    # Linux/macOS

# 3. Build and start all services
docker compose up --build
```

The API will be available at **http://localhost:8000**  
Interactive docs at **http://localhost:8000/docs**

> **Note:** The first `docker compose up --build` downloads the ResNet18 weights (~45 MB). Subsequent starts use the cached `model_cache` volume.

---

## Manual Setup

```bash
# 1. Create and activate a virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Linux/macOS

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Configure environment
copy .env.example .env
# Edit .env to point DATABASE_URL and SYNC_DATABASE_URL at your PostgreSQL instance

# 4. Start PostgreSQL with pgvector (Docker)
docker run -d \
  --name takatrack_db \
  -e POSTGRES_USER=takatrack \
  -e POSTGRES_PASSWORD=takatrack_secret \
  -e POSTGRES_DB=takatrack_db \
  -p 5432:5432 \
  pgvector/pgvector:pg16

# 5. Run database migrations
alembic upgrade head

# 6. Start the API server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## API Endpoints

### Designs

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/designs` | List all designs (supports `skip`, `limit`, `low_stock_only`) |
| `POST` | `/api/designs` | Create a new design |
| `GET` | `/api/designs/{design_id}` | Get a single design |
| `PUT` | `/api/designs/{design_id}` | Update design fields |
| `DELETE` | `/api/designs/{design_id}` | Delete design (cascades to transactions) |
| `GET` | `/api/designs/stats/dashboard` | Aggregated dashboard statistics |

### Inventory

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/inventory/adjust` | Atomically adjust taka count (INWARD or OUTWARD) |

### Transactions

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/transactions` | List transactions (filter by `design_id`, `type`, date range) |
| `GET` | `/api/transactions/{transaction_id}` | Get single transaction |

### Vision / Scan

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/scan-design` | Upload fabric image → get matched design (multipart/form-data) |
| `POST` | `/api/designs/{design_id}/register-embedding` | Register/update embedding for a design |

### Utility

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Liveness probe |
| `WS` | `/ws/inventory` | Real-time inventory update stream |

---

## WebSocket Usage

Connect to `ws://localhost:8000/ws/inventory` with any WebSocket client.

**Keepalive ping:**
```
Client → "ping"
Server → "pong"
```

**Inventory update event** (pushed after every `/api/inventory/adjust` call):
```json
{
  "event": "inventory_updated",
  "design": {
    "design_id": "uuid-...",
    "design_name": "Floral Jacquard A",
    "current_taka_count": 42,
    "low_stock_threshold": 5,
    "is_low_stock": false,
    ...
  },
  "transaction": {
    "id": "txn-uuid-...",
    "design_id": "uuid-...",
    "quantity_changed": 10,
    "type": "INWARD",
    "note": "Morning delivery",
    "timestamp": "2026-06-04T08:00:00+00:00"
  }
}
```

**Example (JavaScript):**
```javascript
const ws = new WebSocket('ws://localhost:8000/ws/inventory');
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Inventory updated:', data.design.design_name, data.design.current_taka_count);
};
ws.onopen = () => ws.send('ping');
```

---

## Vision Pipeline

```
Camera / Upload
      │
      ▼
  PIL Image (RGB)
      │
      ▼
  Resize to 224×224
  ImageNet Normalize
      │
      ▼
  ResNet18 (pretrained, frozen)
  — classification head removed —
  avgpool output: [512]
      │
      ▼
  L2 Normalise → 512-dim vector
      │
      ▼
  Cosine similarity vs all stored embeddings
      │
      ├─ ≥ 0.75 → MATCH  (return design + confidence)
      └─ < 0.75 → NEW DESIGN DETECTED
```

The model is loaded once at startup via the `lifespan` hook and reused for all requests (thread-safe inference with `torch.no_grad()`).

---

## Registering a Design Embedding

Before a design can be matched by the scan endpoint, you must register at least one reference image:

```bash
curl -X POST "http://localhost:8000/api/designs/{design_id}/register-embedding" \
  -H "accept: application/json" \
  -F "file=@/path/to/fabric_photo.jpg"
```

The endpoint:
1. Extracts a 512-dim embedding from the uploaded image.
2. Stores the embedding on the `Design` database row.
3. Returns the updated `DesignRead` object.

After registration, the design will participate in future `/api/scan-design` searches.

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DATABASE_URL` | `postgresql+asyncpg://...` | Async DB URL (asyncpg driver) |
| `SYNC_DATABASE_URL` | `postgresql+psycopg2://...` | Sync DB URL (for Alembic) |
| `SECRET_KEY` | `change-me-...` | Application secret key |
| `CONFIDENCE_THRESHOLD` | `0.75` | Minimum cosine similarity to count as a match |
| `LOW_STOCK_THRESHOLD` | `5` | Default low-stock threshold for new designs |
| `MODEL_CACHE_DIR` | `./model_cache` | Directory for PyTorch model weights |
| `DEBUG` | `true` | Enable SQLAlchemy query logging |

---

## Project Structure

```
takatrack_api/
├── app/
│   ├── main.py                  # FastAPI app + lifespan
│   ├── config.py                # Pydantic-settings
│   ├── database.py              # Async engine, session, init_db
│   ├── models/
│   │   ├── design.py            # Design ORM model
│   │   └── transaction.py       # Transaction ORM model
│   ├── schemas/
│   │   ├── design.py            # Design Pydantic schemas
│   │   └── transaction.py       # Transaction + Dashboard schemas
│   ├── api/
│   │   ├── deps.py              # get_db dependency
│   │   └── routes/
│   │       ├── designs.py       # Design CRUD routes
│   │       ├── transactions.py  # Transaction + adjust routes
│   │       ├── scan.py          # Vision scan routes
│   │       └── ws.py            # WebSocket route
│   ├── core/
│   │   ├── websocket_manager.py # ConnectionManager singleton
│   │   └── vision/
│   │       └── extractor.py     # ResNet18 feature extractor
│   └── services/
│       ├── inventory_service.py # Business logic layer
│       └── scan_service.py      # Vision search + registration
├── alembic/
│   ├── env.py                   # Alembic migration env
│   └── versions/
│       └── 001_initial_schema.py
├── alembic.ini
├── Dockerfile
├── docker-compose.yml
├── preload_model.py
├── requirements.txt
└── .env.example
```
