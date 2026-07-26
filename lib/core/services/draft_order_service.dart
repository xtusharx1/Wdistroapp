import 'api_client.dart';
import '../models/draft_order.dart';
import '../models/cart_item.dart';

class DraftOrderService {
  static final DraftOrderService instance = DraftOrderService._();
  DraftOrderService._();

  Future<DraftOrder> createDraft(List<CartItem> items) async {
    final body = {
      'items': items.map((i) => {
        'product_id': i.product.id,
        'quantity': i.quantity,
      }).toList(),
    };
    final res = await ApiClient.instance.post('/drafts', body);
    return DraftOrder.fromJson(res['data']['draft'] as Map<String, dynamic>);
  }

  Future<List<DraftOrder>> getDrafts() async {
    final res = await ApiClient.instance.get('/drafts');
    final list = res['data']['drafts'] as List<dynamic>;
    return list.map((e) => DraftOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DraftOrder> getDraft(int id) async {
    final res = await ApiClient.instance.get('/drafts/$id');
    return DraftOrder.fromJson(res['data']['draft'] as Map<String, dynamic>);
  }

  Future<DraftOrder> updateDraft(int id, List<DraftOrderItem> items) async {
    final body = {
      'items': items.map((i) => i.toSubmitJson()).toList(),
    };
    final res = await ApiClient.instance.put('/drafts/$id', body);
    return DraftOrder.fromJson(res['data']['draft'] as Map<String, dynamic>);
  }

  Future<void> deleteDraft(int id) async {
    await ApiClient.instance.delete('/drafts/$id');
  }

  Future<Map<String, dynamic>> submitDraft(int id) async {
    final res = await ApiClient.instance.post('/drafts/$id/submit', {});
    return res['data']['order'] as Map<String, dynamic>;
  }
}
