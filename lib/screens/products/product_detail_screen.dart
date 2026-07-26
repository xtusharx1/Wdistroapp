import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/product.dart';
import '../../core/models/cart_state.dart';
import '../../core/services/product_service.dart';
import '../../widgets/product_image_placeholder.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final CartState cart;

  const ProductDetailScreen({super.key, required this.product, required this.cart});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  List<Product>? _variations;

  @override
  void initState() {
    super.initState();
    _loadVariations();
  }

  Future<void> _loadVariations() async {
    try {
      final full = await ProductService.instance.getProduct(widget.product.id);
      if (mounted) setState(() => _variations = full.variations ?? []);
    } catch (_) {
      if (mounted) setState(() => _variations = []);
    }
  }

  void _addToCart() {
    try {
      final currentInCart = widget.cart.getQty(widget.product.id);
      if (currentInCart + _qty > widget.product.stock) {
        throw 'Requested quantity exceeds available stock.';
      }
      for (var i = 0; i < _qty; i++) {
        widget.cart.add(widget.product);
      }
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CartScreen(cart: widget.cart),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.white)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.red,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImagePlaceholder(
                    label: '${p.imageLabel} RICE 25KG',
                    height: 220,
                    imageUrl: p.imageUrl,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.category.toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.primary, letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        // Clearance badge
                        if (p.collectionName != null || p.isClearance) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              border: Border.all(color: const Color(0xFFEA580C)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🏷 ${(p.collectionName ?? 'CLEARANCE')}',
                              style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: const Color(0xFFEA580C), letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(p.name,
                            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        // Price display
                        if (p.dealPrice != null || (p.isClearance && p.clearancePrice != null)) ...[
                          Text(
                            '\$${_fmtPrice(p.price)}',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${_fmtPrice(p.dealPrice ?? p.clearancePrice!)}',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C)),
                          ),
                        ] else
                          Text('\$${_fmtPrice(p.price)}',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  p.stock <= 0 ? Icons.error_outline : Icons.check_circle,
                                  size: 14,
                                  color: p.stock <= 0 ? AppColors.red : AppColors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  p.stock <= 0 ? 'Out of stock' : 'In stock · ${p.stock} available',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: p.stock <= 0 ? AppColors.red : AppColors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // ── Variations ───────────────────────────────────────
                        if (_variations != null && _variations!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Variations',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _variations!.length,
                              itemBuilder: (_, i) {
                                final v = _variations![i];
                                final vPrice = v.isClearance && v.clearancePrice != null
                                    ? v.clearancePrice!
                                    : v.price;
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                        product: v,
                                        cart: widget.cart,
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(9.5),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: 72,
                                            width: double.infinity,
                                            child: v.imageUrl != null
                                                ? Image.network(
                                                    v.imageUrl!,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) => _varFallback(v),
                                                  )
                                                : _varFallback(v),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  v.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                    height: 1.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  '\$${_fmtPrice(vPrice)}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  color: (v.dealPrice != null || (v.isClearance && v.clearancePrice != null))
                                                      ? const Color(0xFFEA580C)
                                                      : AppColors.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 5, height: 5,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: v.stock <= 0 ? AppColors.red : AppColors.green,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        v.stock <= 0 ? 'Out of stock' : '${v.stock} avail.',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 9,
                                                          color: v.stock <= 0 ? AppColors.red : AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ),
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
                          ),
                        ],

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text('Quantity',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _qtyButton(Icons.remove, () { if (p.stock > 0 && _qty > 1) setState(() => _qty--); }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                  p.stock <= 0 ? '0' : '$_qty',
                                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            ),
                            _qtyButton(Icons.add, () { if (p.stock > 0) setState(() => _qty++); }),
                            const Spacer(),
                            Text('Subtotal: \$${_fmtPrice(p.stock <= 0 ? 0.0 : p.effectivePrice * _qty)}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                        if (p.description != null && p.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text('Description',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text(
                              p.description!,
                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton.icon(
              onPressed: p.stock <= 0 ? null : _addToCart,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text(p.stock <= 0 ? 'Sold Out' : 'Add to cart'),
              style: p.stock <= 0
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.grey.shade500,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _varFallback(Product v) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Text(
        v.name.isNotEmpty ? v.name[0].toUpperCase() : '?',
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }

  String _fmtPrice(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$integerPart.${parts[1]}';
  }
}
