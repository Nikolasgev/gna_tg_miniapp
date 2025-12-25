"""add_variations_to_products

Revision ID: bc2d43cc3e9c
Revises: dcc58a411ec6
Create Date: 2025-12-25 10:20:41.190103

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'bc2d43cc3e9c'
down_revision: Union[str, None] = 'dcc58a411ec6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Добавляем колонку variations в таблицу products
    op.add_column('products', sa.Column('variations', sa.JSON(), nullable=True))


def downgrade() -> None:
    # Удаляем колонку variations из таблицы products
    op.drop_column('products', 'variations')

