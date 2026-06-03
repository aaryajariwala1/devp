import enum
from uuid import uuid4

from sqlalchemy import (
    Column,
    String,
    Integer,
    DateTime,
    Enum,
    ForeignKey,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class TransactionType(str, enum.Enum):
    INWARD = "INWARD"
    OUTWARD = "OUTWARD"


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    design_id = Column(
        String,
        ForeignKey("designs.design_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    quantity_changed = Column(Integer, nullable=False)  # positive=inward, negative=outward
    type = Column(
        Enum("INWARD", "OUTWARD", name="transaction_type"),
        nullable=False,
    )
    note = Column(String(500), nullable=True)
    timestamp = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    # Relationships
    design = relationship("Design", back_populates="transactions")
