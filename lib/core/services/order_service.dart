import 'api_client.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderService {
  static final OrderService instance = OrderService._();
  OrderService._();

  Future<List<Order>> getOrders({int? shopId}) async {
    var path = '/orders';
    if (shopId != null) path += '?shop_id=$shopId';

    final res = await ApiClient.instance.get(path);
    final list = res['data']['orders'] as List<dynamic>;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> getOrder(int id) async {
    final res = await ApiClient.instance.get('/orders/$id');
    return Order.fromJson(res['data']['order'] as Map<String, dynamic>);
  }

  Future<Order> createOrder({
    required int shopId,
    required List<CartItem> items,
  }) async {
    final total = items.fold(0.0, (sum, i) => sum + i.subtotal);
    final body = {
      'shop_id': shopId,
      'total_amount': total,
      'items': items.map((i) => {
        'product_id': i.product.id,
        'requested_qty': i.quantity,
        'price': i.product.effectivePrice,
      }).toList(),
    };

    final res = await ApiClient.instance.post('/orders', body);
    return Order.fromJson(res['data']['order'] as Map<String, dynamic>);
  }
}
