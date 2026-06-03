import logging
from typing import List, Optional, Tuple

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.vision.extractor import cosine_similarity, get_extractor
from app.models.design import Design

logger = logging.getLogger(__name__)


async def find_similar_design(
    db: AsyncSession,
    query_embedding: List[float],
    threshold: float = 0.75,
) -> Tuple[Optional[Design], float]:
    """
    Query all designs that have stored embeddings and find the best cosine match.

    Returns:
        (best_design, best_confidence) — best_design is None if no match exceeds threshold.
    """
    result = await db.execute(
        select(Design).where(Design.image_vector_embedding.isnot(None))
    )
    designs = result.scalars().all()

    if not designs:
        logger.info("No designs with embeddings found in the database.")
        return None, 0.0

    best_design: Optional[Design] = None
    best_confidence: float = 0.0

    for design in designs:
        stored_embedding: List[float] = design.image_vector_embedding
        if not stored_embedding:
            continue
        score = cosine_similarity(query_embedding, stored_embedding)
        if score > best_confidence:
            best_confidence = score
            best_design = design

    logger.info(
        f"Vision scan: best_confidence={best_confidence:.4f}, "
        f"threshold={threshold}, "
        f"matched={'yes' if best_confidence >= threshold else 'no'}"
    )

    if best_confidence >= threshold:
        return best_design, best_confidence
    return None, best_confidence


async def register_design_embedding(
    db: AsyncSession,
    design_id: str,
    image_bytes: bytes,
) -> Design:
    """
    Extract a 512-dim embedding from image_bytes and persist it on the Design row.
    Raises HTTP 404 if the design does not exist.
    """
    result = await db.execute(select(Design).where(Design.design_id == design_id))
    design = result.scalar_one_or_none()
    if design is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Design '{design_id}' not found.",
        )

    extractor = get_extractor()
    embedding = extractor.extract(image_bytes)
    design.image_vector_embedding = embedding

    await db.commit()
    await db.refresh(design)
    logger.info(f"Registered embedding for design {design_id} (dim={len(embedding)})")
    return design
