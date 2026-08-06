import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final int id;
  final String name;
  final String email;

  const AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> j) =>
      AppUser(id: j['id'] as int, name: j['name'] as String, email: j['email'] as String);
}

class AppShop {
  final int id;
  final String shopName;
  final String ownerName;
  final String email;
  final String contactDetails;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String approvalStatus;
  final bool approved;
  final String? sellerPermit;
  final String? tobaccoLicense;

  const AppShop({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.email,
    required this.contactDetails,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.approvalStatus,
    required this.approved,
    this.sellerPermit,
    this.tobaccoLicense,
  });

  factory AppShop.fromJson(Map<String, dynamic> j) => AppShop(
        id: j['id'] as int,
        shopName: j['shop_name'] as String? ?? '',
        ownerName: j['owner_name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        contactDetails: j['contact_details'] as String? ?? '',
        address: j['address'] as String? ?? '',
        city: j['city'] as String? ?? '',
        state: j['state'] as String? ?? '',
        zip: j['zip'] as String? ?? '',
        approvalStatus: j['approval_status'] as String? ?? 'Pending',
        approved: j['approved'] as bool? ?? false,
        sellerPermit: j['seller_permit'] as String?,
        tobaccoLicense: j['tobacco_license'] as String?,
      );

  /// Check if shop has required license/permit (e.g. tobacco, seller permit).
  bool hasLicenseFor(String? requiredLicense) {
    if (requiredLicense == null) return true;
    final req = requiredLicense.trim().toLowerCase();
    if (req.isEmpty || req == 'none' || req == 'unrestricted') return true;

    if (req.contains('tobacco')) {
      return approved && tobaccoLicense != null && tobaccoLicense!.trim().isNotEmpty;
    }

    if (req.contains('seller')) {
      return approved && sellerPermit != null && sellerPermit!.trim().isNotEmpty;
    }

    return approved;
  }
}

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  AppShop? _shop;

  AppShop? get shop => _shop;
  bool get isLoggedIn => _shop != null;

  /// Check if currently active shop has the required license for a product/category.
  bool hasLicenseFor(String? requiredLicense) {
    if (requiredLicense == null) return true;
    final req = requiredLicense.trim().toLowerCase();
    if (req.isEmpty || req == 'none' || req == 'unrestricted') return true;
    if (_shop == null) return false;
    return _shop!.hasLicenseFor(requiredLicense);
  }

  // Computed virtual AppUser derived from the Shop credentials to maintain backward compatibility in UI screens
  AppUser? get user => _shop != null ? AppUser(id: _shop!.id, name: _shop!.ownerName, email: _shop!.email) : null;

  /// Called after successful login or on app resume from prefs.
  void setSession(AppShop shop) {
    _shop = shop;
    notifyListeners();
  }

  void setShop(AppShop shop) {
    _shop = shop;
    notifyListeners();
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_shop != null) {
      prefs.setInt('shop_id', _shop!.id);
      prefs.setString('shop_name', _shop!.shopName);
      prefs.setString('shop_owner', _shop!.ownerName);
      prefs.setString('shop_email', _shop!.email);
      prefs.setString('shop_contact', _shop!.contactDetails);
      prefs.setString('shop_address', _shop!.address);
      prefs.setString('shop_city', _shop!.city);
      prefs.setString('shop_state', _shop!.state);
      prefs.setString('shop_zip', _shop!.zip);
      prefs.setString('shop_approval_status', _shop!.approvalStatus);
      prefs.setBool('shop_approved', _shop!.approved);
      if (_shop!.sellerPermit != null) prefs.setString('shop_seller_permit', _shop!.sellerPermit!);
      if (_shop!.tobaccoLicense != null) prefs.setString('shop_tobacco_license', _shop!.tobaccoLicense!);
    }
  }

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shop_id');
    if (shopId == null) return false;

    _shop = AppShop(
      id: shopId,
      shopName: prefs.getString('shop_name') ?? '',
      ownerName: prefs.getString('shop_owner') ?? '',
      email: prefs.getString('shop_email') ?? '',
      contactDetails: prefs.getString('shop_contact') ?? '',
      address: prefs.getString('shop_address') ?? '',
      city: prefs.getString('shop_city') ?? '',
      state: prefs.getString('shop_state') ?? '',
      zip: prefs.getString('shop_zip') ?? '',
      approvalStatus: prefs.getString('shop_approval_status') ?? 'Pending',
      approved: prefs.getBool('shop_approved') ?? false,
      sellerPermit: prefs.getString('shop_seller_permit'),
      tobaccoLicense: prefs.getString('shop_tobacco_license'),
    );

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _shop = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
