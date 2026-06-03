import logging
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.config import settings
from app.core.vision.extractor import get_extractor
from app.schemas.design import DesignRead
from app.schemas.transaction import ScanResult
from app.services.scan_service import find_similar_design, register_design_embedding

logger = logging.getLogger(__name__)

router = APIRouter()

MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


@router.post("/scan-design", response_model=ScanResult)
async def scan_design(
    db: Annotated[AsyncSession, Depends(get_db)],
    file: UploadFile = File(..., description="Fabric image (JPEG/PNG, max 5 MB)"),
) -> ScanResult:
    """
    Scan a fabric image and find the closest matching design.

    1. Validate image file size (≤ 5 MB).
    2. Extract a 512-dim ResNet18 embedding from the uploaded image.
    3. Compare cosine similarity against every stored design embedding.
    4. If best confidence ≥ CONFIDENCE_THRESHOLD → return matched design details.
    5. Otherwise → return is_new_design=True with 'New Design Detected' message.
    """
    # Read bytes and enforce size limit
    image_bytes = await file.read()
    if len(image_bytes) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File too large. Maximum allowed size is 5 MB, got {len(image_bytes) / 1024 / 1024:.2f} MB.",
        )

    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty.",
        )

    # Extract embedding
    try:
        extractor = get_extractor()
        query_embedding = extractor.extract(image_bytes)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc

    # Find the best matching design
    matched_design, confidence = await find_similar_design(
        db, query_embedding, threshold=settings.CONFIDENCE_THRESHOLD
    )

    if matched_design is not None:
        return ScanResult(
            matched=True,
            design_id=matched_design.design_id,
            design_name=matched_design.design_name,
            confidence=round(confidence, 4),
            taka_count=matched_design.current_taka_count,
            is_new_design=False,
            message=f"Matched design '{matched_design.design_name}' with {confidence * 100:.1f}% confidence.",
        )

    return ScanResult(
        matched=False,
        design_id=None,
        design_name=None,
        confidence=round(confidence, 4),
        taka_count=None,
        is_new_design=True,
        message="New Design Detected",
    )


@router.post(
    "/designs/{design_id}/register-embedding",
    response_model=DesignRead,
    status_code=status.HTTP_200_OK,
)
async def register_embedding(
    design_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    file: UploadFile = File(..., description="Reference image for embedding registration (JPEG/PNG, max 5 MB)"),
) -> DesignRead:
    """
    Register (or update) the visual embedding for an existing design.

    Extracts a 512-dim ResNet18 feature vector from the uploaded image and
    persists it on the Design record. Future scan requests will compare against
    this stored embedding.
    """
    image_bytes = await file.read()
    if len(image_bytes) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File too large. Maximum allowed size is 5 MB.",
        )

    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty.",
        )

    design = await register_design_embedding(db, design_id, image_bytes)
    return DesignRead.model_validate(design)
