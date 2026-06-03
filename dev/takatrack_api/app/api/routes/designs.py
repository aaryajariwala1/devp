import logging
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.schemas.design import DesignCreate, DesignListResponse, DesignRead, DesignUpdate
from app.schemas.transaction import DashboardStats
from app.services import inventory_service

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/designs/stats/dashboard", response_model=DashboardStats)
async def get_dashboard_stats(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DashboardStats:
    """Aggregated dashboard statistics — total takas, today's movements, low-stock alerts."""
    return await inventory_service.get_dashboard_stats(db)


@router.get("/designs", response_model=DesignListResponse)
async def list_designs(
    db: Annotated[AsyncSession, Depends(get_db)],
    skip: int = Query(default=0, ge=0, description="Number of records to skip"),
    limit: int = Query(default=50, ge=1, le=200, description="Maximum records to return"),
    low_stock_only: bool = Query(default=False, description="Filter to designs at or below threshold"),
) -> DesignListResponse:
    """List all designs with optional pagination and low-stock filter."""
    designs, total = await inventory_service.list_designs(
        db, skip=skip, limit=limit, low_stock_only=low_stock_only
    )
    return DesignListResponse(
        items=[DesignRead.model_validate(d) for d in designs],
        total=total,
    )


@router.post("/designs", response_model=DesignRead, status_code=status.HTTP_201_CREATED)
async def create_design(
    data: DesignCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DesignRead:
    """Create a new design entry."""
    design = await inventory_service.create_design(db, data)
    return DesignRead.model_validate(design)


@router.get("/designs/{design_id}", response_model=DesignRead)
async def get_design(
    design_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DesignRead:
    """Retrieve a single design by ID."""
    design = await inventory_service.get_design_by_id(db, design_id)
    return DesignRead.model_validate(design)


@router.put("/designs/{design_id}", response_model=DesignRead)
async def update_design(
    design_id: str,
    data: DesignUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DesignRead:
    """Update mutable fields on an existing design."""
    design = await inventory_service.update_design(db, design_id, data)
    return DesignRead.model_validate(design)


@router.delete("/designs/{design_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_design(
    design_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """Delete a design and all associated transactions."""
    await inventory_service.delete_design(db, design_id)
