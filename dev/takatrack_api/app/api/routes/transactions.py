import logging
from datetime import datetime
from typing import Annotated, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.websocket_manager import manager
from app.models.transaction import Transaction
from app.schemas.design import DesignRead
from app.schemas.transaction import AdjustInventoryRequest, TransactionRead
from app.services import inventory_service

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/inventory/adjust", status_code=status.HTTP_200_OK)
async def adjust_inventory(
    payload: AdjustInventoryRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """
    Atomically adjust a design's taka count.

    - Uses SELECT FOR UPDATE to prevent concurrent race conditions.
    - OUTWARD adjustments that would drive stock below 0 are rejected (HTTP 400).
    - Broadcasts the updated design to all connected WebSocket clients.
    """
    design, txn = await inventory_service.adjust_inventory(
        db,
        design_id=payload.design_id,
        delta=payload.delta,
        note=payload.note,
    )

    design_read = DesignRead.model_validate(design)
    txn_read = TransactionRead(
        id=txn.id,
        design_id=txn.design_id,
        quantity_changed=txn.quantity_changed,
        type=txn.type,
        note=txn.note,
        timestamp=txn.timestamp,
        design_name=design.design_name,
    )

    # Broadcast update to all WebSocket clients
    await manager.broadcast(
        {
            "event": "inventory_updated",
            "design": design_read.model_dump(mode="json"),
            "transaction": txn_read.model_dump(mode="json"),
        }
    )

    return {
        "design": design_read.model_dump(mode="json"),
        "transaction": txn_read.model_dump(mode="json"),
    }


@router.get("/transactions", response_model=List[TransactionRead])
async def list_transactions(
    db: Annotated[AsyncSession, Depends(get_db)],
    design_id: Optional[str] = Query(default=None, description="Filter by design ID"),
    type_filter: Optional[str] = Query(default=None, alias="type", description="INWARD or OUTWARD"),
    date_from: Optional[datetime] = Query(default=None, description="ISO8601 start timestamp"),
    date_to: Optional[datetime] = Query(default=None, description="ISO8601 end timestamp"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=100, ge=1, le=500),
) -> List[TransactionRead]:
    """
    List transactions with optional filters: design_id, type, date range.
    Results are ordered newest-first.
    """
    from app.models.design import Design

    query = (
        select(Transaction, Design.design_name)
        .join(Design, Transaction.design_id == Design.design_id)
    )

    if design_id:
        query = query.where(Transaction.design_id == design_id)
    if type_filter:
        if type_filter not in ("INWARD", "OUTWARD"):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="type must be 'INWARD' or 'OUTWARD'",
            )
        query = query.where(Transaction.type == type_filter)
    if date_from:
        query = query.where(Transaction.timestamp >= date_from)
    if date_to:
        query = query.where(Transaction.timestamp <= date_to)

    query = query.order_by(Transaction.timestamp.desc()).offset(skip).limit(limit)

    result = await db.execute(query)
    rows = result.all()

    return [
        TransactionRead(
            id=row.Transaction.id,
            design_id=row.Transaction.design_id,
            quantity_changed=row.Transaction.quantity_changed,
            type=row.Transaction.type,
            note=row.Transaction.note,
            timestamp=row.Transaction.timestamp,
            design_name=row.design_name,
        )
        for row in rows
    ]


@router.get("/transactions/{transaction_id}", response_model=TransactionRead)
async def get_transaction(
    transaction_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TransactionRead:
    """Retrieve a single transaction record by ID."""
    from app.models.design import Design

    result = await db.execute(
        select(Transaction, Design.design_name)
        .join(Design, Transaction.design_id == Design.design_id)
        .where(Transaction.id == transaction_id)
    )
    row = result.first()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Transaction '{transaction_id}' not found.",
        )
    return TransactionRead(
        id=row.Transaction.id,
        design_id=row.Transaction.design_id,
        quantity_changed=row.Transaction.quantity_changed,
        type=row.Transaction.type,
        note=row.Transaction.note,
        timestamp=row.Transaction.timestamp,
        design_name=row.design_name,
    )
