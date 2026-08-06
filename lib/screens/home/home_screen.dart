import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/product.dart';
import '../../core/models/cart_state.dart';
import '../../core/services/product_service.dart';
import '../../core/state/app_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/w_logo.dart';
import '../products/product_list_screen.dart';
import '../products/product_detail_screen.dart';
import '../cart/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  final CartState cart;

  const HomeScreen({super.key, required this.cart});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  bool _loading = true;

  List<Map<String, dynamic>> _categories = [];

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'General Merchandise':
        return Icons.grid_view_rounded;
      case 'Glass':
        return Icons.wine_bar_rounded;
      case 'Tobacco':
        return Icons.smoking_rooms_rounded;
      case 'Lighters':
        return Icons.local_fire_department_rounded;
      case 'Vape':
        return Icons.air_rounded;
      case 'Rolling Papers':
        return Icons.sticky_note_2_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await ProductService.instance.getCategories(activeOnly: true);
      if (list.isNotEmpty && mounted) {
        setState(() {
          _categories = list.map((e) {
            final name = e['category_name'] as String;
            return {
              'name': name,
              'icon': _getCategoryIcon(name),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading dynamic categories: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final results = await Future.wait([
        ProductService.instance.getProducts(limit: 20),
        ProductService.instance.getFeaturedProducts(),
      ]);
      if (mounted) {
        setState(() {
          _products = results[0];
          _featuredProducts = results[1];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _products = Product.sampleProducts;
          _featuredProducts = [];
          _loading = false;
        });
      }
    }
  }

  List<Product> get _popular => _featuredProducts;

  void _openCart() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CartScreen(cart: widget.cart)),
  );

  void _openProductList() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ProductListScreen(cart: widget.cart, initialProducts: _products),
    ),
  );
  Future<void> _refreshAll() async {
    await Future.wait([
      _loadCategories(),
      _loadProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: ListView(
            children: [
              // ── App Bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    const WLogo(size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'W Distro',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: widget.cart,
                      builder: (_, __) => GestureDetector(
                        onTap: _openCart,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (widget.cart.itemCount > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${widget.cart.itemCount}',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search Bar ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: _openProductList,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Search products...',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Browse Categories Header ─────────────────────────────
              if (_categories.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Browse Categories',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _openProductList,
                        child: Text(
                          'Browse All',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Categories List ──────────────────────────────────────
                SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductListScreen(
                                cart: widget.cart,
                                initialCategory: cat['name'] as String,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 80,
                          child: Column(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  cat['icon'] as IconData,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat['name'] as String,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Popular This Week ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular this week',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _openProductList,
                      child: Text(
                        'See all',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Product List ─────────────────────────────────────────
              if (_loading)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_popular.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No featured products yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ListenableBuilder(
                  listenable: widget.cart,
                  builder: (_, __) => Column(
                    children: _popular
                        .map(
                          (product) => GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    product: product,
                                    cart: widget.cart,
                                  ),
                                ),
                              );
                            },
                            child: ProductCard(
                              product: product,
                              compact: false,
                              quantityInCart: widget.cart.getQty(product.id),
                              onRemove: () => widget.cart.decrement(product.id),
                              onAdd: () {
                                try {
                                  widget.cart.add(product);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.red,
                                      margin: const EdgeInsets.fromLTRB(
                                        20,
                                        0,
                                        20,
                                        20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
