"""
Референсные изображения с витрины Periche (Tilda): static.tildacdn.com.
Снято с карточек каталога (data-product-img / data-original), без optim.webp.

Исходные позиции на periche.ru (для правок маппинга):
  KODE WET:   FREQ SHAMPOO / FREQ CONDITIONER
  KODE VOLUME: VOLM SHAMPOO / VOLM CONDITIONER
  SECRET PLANTS: HEMP RITUAL *, REISHI RITUAL *
"""

# --- Оригиналы с Tilda (как в HTML) ---
FREQ_SHAMPOO_PNG = "https://static.tildacdn.com/stor6636-3465-4833-b231-653162323439/69913862.png"
FREQ_CONDITIONER_PNG = "https://static.tildacdn.com/stor3631-6665-4963-b761-343331373936/90989235.png"
VOLM_SHAMPOO_JPG = "https://static.tildacdn.com/stor6366-6632-4037-b138-623064353861/59636030.jpg"
VOLM_CONDITIONER_JPG = "https://static.tildacdn.com/stor6134-3136-4737-a331-333234623362/54631624.jpg"
HEMP_SHAMPOO_PNG = "https://static.tildacdn.com/stor3264-3036-4430-b231-323661353133/64978873.png"
HEMP_CONDITIONER_PNG = "https://static.tildacdn.com/stor6130-3761-4439-b738-636532613333/98407205.png"
HEMP_ENRICHED_OIL_PNG = "https://static.tildacdn.com/stor6133-6533-4063-b162-346265636266/64296082.png"
REISHI_SHAMPOO_PNG = "https://static.tildacdn.com/stor6431-3531-4861-b664-323832663231/27058388.png"
REISHI_MASK_JPG = "https://static.tildacdn.com/stor3630-6165-4466-b938-396334653631/30164944.jpg"
REISHI_LEAVE_IN_MASK_JPG = "https://static.tildacdn.com/stor3865-6437-4533-b530-306431343762/23409321.jpg"

# Сырые карточки (артикулы с витрины) — для справки / расширения парсера
PERICHE_TILDA_CARDS: tuple[dict[str, str], ...] = (
    {"name": "FREQ SHAMPOO", "sku": "KOFREQ", "image_url": FREQ_SHAMPOO_PNG},
    {"name": "FREQ CONDITIONER", "sku": "KOAFREQ", "image_url": FREQ_CONDITIONER_PNG},
    {"name": "VOLM SHAMPOO", "sku": "KOVOLM", "image_url": VOLM_SHAMPOO_JPG},
    {"name": "VOLM CONDITIONER", "sku": "KOAVOLM", "image_url": VOLM_CONDITIONER_JPG},
    {"name": "HEMP RITUAL SHAMPOO", "sku": "SPHSH500", "image_url": HEMP_SHAMPOO_PNG},
    {"name": "HEMP RITUAL CONDITIONER", "sku": "SPHC500", "image_url": HEMP_CONDITIONER_PNG},
    {"name": "HEMP RITUAL ENRICHED OIL", "sku": "SPHO100", "image_url": HEMP_ENRICHED_OIL_PNG},
    {"name": "REISHI RITUAL SHAMPOO", "sku": "SPRESH500", "image_url": REISHI_SHAMPOO_PNG},
    {"name": "REISHI RITUAL MASK", "sku": "SPREM500", "image_url": REISHI_MASK_JPG},
    {"name": "REISHI RITUAL LEAVE-IN MASK", "sku": "SPREM100", "image_url": REISHI_LEAVE_IN_MASK_JPG},
)

# Маппинг демо-SKU → картинка Periche (по смыслу линейки / типа продукта)
HAIR_SKU_PERICHE_IMAGE_URL: dict[str, str] = {
    "HAIR-SHAMP-001": VOLM_SHAMPOO_JPG,
    "HAIR-SHAMP-002": REISHI_SHAMPOO_PNG,
    "HAIR-SHAMP-003": FREQ_SHAMPOO_PNG,
    "HAIR-SHAMP-004": HEMP_SHAMPOO_PNG,
    "HAIR-SHAMP-005": HEMP_SHAMPOO_PNG,
    "HAIR-COND-001": FREQ_CONDITIONER_PNG,
    "HAIR-COND-002": VOLM_CONDITIONER_JPG,
    "HAIR-COND-003": REISHI_LEAVE_IN_MASK_JPG,
    "HAIR-MASK-001": REISHI_MASK_JPG,
    "HAIR-MASK-002": HEMP_CONDITIONER_PNG,
    "HAIR-MASK-003": HEMP_ENRICHED_OIL_PNG,
    "HAIR-MASK-004": FREQ_CONDITIONER_PNG,
    "HAIR-OIL-001": HEMP_ENRICHED_OIL_PNG,
    "HAIR-OIL-002": HEMP_ENRICHED_OIL_PNG,
    "HAIR-SERUM-001": REISHI_LEAVE_IN_MASK_JPG,
    "HAIR-SERUM-002": HEMP_ENRICHED_OIL_PNG,
    "HAIR-STYLE-001": FREQ_CONDITIONER_PNG,
    "HAIR-STYLE-002": VOLM_SHAMPOO_JPG,
    "HAIR-STYLE-003": HEMP_CONDITIONER_PNG,
    "HAIR-STYLE-004": FREQ_SHAMPOO_PNG,
    "HAIR-DYE-001": REISHI_MASK_JPG,
    "HAIR-DYE-002": FREQ_CONDITIONER_PNG,
    "HAIR-DYE-003": VOLM_SHAMPOO_JPG,
    "HAIR-DYE-004": HEMP_SHAMPOO_PNG,
}
