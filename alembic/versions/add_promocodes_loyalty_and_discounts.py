"""add promocodes loyalty and discounts

Revision ID: add_promocodes_loyalty
Revises: e6871241d61c
Create Date: 2025-01-27 10:00:00.000000

"""
from typing import Sequence, Union
from datetime import datetime

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'add_promocodes_loyalty'
down_revision: Union[str, None] = 'e6871241d61c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add discount fields to products table (variations уже существует, не добавляем)
    # Используем условное добавление колонок
    conn = op.get_bind()
    
    # Проверяем и добавляем колонки для products
    existing_cols = [row[0] for row in conn.execute(sa.text("""
        SELECT column_name FROM information_schema.columns 
        WHERE table_name = 'products'
    """)).fetchall()]
    
    if 'discount_percentage' not in existing_cols:
        op.add_column('products', sa.Column('discount_percentage', sa.Numeric(precision=5, scale=2), nullable=True))
    if 'discount_price' not in existing_cols:
        op.add_column('products', sa.Column('discount_price', sa.Numeric(precision=10, scale=2), nullable=True))
    if 'discount_valid_from' not in existing_cols:
        op.add_column('products', sa.Column('discount_valid_from', sa.DateTime(), nullable=True))
    if 'discount_valid_until' not in existing_cols:
        op.add_column('products', sa.Column('discount_valid_until', sa.DateTime(), nullable=True))

    # Add promocode and loyalty fields to orders table
    op.add_column('orders', sa.Column('subtotal_amount', sa.Numeric(precision=10, scale=2), nullable=True))
    op.add_column('orders', sa.Column('discount_amount', sa.Numeric(precision=10, scale=2), nullable=True))
    op.add_column('orders', sa.Column('promocode_id', sa.Uuid(), nullable=True))
    op.add_column('orders', sa.Column('loyalty_points_earned', sa.Numeric(precision=10, scale=2), nullable=True))
    op.add_column('orders', sa.Column('loyalty_points_spent', sa.Numeric(precision=10, scale=2), nullable=True))
    
    # Create promocodes table
    op.create_table('promocodes',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('business_id', sa.Uuid(), nullable=False),
        sa.Column('code', sa.String(length=50), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('discount_type', sa.String(length=20), nullable=False),
        sa.Column('discount_value', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('min_order_amount', sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column('max_discount_amount', sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column('max_uses', sa.Integer(), nullable=True),
        sa.Column('uses_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('max_uses_per_user', sa.Integer(), nullable=True, server_default='1'),
        sa.Column('valid_from', sa.DateTime(), nullable=True),
        sa.Column('valid_until', sa.DateTime(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('code')
    )
    op.create_index(op.f('ix_promocodes_business_id'), 'promocodes', ['business_id'], unique=False)
    op.create_index(op.f('ix_promocodes_code'), 'promocodes', ['code'], unique=True)

    # Create promocode_usages table
    op.create_table('promocode_usages',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('promocode_id', sa.Uuid(), nullable=False),
        sa.Column('order_id', sa.Uuid(), nullable=False),
        sa.Column('user_telegram_id', sa.BigInteger(), nullable=True),
        sa.Column('discount_amount', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('order_amount_before', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('order_amount_after', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['promocode_id'], ['promocodes.id'], ),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_promocode_usages_promocode_id'), 'promocode_usages', ['promocode_id'], unique=False)
    op.create_index(op.f('ix_promocode_usages_order_id'), 'promocode_usages', ['order_id'], unique=False)
    op.create_index(op.f('ix_promocode_usages_user_telegram_id'), 'promocode_usages', ['user_telegram_id'], unique=False)

    # Add foreign key for promocode_id in orders
    op.create_foreign_key('fk_orders_promocode_id', 'orders', 'promocodes', ['promocode_id'], ['id'])

    # Create loyalty_accounts table
    op.create_table('loyalty_accounts',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('business_id', sa.Uuid(), nullable=False),
        sa.Column('user_telegram_id', sa.BigInteger(), nullable=False),
        sa.Column('points_balance', sa.Numeric(precision=10, scale=2), nullable=False, server_default='0'),
        sa.Column('total_earned', sa.Numeric(precision=10, scale=2), nullable=False, server_default='0'),
        sa.Column('total_spent', sa.Numeric(precision=10, scale=2), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_loyalty_accounts_business_id'), 'loyalty_accounts', ['business_id'], unique=False)
    op.create_index(op.f('ix_loyalty_accounts_user_telegram_id'), 'loyalty_accounts', ['user_telegram_id'], unique=False)
    # Unique constraint on business_id + user_telegram_id
    op.create_index('ix_loyalty_accounts_business_user', 'loyalty_accounts', ['business_id', 'user_telegram_id'], unique=True)

    # Create loyalty_transactions table
    op.create_table('loyalty_transactions',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('account_id', sa.Uuid(), nullable=False),
        sa.Column('order_id', sa.Uuid(), nullable=True),
        sa.Column('transaction_type', sa.String(length=20), nullable=False),
        sa.Column('points', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('balance_after', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['account_id'], ['loyalty_accounts.id'], ),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_loyalty_transactions_account_id'), 'loyalty_transactions', ['account_id'], unique=False)
    op.create_index(op.f('ix_loyalty_transactions_order_id'), 'loyalty_transactions', ['order_id'], unique=False)


def downgrade() -> None:
    # Drop loyalty_transactions table
    op.drop_index(op.f('ix_loyalty_transactions_order_id'), table_name='loyalty_transactions')
    op.drop_index(op.f('ix_loyalty_transactions_account_id'), table_name='loyalty_transactions')
    op.drop_table('loyalty_transactions')

    # Drop loyalty_accounts table
    op.drop_index('ix_loyalty_accounts_business_user', table_name='loyalty_accounts')
    op.drop_index(op.f('ix_loyalty_accounts_user_telegram_id'), table_name='loyalty_accounts')
    op.drop_index(op.f('ix_loyalty_accounts_business_id'), table_name='loyalty_accounts')
    op.drop_table('loyalty_accounts')

    # Drop foreign key and promocode_usages table
    op.drop_index(op.f('ix_promocode_usages_user_telegram_id'), table_name='promocode_usages')
    op.drop_index(op.f('ix_promocode_usages_order_id'), table_name='promocode_usages')
    op.drop_index(op.f('ix_promocode_usages_promocode_id'), table_name='promocode_usages')
    op.drop_table('promocode_usages')

    # Drop promocodes table
    op.drop_index(op.f('ix_promocodes_code'), table_name='promocodes')
    op.drop_index(op.f('ix_promocodes_business_id'), table_name='promocodes')
    op.drop_table('promocodes')

    # Drop foreign key constraint for promocode_id
    op.drop_constraint('fk_orders_promocode_id', 'orders', type_='foreignkey')

    # Remove fields from orders table
    op.drop_column('orders', 'loyalty_points_spent')
    op.drop_column('orders', 'loyalty_points_earned')
    op.drop_column('orders', 'promocode_id')
    op.drop_column('orders', 'discount_amount')
    op.drop_column('orders', 'subtotal_amount')

    # Remove fields from products table
    op.drop_column('products', 'discount_valid_until')
    op.drop_column('products', 'discount_valid_from')
    op.drop_column('products', 'discount_price')
    op.drop_column('products', 'discount_percentage')
    # variations не удаляем, так как она существовала до этой миграции

