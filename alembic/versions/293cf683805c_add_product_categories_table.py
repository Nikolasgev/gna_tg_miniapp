"""add_product_categories_table

Revision ID: 293cf683805c
Revises: bc2d43cc3e9c
Create Date: 2025-12-25 10:32:31.580093

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '293cf683805c'
down_revision: Union[str, None] = 'bc2d43cc3e9c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Создаем таблицу product_categories для M2M связи между products и categories
    op.create_table(
        'product_categories',
        sa.Column('product_id', sa.Uuid(), nullable=False),
        sa.Column('category_id', sa.Uuid(), nullable=False),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['category_id'], ['categories.id'], ),
        sa.PrimaryKeyConstraint('product_id', 'category_id')
    )


def downgrade() -> None:
    # Удаляем таблицу product_categories
    op.drop_table('product_categories')

