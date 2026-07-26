class OrderItemDetail {
  final int? id;
  final String name;
  final double price;
  final double? customPrice;
  final int requestedQty;
  final int? approvedQty;

  const OrderItemDetail({
    this.id,
    required this.name,
    required this.price,
    this.customPrice,
    required this.requestedQty,
    this.approvedQty,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> j) {
    final product = j['Product'] as Map<String, dynamic>?;
    return OrderItemDetail(
      id: j['id'] as int?,
      name: product?['name'] as String? ?? 'Product #${j['product_id']}',
      price: (j['price'] as num).toDouble(),
      customPrice: j['custom_price'] != null ? (j['custom_price'] as num).toDouble() : null,
      requestedQty: j['requested_qty'] as int? ?? 0,
      approvedQty: j['approved_qty'] as int?,
    );
  }

  double get activePrice => customPrice ?? price;

  double get total => activePrice * (approvedQty ?? requestedQty);
}

enum OrderStatus { pending, approved, dispatched, delivered }

class Order {
  final int id;
  final String displayId;
  final int itemCount;
  final DateTime placedAt;
  final OrderStatus status;
  final double total;
  final List<OrderItemDetail> items;
  final DateTime? approvedAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;

  const Order({
    required this.id,
    required this.displayId,
    required this.itemCount,
    required this.placedAt,
    required this.status,
    required this.total,
    required this.items,
    this.approvedAt,
    this.dispatchedAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) {
    final rawItems = (j['OrderItems'] as List<dynamic>?) ?? [];
    final items = rawItems
        .map((e) => OrderItemDetail.fromJson(e as Map<String, dynamic>))
        .toList();

    return Order(
      id: j['id'] as int,
      displayId: 'WS-${j['id']}',
      itemCount: items.isNotEmpty
          ? items.length
          : (j['item_count'] as int? ?? 0),
      placedAt:
          DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      status: _parseStatus(j['status'] as String? ?? 'pending'),
      total: (j['total_amount'] as num).toDouble(),
      items: items,
      approvedAt: j['approved_at'] != null
          ? DateTime.tryParse(j['approved_at'] as String)
          : null,
      dispatchedAt: j['dispatched_at'] != null
          ? DateTime.tryParse(j['dispatched_at'] as String)
          : null,
      deliveredAt: j['delivered_at'] != null
          ? DateTime.tryParse(j['delivered_at'] as String)
          : null,
    );
  }

  static OrderStatus _parseStatus(String s) => switch (s) {
    'approved' => OrderStatus.approved,
    'dispatched' => OrderStatus.dispatched,
    'delivered' => OrderStatus.delivered,
    'processed' => OrderStatus.approved, // legacy backend value
    'completed' => OrderStatus.delivered, // legacy backend value
    _ => OrderStatus.pending,
  };

  static final List<Order> sampleOrders = [
    Order(
      id: 2841,
      displayId: 'WS-2841',
      itemCount: 2,
      placedAt: DateTime(2026, 5, 18, 10, 32),
      status: OrderStatus.pending,
      total: 12500,
      items: const [
        OrderItemDetail(
          name: 'Basmati Rice 25kg',
          price: 1850,
          requestedQty: 5,
        ),
        OrderItemDetail(name: 'Toor Dal 30kg', price: 4200, requestedQty: 1),
      ],
    ),
    Order(
      id: 2837,
      displayId: 'WS-2837',
      itemCount: 2,
      placedAt: DateTime(2026, 5, 14, 9, 18),
      status: OrderStatus.approved,
      total: 7790,
      approvedAt: DateTime(2026, 5, 14, 14, 45),
      items: const [
        OrderItemDetail(
          name: 'Sunflower Oil 15L',
          price: 1620,
          requestedQty: 3,
          approvedQty: 3,
        ),
        OrderItemDetail(
          name: 'Wheat Flour 50kg',
          price: 1450,
          requestedQty: 2,
          approvedQty: 2,
        ),
      ],
    ),
    Order(
      id: 2835,
      displayId: 'WS-2835',
      itemCount: 1,
      placedAt: DateTime(2026, 5, 12, 11, 20),
      status: OrderStatus.dispatched,
      total: 3240,
      approvedAt: DateTime(2026, 5, 12, 15, 30),
      dispatchedAt: DateTime(2026, 5, 13, 09, 15),
      items: const [
        OrderItemDetail(
          name: 'Sunflower Oil 15L',
          price: 1620,
          requestedQty: 2,
          approvedQty: 2,
        ),
      ],
    ),
    Order(
      id: 2830,
      displayId: 'WS-2830',
      itemCount: 2,
      placedAt: DateTime(2026, 5, 10, 08, 45),
      status: OrderStatus.delivered,
      total: 4750,
      approvedAt: DateTime(2026, 5, 10, 12, 10),
      dispatchedAt: DateTime(2026, 5, 11, 10, 00),
      deliveredAt: DateTime(2026, 5, 12, 16, 20),
      items: const [
        OrderItemDetail(
          name: 'Basmati Rice 25kg',
          price: 1850,
          requestedQty: 1,
          approvedQty: 1,
        ),
        OrderItemDetail(
          name: 'Wheat Flour 50kg',
          price: 1450,
          requestedQty: 2,
          approvedQty: 2,
        ),
      ],
    ),
  ];
}
