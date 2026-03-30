import 'package:flutter/material.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';
import 'package:tg_store/mini_app/presentation/navigation/app_router.dart';
import 'package:tg_store/mini_app/presentation/widgets/animated_cart_button.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final EdgeInsets? margin;

  const ProductCard({
    super.key,
    required this.product,
    this.margin,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MouseRegion(
      onEnter: (_) {
        _controller.forward();
      },
      onExit: (_) {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: _elevationAnimation.value,
              color: colorScheme.surfaceContainerHighest, // Фон карточки из темы
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.08),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  AppRouter.toProduct(widget.product.id);
                },
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product image with modern design
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        height: 240,
                        width: double.infinity,
                        color: colorScheme.surface,
                        child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                            ? Builder(
                                builder: (context) {
                                  final imageUrl = widget.product.imageUrl!;
                                  final proxiedUrl = ApiConstants.imageProxyFull(imageUrl, AppConfig.baseUrl);
                                  logger.d('Loading image: $imageUrl -> $proxiedUrl');
                                  return Image.network(
                                    proxiedUrl,
                                    fit: BoxFit.contain,
                                    headers: const {
                                      'Accept': 'image/*',
                                    },
                                    // Оптимизация: ограничение размера кеша для экономии памяти
                                    cacheWidth: 400,
                                    cacheHeight: 400,
                                    loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: colorScheme.surface,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: colorScheme.primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  // Логируем ошибку для отладки
                                  debugPrint('Image load error for ${widget.product.imageUrl}: $error');
                                  return Container(
                                    color: colorScheme.surface,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                            color: colorScheme.outline.withOpacity(0.3),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Не удалось загрузить изображение',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.outline.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                  );
                                },
                              )
                            : Container(
                                color: colorScheme.surface,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(
                        color: colorScheme.outline,
                        height: 2,
                      ),
                    ),
                    // Content section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Product title
                          Text(
                            widget.product.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Product description
                          if (widget.product.description != null && widget.product.description!.isNotEmpty)
                            Text(
                              widget.product.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          // Stock status badge
                          if (widget.product.stockQuantity != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.product.isInStock
                                          ? colorScheme.primaryContainer
                                          : colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.product.isInStock
                                              ? Icons.check_circle_outline
                                              : Icons.cancel_outlined,
                                          size: 14,
                                          color: widget.product.isInStock
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onErrorContainer,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.product.isInStock
                                              ? 'В наличии (${widget.product.stockQuantity} шт.)'
                                              : 'Нет в наличии',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: widget.product.isInStock
                                                ? colorScheme.onPrimaryContainer
                                                : colorScheme.onErrorContainer,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Price and add button row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Price badge
                              widget.product.hasActiveDiscount
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Новая цена со скидкой
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.tertiary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                widget.product.currentPrice.toStringAsFixed(0),
                                                style: theme.textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onTertiary,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '₽',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.onTertiary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Старая цена (зачеркнутая) справа в красивом контейнере
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: colorScheme.outline.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            '${widget.product.price.toStringAsFixed(0)} ₽',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              decoration: TextDecoration.lineThrough,
                                              decorationThickness: 2,
                                              color: colorScheme.onSurface.withOpacity(0.6),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.product.currentPrice.toStringAsFixed(0),
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onPrimary,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '₽',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              // Add to cart button
                              AnimatedCartButton(product: widget.product),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
