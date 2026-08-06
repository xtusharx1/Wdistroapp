import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'cart_item.dart';
import 'product.dart';

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);
  double get delivery => 0;
  double get total => subtotal;

  void add(Product product) {
    if (!AppState.instance.hasLicenseFor(product.requiredLicense)) {
      throw 'License Required: You do not have the required license to add this product to cart.';
    }
    final existing = _items.where((i) => i.product.id == product.id);
    if (existing.isNotEmpty) {
      if (existing.first.quantity >= product.stock) {
        throw 'Requested quantity exceeds available stock.';
      }
      existing.first.quantity++;
    } else {
      if (product.stock <= 0) {
        throw 'Requested quantity exceeds available stock.';
      }
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void increment(int productId) {
    final item = _items.firstWhere((i) => i.product.id == productId);
    if (item.quantity >= item.product.stock) {
      throw 'Requested quantity exceeds available stock.';
    }
    item.quantity++;
    notifyListeners();
  }

  void decrement(int productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx == -1) return;
    if (_items[idx].quantity <= 1) {
      _items.removeAt(idx);
    } else {
      _items[idx].quantity--;
    }
    notifyListeners();
  }

  int getQty(int productId) {
    final match = _items.where((i) => i.product.id == productId);
    return match.isNotEmpty ? match.first.quantity : 0;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
