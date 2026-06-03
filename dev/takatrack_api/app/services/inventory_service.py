import logging
from datetime import datetime, timezone
from typing import List, Optional, Tuple

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.design import Design
from app.models.transaction import Transaction
from app.schemas.design import DesignCreate, DesignRead, DesignUpdate
from app.schemas.transaction import DashboardStats

logger = logging.getLogger(__name__)


async def get_design_by_id(db: AsyncSession, design_id: str) -> Design:
    """Return a Design ORM object or raise HTTP 404."""
    result = await db.execute(select(Design).where(Design.design_id == design_id))
    design = result.scalar_one_or_none()
    if design is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Design '{design_id}' not found.",
        )
    return design


async def list_designs(
    db: AsyncSession,
    skip: int = 0,
    limit: int = 50,
    low_stock_only: bool = False,
) -> Tuple[List[Design], int]:
    """Return a page of designs and the total count."""
    query = select(Design)
    if low_stock_only:
        query = query.where(Design.current_taka_count <= Design.low_stock_threshold)

    # Count
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar_one()

    # Page
    query = query.offset(skip).limit(limit).order_by(Design.created_at.desc())
    result = await db.execute(query)
    designs = result.scalars().all()

    return list(designs), total


async def create_design(db: AsyncSession, data: DesignCreate) -> Design:
    """Create a new design, enforcing unique name."""
    # Check uniqueness
    existing = await db.execute(
        select(Design).where(Design.design_name == data.design_name)
    )
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Design with name '{data.design_name}' already exists.",
        )

    design = Design(
        design_name=data.design_name,
        current_taka_count=data.initial_taka_count,
        low_stock_threshold=data.low_stock_threshold,
    )
    db.add(design)
    await db.commit()
    await db.refresh(design)
    logger.info(f"Created design: {design.design_id} — {design.design_name}")
    return design


async def update_design(
    db: AsyncSession, design_id: str, data: DesignUpdate
) -> Design:
    """Partially update a design's mutable fields."""
    design = await get_design_by_id(db, design_id)

    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(design, field, value)

    await db.commit()
    await db.refresh(design)
    return design


async def delete_design(db: AsyncSession, design_id: str) -> None:
    """Delete a design (cascades to transactions)."""
    design = await get_design_by_id(db, design_id)
    await db.delete(design)
    await db.commit()
    logger.info(f"Deleted design: {design_id}")


async def adjust_inventory(
    db: AsyncSession,
    design_id: str,
    delta: int,
    note: Optional[str] = None,
) -> Tuple[Design, Transaction]:
    """
    Atomically adjust a design's taka count and record the transaction.

    Uses SELECT … FOR UPDATE to serialise concurrent updates on the same row.
    Raises HTTP 400 if an OUTWARD adjustment would drive stock negative.
    """
    # SELECT FOR UPDATE — prevents race conditions
    result = await db.execute(
        select(Design).where(Design.design_id == design_id).with_for_update()
    )
    design = result.scalar_one_or_none()
    if design is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Design '{design_id}' not found.",
        )

    # Validate outward stock
    if delta < 0 and abs(delta) > design.current_taka_count:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Insufficient stock. Current count: {design.current_taka_count}, "
                f"requested outward: {abs(delta)}."
            ),
        )

    transaction_type = "INWARD" if delta > 0 else "OUTWARD"
    design.current_taka_count += delta

    txn = Transaction(
        design_id=design_id,
        quantity_changed=delta,
        type=transaction_type,
        note=note,
    )
    db.add(txn)
    await db.commit()
    await db.refresh(design)
    await db.refresh(txn)
    logger.info(
        f"Adjusted inventory for {design_id}: delta={delta}, new_count={design.current_taka_count}"
    )
    return design, txn


async def get_dashboard_stats(db: AsyncSession) -> DashboardStats:
    """Compute aggregated stats for the dashboard."""
    # Total takas across all designs
    total_takas_result = await db.execute(select(func.sum(Design.current_taka_count)))
    total_takas: int = total_takas_result.scalar_one() or 0

    # Today's date boundaries (UTC)
    now_utc = datetime.now(timezone.utc)
    today_start = now_utc.replace(hour=0, minute=0, second=0, microsecond=0)

    # Inward today
    inward_result = await db.execute(
        select(func.coalesce(func.sum(Transaction.quantity_changed), 0)).where(
            Transaction.type == "INWARD",
            Transaction.timestamp >= today_start,
        )
    )
    inward_today: int = inward_result.scalar_one() or 0

    # Outward today (sum of negative deltas, returned as positive number)
    outward_result = await db.execute(
        select(func.coalesce(func.sum(Transaction.quantity_changed), 0)).where(
            Transaction.type == "OUTWARD",
            Transaction.timestamp >= today_start,
        )
    )
    outward_raw: int = outward_result.scalar_one() or 0
    outward_today: int = abs(outward_raw)

    # Low stock designs
    low_stock_result = await db.execute(
        select(Design).where(Design.current_taka_count <= Design.low_stock_threshold)
    )
    low_stock_designs = low_stock_result.scalars().all()

    return DashboardStats(
        total_takas=total_takas,
        inward_today=inward_today,
        outward_today=outward_today,
        low_stock_count=len(low_stock_designs),
        low_stock_designs=[d.design_name for d in low_stock_designs],
    )
