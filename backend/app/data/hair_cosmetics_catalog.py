"""
Категории и товары косметики для волос — единый источник для:
- create_hair_cosmetics_business.py (slug hair-cosmetics)
- create_demo_menu.py (slug default-business)

Не дублируйте списки в других файлах — импортируйте отсюда.
"""
from decimal import Decimal

# Тема для бизнеса косметики (как в create_hair_cosmetics_business.py)
HAIR_COSMETICS_THEME_SETTINGS = {
    "primary_color": "#C2185B",
    "background_color": "#FFF5F8",
    "text_color": "#2C1810",
}

HAIR_COSMETICS_CATEGORIES_DATA = [
    {"name": "Шампуни", "position": 1, "surcharge": Decimal("0.00")},
    {"name": "Кондиционеры", "position": 2, "surcharge": Decimal("0.00")},
    {"name": "Маски для волос", "position": 3, "surcharge": Decimal("0.00")},
    {"name": "Масла и сыворотки", "position": 4, "surcharge": Decimal("0.00")},
    {"name": "Средства для укладки", "position": 5, "surcharge": Decimal("0.00")},
    {"name": "Окрашивание", "position": 6, "surcharge": Decimal("0.00")},
]

HAIR_COSMETICS_PRODUCTS_DATA = [
    {
        "title": "Шампунь для объема",
        "description": "Придает волосам объем и пышность. Подходит для тонких волос",
        "price": Decimal("890.00"),
        "sku": "HAIR-SHAMP-001",
        "category": "Шампуни",
    },
    {
        "title": "Шампунь для поврежденных волос",
        "description": "Интенсивное восстановление. С кератином и протеинами",
        "price": Decimal("990.00"),
        "sku": "HAIR-SHAMP-002",
        "category": "Шампуни",
    },
    {
        "title": "Шампунь для жирных волос",
        "description": "Матирующий эффект, контролирует выделение себума",
        "price": Decimal("850.00"),
        "sku": "HAIR-SHAMP-003",
        "category": "Шампуни",
    },
    {
        "title": "Шампунь для сухих волос",
        "description": "Интенсивное увлажнение. С маслами арганы и кокоса",
        "price": Decimal("950.00"),
        "sku": "HAIR-SHAMP-004",
        "category": "Шампуни",
    },
    {
        "title": "Безсульфатный шампунь",
        "description": "Мягкое очищение для чувствительной кожи головы",
        "price": Decimal("1100.00"),
        "sku": "HAIR-SHAMP-005",
        "category": "Шампуни",
    },
    {
        "title": "Кондиционер для волос",
        "description": "Восстанавливающий кондиционер с кератином. Разглаживает и питает волосы",
        "price": Decimal("950.00"),
        "sku": "HAIR-COND-001",
        "category": "Кондиционеры",
    },
    {
        "title": "Кондиционер для объема",
        "description": "Легкий кондиционер, не утяжеляет волосы",
        "price": Decimal("890.00"),
        "sku": "HAIR-COND-002",
        "category": "Кондиционеры",
    },
    {
        "title": "Кондиционер-спрей",
        "description": "Быстрый уход без смывания. Для ежедневного использования",
        "price": Decimal("650.00"),
        "sku": "HAIR-COND-003",
        "category": "Кондиционеры",
    },
    {
        "title": "Маска для волос",
        "description": "Интенсивное восстановление поврежденных волос. С аргановым маслом",
        "price": Decimal("1290.00"),
        "sku": "HAIR-MASK-001",
        "category": "Маски для волос",
    },
    {
        "title": "Маска для объема",
        "description": "Придает волосам объем и упругость. С протеинами",
        "price": Decimal("1190.00"),
        "sku": "HAIR-MASK-002",
        "category": "Маски для волос",
    },
    {
        "title": "Маска для блеска",
        "description": "Добавляет волосам здоровый блеск и сияние",
        "price": Decimal("1090.00"),
        "sku": "HAIR-MASK-003",
        "category": "Маски для волос",
    },
    {
        "title": "Маска для окрашенных волос",
        "description": "Сохраняет цвет, питает и защищает окрашенные волосы",
        "price": Decimal("1390.00"),
        "sku": "HAIR-MASK-004",
        "category": "Маски для волос",
    },
    {
        "title": "Масло для кончиков волос",
        "description": "Защита и питание кончиков волос. Предотвращает сечение",
        "price": Decimal("690.00"),
        "sku": "HAIR-OIL-001",
        "category": "Масла и сыворотки",
    },
    {
        "title": "Аргановое масло",
        "description": "Универсальное масло для всех типов волос. Придает блеск и мягкость",
        "price": Decimal("890.00"),
        "sku": "HAIR-OIL-002",
        "category": "Масла и сыворотки",
    },
    {
        "title": "Сыворотка для роста волос",
        "description": "Стимулирует рост волос. С пептидами и биотином",
        "price": Decimal("1590.00"),
        "sku": "HAIR-SERUM-001",
        "category": "Масла и сыворотки",
    },
    {
        "title": "Сыворотка от выпадения",
        "description": "Укрепляет корни волос, предотвращает выпадение",
        "price": Decimal("1790.00"),
        "sku": "HAIR-SERUM-002",
        "category": "Масла и сыворотки",
    },
    {
        "title": "Термозащитный спрей",
        "description": "Защита волос от высоких температур при укладке",
        "price": Decimal("750.00"),
        "sku": "HAIR-STYLE-001",
        "category": "Средства для укладки",
    },
    {
        "title": "Лак для волос",
        "description": "Надежная фиксация прически. Сильная фиксация",
        "price": Decimal("590.00"),
        "sku": "HAIR-STYLE-002",
        "category": "Средства для укладки",
    },
    {
        "title": "Мусс для объема",
        "description": "Создает объем и упругость. Для корней волос",
        "price": Decimal("690.00"),
        "sku": "HAIR-STYLE-003",
        "category": "Средства для укладки",
    },
    {
        "title": "Пена для укладки",
        "description": "Гибкая фиксация, естественный вид",
        "price": Decimal("650.00"),
        "sku": "HAIR-STYLE-004",
        "category": "Средства для укладки",
    },
    {
        "title": "Краска для волос (1 шт)",
        "description": "Профессиональная краска для волос. Богатая палитра оттенков",
        "price": Decimal("450.00"),
        "sku": "HAIR-DYE-001",
        "category": "Окрашивание",
    },
    {
        "title": "Окислитель для краски",
        "description": "Профессиональный окислитель 3%, 6%, 9%",
        "price": Decimal("350.00"),
        "sku": "HAIR-DYE-002",
        "category": "Окрашивание",
    },
    {
        "title": "Блондирующий порошок",
        "description": "Для осветления волос. С аммиаком",
        "price": Decimal("550.00"),
        "sku": "HAIR-DYE-003",
        "category": "Окрашивание",
    },
    {
        "title": "Тонирующая маска",
        "description": "Коррекция оттенка, придание блеска. Без аммиака",
        "price": Decimal("790.00"),
        "sku": "HAIR-DYE-004",
        "category": "Окрашивание",
    },
]
