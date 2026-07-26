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

    return products;
  }

  Future<List<Product>> getFeaturedProducts() async {
    final res = await ApiClient.instance.get('/products/featured');
    final list = res['data']['products'] as List<dynamic>;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> scanProduct(String code) async {
    final res = await ApiClient.instance.get('/products/scan/${Uri.encodeComponent(code)}');
    return Product.fromJson(res['data']['product'] as Map<String, dynamic>);
  }

  Future<Product> getProduct(int id) async {
    final res = await ApiClient.instance.get('/products/$id');
    final product = Product.fromJson(res['data']['product'] as Map<String, dynamic>);

    final shop = AppState.instance.shop;
    if (shop != null) {
      if (product.requiredLicense == 'Seller Permit') {
        if (!shop.approved || shop.sellerPermit == null || shop.sellerPermit!.isEmpty) {
          throw Exception("Seller Permit Required for this product category.");
        }
      }
      if (product.requiredLicense == 'Tobacco License') {
        if (!shop.approved || shop.tobaccoLicense == null || shop.tobaccoLicense!.isEmpty) {
          throw Exception("Tobacco License Required for this product category.");
        }
      }
    }

    return product;
  }

  Future<List<Map<String, dynamic>>> getCategories({bool activeOnly = true}) async {
    final res = await ApiClient.instance.get('/categories?active_only=$activeOnly');
    final list = res['data']['categories'] as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getCollections({bool activeOnly = true}) async {
    final res = await ApiClient.instance.get('/collections?active_only=$activeOnly');
    final list = res['data']['collections'] as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
}
