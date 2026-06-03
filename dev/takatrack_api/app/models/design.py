from uuid import uuid4

from sqlalchemy import (
    Column,
    String,
    Integer,
    DateTime,
    Float,
)
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Design(Base):
    __tablename__ = "designs"

    design_id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    design_name = Column(String(200), nullable=False, unique=True, index=True)
    current_taka_count = Column(Integer, nullable=False, default=0)
    low_stock_threshold = Column(Integer, nullable=False, default=5)
    # 512-dimensional feature vector extracted by ResNet18
    image_vector_embedding = Column(ARRAY(Float), nullable=True)
    thumbnail_url = Column(String, nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        onupdate=func.now(),
        nullable=True,
    )

    # Relationships
    transactions = relationship(
        "Transaction",
        back_populates="design",
        cascade="all, delete-orphan",
    )
