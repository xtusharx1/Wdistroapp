import 'api_client.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await ApiClient.instance.post('/auth/shop/login', {
      'email': email,
      'password': password,
    });
    return res['data']['shop'] as Map<String, dynamic>;
  }

  /// Creates a standalone Shop account directly.
  Future<Map<String, dynamic>> registerShop({
    required String ownerName,
    required String email,
    required String password,
    required String shopName,
    required String sellerPermit,
    String? tobaccoLicense,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? zip,
  }) async {
    final res = await ApiClient.instance.post('/auth/shop/register', {
      'ownerName': ownerName,
      'email': email,
      'password': password,
      'shopName': shopName,
      'sellerPermit': sellerPermit,
      'tobaccoLicense': tobaccoLicense,
      'phone': phone,
      'address': address ?? '',
      'city': city ?? '',
      'state': state ?? '',
      'zip': zip ?? '',
    });
    return res['data']['shop'] as Map<String, dynamic>;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    await ApiClient.instance.post('/auth/shop/reset-password', {
      'email': email,
      'newPassword': newPassword,
    });
  }
}
