from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, field_validator, model_validator


class DesignBase(BaseModel):
    design_name: str
    low_stock_threshold: int = 5


class DesignCreate(DesignBase):
    initial_taka_count: int = 0


class DesignUpdate(BaseModel):
    design_name: Optional[str] = None
    low_stock_threshold: Optional[int] = None
    current_taka_count: Optional[int] = None


class DesignRead(BaseModel):
    design_id: str
    design_name: str
    current_taka_count: int
    low_stock_threshold: int
    thumbnail_url: Optional[str] = None
    created_at: Optional[datetime] = None

    # Computed field: true when stock is at or below threshold
    @property
    def is_low_stock(self) -> bool:
        return self.current_taka_count <= self.low_stock_threshold

    model_config = {"from_attributes": True}

    def model_post_init(self, __context) -> None:
        # Expose is_low_stock as a real attribute so it serialises correctly
        object.__setattr__(self, "_is_low_stock", self.current_taka_count <= self.low_stock_threshold)

    def model_dump(self, **kwargs):
        data = super().model_dump(**kwargs)
        data["is_low_stock"] = self.current_taka_count <= self.low_stock_threshold
        return data


class DesignListResponse(BaseModel):
    items: List[DesignRead]
    total: int
