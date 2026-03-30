"""add stock_quantity to products

Revision ID: add_stock_quantity
Revises: add_item_metadata
Create Date: 2025-01-29 10:00:00.000000

"""
from typing import Sequence, Union
from datetime import datetime

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'add_stock_quantity'
down_revision: Union[str, None] = 'add_item_metadata'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add stock_quantity column to products table
    conn = op.get_bind()
    
    # Check if column already exists
    existing_cols = [row[0] for row in conn.execute(sa.text("""
        SELECT column_name FROM information_schema.columns 
        WHERE table_name = 'products'
    """)).fetchall()]
    
    if 'stock_quantity' not in existing_cols:
        op.add_column('products', sa.Column('stock_quantity', sa.Integer(), nullable=True))


def downgrade() -> None:
    # Remove stock_quantity column from products table
    op.drop_column('products', 'stock_quantity')


