import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/product.dart';
import '../../core/models/cart_state.dart';
import '../../core/services/product_service.dart';
import '../../core/state/app_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/empty_state_widget.dart';
import 'product_detail_screen.dart';
import 'scanner_screen.dart';

const Map<String, List<String>> kCategoryMap = {
  'General Merchandise': ['Cables', 'Toys', 'Misc', 'Clothing', 'Supplements', 'Medicine (OTC)'],
  'Glass': ['Glass Rigs', 'Glass Accessories', 'Grinders'],
  'Lighters': ['Pocket Torches', 'High Flame', 'Butane', 'Torch Lighters'],
};

class ProductListScreen extends StatefulWidget {
  final CartState cart;
  final List<Product> initialProducts;
  final String initialCategory;

  const ProductListScreen({
    super.key,
    required this.cart,
    this.initialProducts = const [],
    this.initialCategory = 'All',
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  Map<String, List<String>> _categoryMap = kCategoryMap;
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  bool _loading = false;
  String _query = '';
  final bool _isGridView = true;
  String _selectedCategory = 'All';
  String _selectedSubCategory = 'All';
  bool? _clearanceFilter; // null = All, true = Clearance only, false = Regular only
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _selectedCategory = widget.initialCategory;
    if (widget.initialCategory != 'All') {
      _products = [];
      _page = 1;
      _hasMore = true;
      _fetch();
    } else if (widget.initialProducts.isNotEmpty) {
      _products = widget.initialProducts.where((p) => AppState.instance.hasLicenseFor(p.requiredLicense)).toList();
      _hasMore = true;
      _page = 1;
    } else {
      _fetch();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final list = await ProductService.instance.getCategories(activeOnly: true);
      if (list.isNotEmpty && mounted) {
        final Map<String, List<String>> newMap = {};
        for (var c in list) {
          final name = c['category_name'] as String;
          final subs = (c['sub_categories'] as List<dynamic>).map((e) => e as String).toList();
          newMap[name] = subs;
        }
        setState(() {
          _categoryMap = newMap;
        });
      }
    } catch (e) {
      debugPrint('Error loading dynamic category filters: $e');
    }
  }

  Future<void> _fetch({String? search, bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;
    setState(() => _loading = true);
    try {
      final pageToFetch = loadMore ? _page + 1 : 1;
      final results = await ProductService.instance.getProducts(
        search: search,
        mainCategory: _selectedCategory,
        subCategory: _selectedSubCategory,
        page: pageToFetch,
        limit: 12,
        clearance: _clearanceFilter,
      );
      if (mounted) {
        setState(() {
          if (loadMore) {
            final existingIds = _products.map((p) => p.id).toSet();
            final uniqueResults = results.where((p) => !existingIds.contains(p.id)).toList();
            _products.addAll(uniqueResults);
            _page = pageToFetch;
            _hasMore = results.length == 12;
          } else {
            _products = results;
            _page = 1;
            _hasMore = results.length == 12;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (!loadMore) _products = Product.sampleProducts;
          _loading = false;
          _hasMore = false;
        });
      }
    }
  }

  void _onSearch(String v) {
    setState(() {
      _query = v;
      _page = 1;
      _hasMore = true;
    });
    _fetch(search: v.isEmpty ? null : v);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _onSearch('');
  }

  List<Product> get _filtered {
    var list = _products;
    if (_query.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _clearanceChip({required String label, required bool? value, Color? activeColor}) {
    final isSelected = _clearanceFilter == value;
    final color = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: () {
        setState(() {
          _clearanceFilter = value;
          _products = [];
          _page = 1;
          _hasMore = true;
        });
        _fetch(search: _query.isEmpty ? null : _query);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }


  void _showFilterBottomSheet() {
    String tempCategory = _selectedCategory;
    String tempSubCategory = _selectedSubCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final tempCategories = ['All', ..._categoryMap.keys];
            final tempSubCategories = tempCategory == 'All'
                ? ['All']
                : ['All', ...(_categoryMap[tempCategory] ?? [])];

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Products',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tempCategories.map((cat) {
                      final isSelected = tempCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.white : AppColors.textSecondary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 1,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              tempCategory = cat;
                              tempSubCategory = 'All';
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  if (tempCategory != 'All' && tempSubCategories.length > 1) ...[
                    Text(
                      'Sub Category',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tempSubCategories.map((sub) {
                        final isSelected = tempSubCategory == sub;
                        return ChoiceChip(
                          label: Text(sub),
                          selected: isSelected,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          selectedColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 1,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                tempSubCategory = sub;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempCategory = 'All';
                              tempSubCategory = 'All';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
                              _selectedSubCategory = tempSubCategory;
                              _products = [];
                              _page = 1;
                              _hasMore = true;
                            });
                            Navigator.pop(context);
                            _fetch(search: _query.isEmpty ? null : _query);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Product Catalogue',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        elevation: 0,
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: const [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search brand, tobacco, snacks...',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textTertiary),
                                onPressed: _clearSearch,
                              )
                            : IconButton(
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.textTertiary),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ScannerScreen(cart: widget.cart)),
                                ),
                              ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_selectedCategory != 'All' || _selectedSubCategory != 'All')
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_selectedCategory != 'All' || _selectedSubCategory != 'All')
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: (_selectedCategory != 'All' || _selectedSubCategory != 'All')
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedCategory != 'All' || _selectedSubCategory != 'All')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_selectedCategory != 'All')
                          Chip(
                            label: Text(_selectedCategory, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                            side: const BorderSide(color: AppColors.primary, width: 0.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                            onDeleted: () {
                              setState(() {
                                _selectedCategory = 'All';
                                _selectedSubCategory = 'All';
                                _products = [];
                                _page = 1;
                                _hasMore = true;
                              });
                              _fetch(search: _query.isEmpty ? null : _query);
                            },
                          ),
                        if (_selectedSubCategory != 'All')
                          Chip(
                            label: Text(_selectedSubCategory, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                            side: const BorderSide(color: AppColors.primary, width: 0.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                            onDeleted: () {
                              setState(() {
                                _selectedSubCategory = 'All';
                                _products = [];
                                _page = 1;
                                _hasMore = true;
                              });
                              _fetch(search: _query.isEmpty ? null : _query);
                            },
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _selectedSubCategory = 'All';
                        _products = [];
                        _page = 1;
                        _hasMore = true;
                      });
                      _fetch(search: _query.isEmpty ? null : _query);
                    },
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

          // Clearance quick-filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _clearanceChip(label: 'All', value: null),
                const SizedBox(width: 8),
                _clearanceChip(label: '🏷 Clearance', value: true, activeColor: const Color(0xFFEA580C)),
                const SizedBox(width: 8),
                _clearanceChip(label: 'Regular', value: false),
              ],
            ),
          ),
          if (products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text('${products.length} products found',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (_selectedCategory != 'All') ...[
                    Text(' in $_selectedCategory',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    if (_selectedSubCategory != 'All')
                      Text(' > $_selectedSubCategory',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          Expanded(
            child: _loading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Builder(
                    builder: (context) {
                      final products = _filtered;
                      if (products.isEmpty) {
                        return EmptyStateWidget(
                          icon: Icons.sentiment_dissatisfied_outlined,
                          title: 'No products found',
                          subtitle: 'Try adjusting your search query or switching categories.',
                          buttonLabel: 'Reset Catalogue',
                          onAction: () {
                            setState(() {
                              _selectedCategory = 'All';
                              _selectedSubCategory = 'All';
                            });
                            _clearSearch();
                          },
                        );
                      }
                      return CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (_isGridView)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.69,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _buildProductItem(products[i]),
                                  childCount: products.length,
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _buildProductItem(products[i]),
                                childCount: products.length,
                              ),
                            ),
                          if (_hasMore)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: _loading
                                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                    : Center(
                                        child: TextButton(
                                          onPressed: () => _fetch(search: _query.isEmpty ? null : _query, loadMore: true),
                                          child: Text(
                                            'Load More',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            )
                          else
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 20),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return ListenableBuilder(
      listenable: widget.cart,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product, cart: widget.cart),
          )),
          child: ProductCard(
            product: product,
            compact: _isGridView,
            quantityInCart: widget.cart.getQty(product.id),
            onRemove: () => widget.cart.decrement(product.id),
            onAdd: () {
              try {
                widget.cart.add(product);
              } catch (e) {
                final messenger = ScaffoldMessenger.of(context);
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(SnackBar(
                  content: Text(e.toString(),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.white)),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.red,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ));
              }
            },
          ),
        );
      },
    );
  }
}
