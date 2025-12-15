"""add loyalty points percent to businesses

Revision ID: add_loyalty_points_percent
Revises: add_promocodes_loyalty
Create Date: 2025-01-28 12:00:00.000000

"""
from typing import Sequence, Union
from datetime import datetime

from alembic import op
import sqlalchemy as sa
from decimal import Decimal


# revision identifiers, used by Alembic.
revision: str = 'add_loyalty_points_percent'
down_revision: Union[str, None] = 'add_promocodes_loyalty'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Добавляем поле для процента начисления баллов (по умолчанию 1.0 = 1%)
    op.add_column('businesses', sa.Column('loyalty_points_percent', sa.Numeric(precision=5, scale=2), nullable=True, server_default='1.00'))
    
    # Устанавливаем значение по умолчанию для существующих бизнесов
    op.execute("UPDATE businesses SET loyalty_points_percent = 1.00 WHERE loyalty_points_percent IS NULL")


def downgrade() -> None:
    op.drop_column('businesses', 'loyalty_points_percent')






