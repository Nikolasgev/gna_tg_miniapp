"""add item_metadata to order_items

Revision ID: add_item_metadata
Revises: add_promocodes_loyalty
Create Date: 2025-01-27 12:00:00.000000

"""
from typing import Sequence, Union
from datetime import datetime

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'add_item_metadata'
down_revision: Union[str, None] = 'add_loyalty_points_percent'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add item_metadata column to order_items table
    conn = op.get_bind()
    
    # Check if column already exists
    existing_cols = [row[0] for row in conn.execute(sa.text("""
        SELECT column_name FROM information_schema.columns 
        WHERE table_name = 'order_items'
    """)).fetchall()]
    
    if 'item_metadata' not in existing_cols:
        op.add_column('order_items', sa.Column('item_metadata', sa.JSON(), nullable=True))


def downgrade() -> None:
    # Remove item_metadata column from order_items table
    op.drop_column('order_items', 'item_metadata')

