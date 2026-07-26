import 'api_client.dart';

class ShopService {
  static final ShopService instance = ShopService._();
  ShopService._();

  /// Fetch all shops then find the one belonging to ownerId.
  Future<Map<String, dynamic>?> getShopByOwner(int ownerId) async {
    final res = await ApiClient.instance.get('/shops');
    final shops = res['data']['shops'] as List<dynamic>;
    final match = shops.cast<Map<String, dynamic>>()
        .where((s) => s['owner_id'] == ownerId)
        .toList();
    return match.isNotEmpty ? match.first : null;
  }

  Future<Map<String, dynamic>?> getShopById(int shopId) async {
    final res = await ApiClient.instance.get('/shops');
    final shops = res['data']['shops'] as List<dynamic>;
    final match = shops.cast<Map<String, dynamic>>()
        .where((s) => s['id'] == shopId)
        .toList();
    return match.isNotEmpty ? match.first : null;
  }
}
