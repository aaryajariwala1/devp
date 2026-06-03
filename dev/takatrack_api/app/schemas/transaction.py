from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, field_validator


class TransactionCreate(BaseModel):
    design_id: str
    quantity_changed: int
    type: str  # 'INWARD' or 'OUTWARD'
    note: Optional[str] = None

    @field_validator("quantity_changed")
    @classmethod
    def quantity_must_be_nonzero(cls, v: int) -> int:
        if v == 0:
            raise ValueError("quantity_changed cannot be zero")
        return v

    @field_validator("type")
    @classmethod
    def type_must_be_valid(cls, v: str) -> str:
        if v not in ("INWARD", "OUTWARD"):
            raise ValueError("type must be 'INWARD' or 'OUTWARD'")
        return v


class TransactionRead(BaseModel):
    id: str
    design_id: str
    quantity_changed: int
    type: str
    note: Optional[str] = None
    timestamp: Optional[datetime] = None
    design_name: Optional[str] = None

    model_config = {"from_attributes": True}


class AdjustInventoryRequest(BaseModel):
    design_id: str
    delta: int
    note: Optional[str] = None

    @field_validator("delta")
    @classmethod
    def delta_must_be_nonzero(cls, v: int) -> int:
        if v == 0:
            raise ValueError("delta cannot be zero")
        return v


class DashboardStats(BaseModel):
    total_takas: int
    inward_today: int
    outward_today: int
    low_stock_count: int
    low_stock_designs: List[str]


class ScanResult(BaseModel):
    matched: bool
    design_id: Optional[str] = None
    design_name: Optional[str] = None
    confidence: float
    taka_count: Optional[int] = None
    is_new_design: bool
    message: str
