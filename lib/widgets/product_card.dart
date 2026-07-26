import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/models/product.dart';
import 'product_image_placeholder.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final int quantityInCart;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    this.onRemove,
    this.quantityInCart = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildList(context);
  }

  // ─── Compact Card ───────────────────────────────────────────────────────────
  Widget _buildCompact(BuildContext context) {
    final isOutOfStock = product.stock <= 0;
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                ProductImagePlaceholder(
                  label: product.imageLabel,
                  height: 96,
                  imageUrl: product.imageUrl,
                ),
                if (product.collectionName != null || product.isClearance)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (product.collectionName ?? 'CLEARANCE').toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isOutOfStock ? 'Out of stock' : 'Stock: ${product.stock}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isOutOfStock ? FontWeight.w600 : FontWeight.normal,
                    color: isOutOfStock ? AppColors.red : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPriceCompact(),
                    isOutOfStock
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Sold Out',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                          )
                        : (quantityInCart > 0
                            ? Container(
                                height: 26,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: onRemove,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                        child: Icon(Icons.remove, size: 14, color: AppColors.primary),
                                      ),
                                    ),
                                    Text('$quantityInCart',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                    GestureDetector(
                                      onTap: onAdd,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                        child: Icon(Icons.add, size: 14, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GestureDetector(
                                onTap: onAdd,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('+ Add',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
                                ),
                              )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── List Card ──────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context) {
    final isOutOfStock = product.stock <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProductImagePlaceholder(
                  label: product.imageLabel,
                  height: 64,
                  width: 64,
                  imageUrl: product.imageUrl,
                ),
              ),
              if (product.collectionName != null || product.isClearance)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA580C),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      (product.collectionName ?? 'CLEARANCE').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isOutOfStock ? 'Out of stock' : 'Stock: ${product.stock}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isOutOfStock ? FontWeight.w600 : FontWeight.normal,
                    color: isOutOfStock ? AppColors.red : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                _buildPriceList(),
              ],
            ),
          ),
          isOutOfStock
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Sold Out',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                )
              : (quantityInCart > 0
                  ? Container(
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onRemove,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(Icons.remove, size: 16, color: AppColors.primary),
                            ),
                          ),
                          Text('$quantityInCart',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          GestureDetector(
                            onTap: onAdd,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(Icons.add, size: 16, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('+ Add',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white)),
                      ),
                    )),
        ],
      ),
    );
  }

  // ─── Price Helpers ───────────────────────────────────────────────────────────

  /// Price widget for compact card
  Widget _buildPriceCompact() {
    final hasPromo = product.dealPrice != null || (product.isClearance && product.clearancePrice != null);
    final promoPrice = product.dealPrice ?? product.clearancePrice ?? product.price;
    if (hasPromo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$${_fmt(product.price)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '\$${_fmt(promoPrice)}',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C)),
          ),
        ],
      );
    }
    return Text(
      '\$${_fmt(product.price)}',
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    );
  }

  /// Price widget for list card
  Widget _buildPriceList() {
    final hasPromo = product.dealPrice != null || (product.isClearance && product.clearancePrice != null);
    final promoPrice = product.dealPrice ?? product.clearancePrice ?? product.price;
    if (hasPromo) {
      return Row(
        children: [
          Text(
            '\$${_fmt(product.price)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '\$${_fmt(promoPrice)}',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C)),
          ),
        ],
      );
    }
    return Text(
      '\$${_fmt(product.price)}',
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    );
  }

  // ─── Formatter ───────────────────────────────────────────────────────────────
  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$integerPart.${parts[1]}';
  }
}
