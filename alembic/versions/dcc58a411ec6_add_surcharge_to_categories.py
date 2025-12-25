"""add_surcharge_to_categories

Revision ID: dcc58a411ec6
Revises: 3901d0463151
Create Date: 2025-12-25 10:19:09.979356

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'dcc58a411ec6'
down_revision: Union[str, None] = '3901d0463151'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Добавляем колонку surcharge в таблицу categories
    op.add_column('categories', sa.Column('surcharge', sa.Numeric(10, 2), nullable=False, server_default='0.00'))


def downgrade() -> None:
    # Удаляем колонку surcharge из таблицы categories
    op.drop_column('categories', 'surcharge')

