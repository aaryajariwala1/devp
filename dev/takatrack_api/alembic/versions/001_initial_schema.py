"""Initial schema

Revision ID: 001
Revises:
Create Date: 2026-06-04 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Enable pgvector extension ────────────────────────────────────────────
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    # ── transaction_type enum ────────────────────────────────────────────────
    transaction_type_enum = sa.Enum("INWARD", "OUTWARD", name="transaction_type")
    transaction_type_enum.create(op.get_bind(), checkfirst=True)

    # ── designs table ────────────────────────────────────────────────────────
    op.create_table(
        "designs",
        sa.Column("design_id", sa.String(), nullable=False),
        sa.Column("design_name", sa.String(200), nullable=False),
        sa.Column("current_taka_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("low_stock_threshold", sa.Integer(), nullable=False, server_default="5"),
        # 512-element float array; stored as PostgreSQL REAL[] — pgvector is optional here
        sa.Column(
            "image_vector_embedding",
            sa.ARRAY(sa.Float()),
            nullable=True,
        ),
        sa.Column("thumbnail_url", sa.String(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("design_id"),
        sa.UniqueConstraint("design_name"),
    )

    # Indexes on designs
    op.create_index(
        "idx_designs_low_stock",
        "designs",
        ["current_taka_count", "low_stock_threshold"],
    )
    op.create_index(
        "idx_designs_name",
        "designs",
        ["design_name"],
    )

    # ── transactions table ───────────────────────────────────────────────────
    op.create_table(
        "transactions",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("design_id", sa.String(), nullable=False),
        sa.Column("quantity_changed", sa.Integer(), nullable=False),
        sa.Column(
            "type",
            sa.Enum("INWARD", "OUTWARD", name="transaction_type"),
            nullable=False,
        ),
        sa.Column("note", sa.String(500), nullable=True),
        sa.Column(
            "timestamp",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["design_id"],
            ["designs.design_id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # Indexes on transactions
    op.create_index("idx_transactions_design_id", "transactions", ["design_id"])
    op.create_index("idx_transactions_timestamp", "transactions", ["timestamp"])
    op.create_index("idx_transactions_type", "transactions", ["type"])


def downgrade() -> None:
    # Drop tables in reverse order of creation
    op.drop_index("idx_transactions_type", table_name="transactions")
    op.drop_index("idx_transactions_timestamp", table_name="transactions")
    op.drop_index("idx_transactions_design_id", table_name="transactions")
    op.drop_table("transactions")

    op.drop_index("idx_designs_name", table_name="designs")
    op.drop_index("idx_designs_low_stock", table_name="designs")
    op.drop_table("designs")

    # Drop enum
    sa.Enum(name="transaction_type").drop(op.get_bind(), checkfirst=True)

    # Note: intentionally do not drop the vector extension as other schemas may use it
