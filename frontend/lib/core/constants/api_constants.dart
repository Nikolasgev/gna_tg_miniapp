class ApiConstants {
  // Base paths
  static const String apiVersion = '/api/v1';
  
  // Telegram endpoints
  static const String validateInitData = '$apiVersion/telegram/validate_init_data';
  
  // Business endpoints
  static String businessBySlug(String slug) => '$apiVersion/businesses/$slug';
  static String businessConfig(String slug) => '$apiVersion/businesses/$slug/config';
  static String businessSettings(String slug) => '$apiVersion/businesses/$slug/settings';
  static String businessProducts(String slug) => '$apiVersion/products/$slug/products';
  static String businessCategories(String slug) => '$apiVersion/categories/$slug/categories';
  
  // Products endpoints
  static String product(String id) => '$apiVersion/products/$id';
  
  // Images endpoints
  static String imageProxy(String imageUrl) {
    // Если это уже относительный URL (загруженный файл), возвращаем как есть
    if (imageUrl.startsWith('/api/v1/images/uploads/') || imageUrl.startsWith('/api/v1/images/uploads')) {
      return imageUrl;
    }
    // Если это полный URL на наш сервер (загруженный файл), извлекаем относительный путь
    if (imageUrl.contains('/api/v1/images/uploads/')) {
      final uri = Uri.parse(imageUrl);
      return uri.path; // Возвращаем относительный путь, например: /api/v1/images/uploads/filename.png
    }
    // Для внешних URL используем прокси (но теперь это не должно использоваться для продуктов)
    final encodedUrl = Uri.encodeComponent(imageUrl);
    return '$apiVersion/images/proxy?url=$encodedUrl';
  }
  
  // Полный URL для изображения (с baseUrl)
  // Теперь используется только для загруженных файлов, внешние URL не поддерживаются
  static String imageProxyFull(String imageUrl, String baseUrl) {
    // Если imageUrl пустой или null, возвращаем пустую строку
    if (imageUrl.isEmpty) {
      return '';
    }

    // Same-origin (Mini App с того же хоста, что и API): относительные URL без baseUrl
    if (baseUrl.isEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageProxy(imageUrl);
      }
      if (imageUrl.startsWith('/')) {
        return imageUrl;
      }
      return '$apiVersion/images/uploads/$imageUrl';
    }
    
    // Если это уже полный URL (начинается с http:// или https://)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Если это полный URL с нашим baseUrl, возвращаем как есть (не используем прокси)
      if (imageUrl.startsWith(baseUrl)) {
        return imageUrl;
      }
      // Для внешних URL используем прокси (но это не должно использоваться для продуктов)
      final proxyPath = imageProxy(imageUrl);
      if (proxyPath.startsWith('http://') || proxyPath.startsWith('https://')) {
        return proxyPath;
      }
      return '$baseUrl$proxyPath';
    }
    
    // Если это относительный путь (начинается с /), добавляем baseUrl
    // Это правильный путь для загруженных файлов: /api/v1/images/uploads/filename.png
    if (imageUrl.startsWith('/')) {
      return '$baseUrl$imageUrl';
    }
    
    // Если это просто имя файла без пути, предполагаем что это загруженный файл
    return '$baseUrl$apiVersion/images/uploads/$imageUrl';
  }
  static const String uploadImage = '$apiVersion/images/upload';
  
  // Orders endpoints
  static String createOrder(String slug) => '$apiVersion/orders/$slug/orders';
  static String order(String id) => '$apiVersion/orders/orders/$id';
  static String cancelOrder(String id) => '$apiVersion/orders/orders/$id/cancel';
  static String updateOrderStatus(String id) => '$apiVersion/orders/orders/$id/status';
  static String businessOrders(String businessSlug) => '$apiVersion/orders/$businessSlug/orders';
  static String userOrders(int telegramId, {String? businessSlug}) {
    final params = businessSlug != null ? '?business_slug=$businessSlug' : '';
    return '$apiVersion/orders/orders/user/$telegramId$params';
  }
  
  // Delivery endpoints
  static String calculateDeliveryCost() => '$apiVersion/delivery/calculate';
  
  // Address endpoints
  static String suggestAddresses() => '$apiVersion/addresses/suggest';
  
  // Admin endpoints
  static const String adminLogin = '$apiVersion/admin/login';
  static String adminBusinesses = '$apiVersion/businesses';
  static String adminProducts(String businessSlug) => '$apiVersion/products/$businessSlug/products';
  static String adminProduct(String productId) => '$apiVersion/products/$productId';
  static String adminCategories(String businessSlug) => '$apiVersion/categories/$businessSlug/categories';
  static String adminCategory(String categoryId) => '$apiVersion/categories/$categoryId';
  static String adminOrders(String businessId) => '$apiVersion/businesses/$businessId/orders';
  
  // Promocodes endpoints
  static String validatePromocode(String businessId) => '$apiVersion/businesses/$businessId/promocodes/validate';
  static String createPromocode(String businessId) => '$apiVersion/businesses/$businessId/promocodes';
  static String promocodes(String businessId) => '$apiVersion/businesses/$businessId/promocodes';
  static String promocode(String promocodeId) => '$apiVersion/promocodes/$promocodeId';
  
  // Loyalty endpoints
  static String loyaltyAccount(String businessId, int userTelegramId) => '$apiVersion/businesses/$businessId/loyalty/account/$userTelegramId';
  static String loyaltyAccountDetail(String businessId, int userTelegramId) => '$apiVersion/businesses/$businessId/loyalty/account/$userTelegramId/detail';
  static String loyaltyAccountBySlug(String businessSlug) => '$apiVersion/businesses/$businessSlug/loyalty/account';
  
  // Analytics endpoints
  static String analyticsSummary(String businessId) => '$apiVersion/businesses/$businessId/analytics/summary';
}

