import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.core.vision.extractor import init_extractor
from app.database import init_db

logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s — %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: startup → yield → shutdown."""
    # ── Startup ──────────────────────────────────────────────────────────────
    logger.info("Starting TakaTrack API …")

    # Initialise database (pgvector extension + tables)
    await init_db()

    # Load ResNet18 feature extractor into memory
    logger.info("Loading fabric feature extractor (ResNet18) …")
    init_extractor(settings.MODEL_CACHE_DIR)
    logger.info("Feature extractor ready.")

    logger.info("TakaTrack API is ready to serve requests.")
    yield

    # ── Shutdown ─────────────────────────────────────────────────────────────
    logger.info("TakaTrack API shutting down.")


app = FastAPI(
    title="TakaTrack API",
    description=(
        "Real-time textile inventory tracking with AI-powered fabric pattern recognition.\n\n"
        "## Features\n"
        "- Full CRUD for jacquard fabric designs\n"
        "- Atomic inventory adjustments (SELECT FOR UPDATE)\n"
        "- ResNet18-based visual similarity scanning\n"
        "- Real-time WebSocket broadcasts on inventory changes\n"
        "- pgvector-ready PostgreSQL backend"
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── Middleware ────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
from app.api.routes import designs, scan, transactions, ws  # noqa: E402

app.include_router(designs.router, prefix="/api", tags=["Designs"])
app.include_router(transactions.router, prefix="/api", tags=["Transactions"])
app.include_router(scan.router, prefix="/api", tags=["Scan"])
app.include_router(ws.router, tags=["WebSocket"])


# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/health", tags=["Health"])
async def health_check() -> dict:
    """Liveness probe — returns 200 when the service is up."""
    return {"status": "healthy", "service": "TakaTrack API", "version": "1.0.0"}
