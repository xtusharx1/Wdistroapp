import 'api_client.dart';
import '../models/product.dart';
import '../state/app_state.dart';

class ProductService {
  static final ProductService instance = ProductService._();
  ProductService._();

  Future<List<Product>> getProducts({String? search, String? mainCategory, String? subCategory, int page = 1, int limit = 20, bool? clearance}) async {
    var path = '/products?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) path += '&search=${Uri.encodeComponent(search)}';
    if (mainCategory != null && mainCategory.isNotEmpty && mainCategory != 'All') {
      path += '&mainCategory=${Uri.encodeComponent(mainCategory)}';
    }
    if (subCategory != null && subCategory.isNotEmpty && subCategory != 'All') {
      path += '&subCategory=${Uri.encodeComponent(subCategory)}';
    }
    if (clearance != null) {
      path += '&clearance=${clearance ? 'true' : 'false'}';
    }

    final res = await ApiClient.instance.get(path);
    final list = res['data']['products'] as List<dynamic>;
    final products = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();

    return products.where((p) => AppState.instance.hasLicenseFor(p.requiredLicense)).toList();
  }

  Future<List<Product>> getFeaturedProducts() async {
    final res = await ApiClient.instance.get('/products/featured');
    final list = res['data']['products'] as List<dynamic>;
    final products = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    return products.where((p) => AppState.instance.hasLicenseFor(p.requiredLicense)).toList();
  }

  Future<Product> scanProduct(String code) async {
    final res = await ApiClient.instance.get('/products/scan/${Uri.encodeComponent(code)}');
    final product = Product.fromJson(res['data']['product'] as Map<String, dynamic>);
    if (!AppState.instance.hasLicenseFor(product.requiredLicense)) {
      throw Exception("License Required: You do not have the required license to view or purchase this product.");
    }
    return product;
  }

  Future<Product> getProduct(int id) async {
    final res = await ApiClient.instance.get('/products/$id');
    final product = Product.fromJson(res['data']['product'] as Map<String, dynamic>);

    if (!AppState.instance.hasLicenseFor(product.requiredLicense)) {
      final licenseReq = product.requiredLicense.toLowerCase().contains('tobacco')
          ? 'Tobacco License'
          : 'Seller Permit';
      throw Exception("$licenseReq Required for this product category.");
    }

    return product;
  }

  Future<List<Map<String, dynamic>>> getCategories({bool activeOnly = true}) async {
    final res = await ApiClient.instance.get('/categories?active_only=$activeOnly');
    final list = res['data']['categories'] as List<dynamic>;
    final categories = list.map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList();

    // Fetch visible products to check category/subcategory content for current user's license
    List<Product> visibleProducts = [];
    try {
      visibleProducts = await getProducts(limit: 1000);
    } catch (_) {}

    final visibleMainCategories = visibleProducts.map((p) => p.mainCategory.trim().toLowerCase()).toSet();
    final visibleCategories = visibleProducts.map((p) => p.category.trim().toLowerCase()).toSet();
    final visibleSubCategories = visibleProducts.map((p) => p.subCategory.trim().toLowerCase()).toSet();

    final filteredCategories = <Map<String, dynamic>>[];
    for (final cat in categories) {
      final name = (cat['category_name'] as String? ?? cat['name'] as String? ?? '').trim();
      final reqLic = cat['required_license'] as String? ?? cat['requiredLicense'] as String?;

      // 1. If explicit required_license exists on category, check license requirement
      if (reqLic != null && reqLic.isNotEmpty) {
        if (!AppState.instance.hasLicenseFor(reqLic)) {
          continue;
        }
      } else {
        // 2. If no required_license on category, filter by checking whether it contains at least one product visible to current user
        final normName = name.toLowerCase();
        final isVisibleCategory = visibleMainCategories.contains(normName) || visibleCategories.contains(normName);
        if (!isVisibleCategory) {
          continue;
        }
      }

      // Filter sub_categories inside category if present
      if (cat.containsKey('sub_categories') && cat['sub_categories'] is List) {
        final subs = (cat['sub_categories'] as List<dynamic>).map((e) => e.toString()).toList();
        final filteredSubs = subs.where((s) => visibleSubCategories.contains(s.trim().toLowerCase())).toList();
        cat['sub_categories'] = filteredSubs;
      }

      filteredCategories.add(cat);
    }

    return filteredCategories;
  }

  Future<List<Map<String, dynamic>>> getCollections({bool activeOnly = true}) async {
    final res = await ApiClient.instance.get('/collections?active_only=$activeOnly');
    final list = res['data']['collections'] as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
}
