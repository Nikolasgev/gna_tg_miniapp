"""add_username_password_to_users

Revision ID: 9456f4baf093
Revises: 293cf683805c
Create Date: 2025-12-25 10:50:07.968709

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9456f4baf093'
down_revision: Union[str, None] = '293cf683805c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Добавляем поля username и password_hash в таблицу users
    op.add_column('users', sa.Column('username', sa.String(), nullable=True, unique=True))
    op.add_column('users', sa.Column('password_hash', sa.String(), nullable=True))


def downgrade() -> None:
    # Удаляем поля username и password_hash из таблицы users
    op.drop_column('users', 'password_hash')
    op.drop_column('users', 'username')

