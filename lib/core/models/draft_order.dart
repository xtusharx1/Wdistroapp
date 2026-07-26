class DraftOrderItem {
  final int id;
  final int draftOrderId;
  final int productId;
  final String productName;
  final double priceAtSave;
  final double? customPrice;
  int quantity;
  final String? imageUrl;
  final int stock;
  final bool isClearance;
  final double? clearancePrice;
  final int? productCollectionId;
  final double? dealPrice;
  final String? collectionName;

  DraftOrderItem({
    required this.id,
    required this.draftOrderId,
    required this.productId,
    required this.productName,
    required this.priceAtSave,
    this.customPrice,
    required this.quantity,
    this.imageUrl,
    required this.stock,
    this.isClearance = false,
    this.clearancePrice,
    this.productCollectionId,
    this.dealPrice,
    this.collectionName,
  });

  double get effectivePrice => customPrice ?? priceAtSave;
  double get subtotal => effectivePrice * quantity;

  factory DraftOrderItem.fromJson(Map<String, dynamic> j) {
    final product = j['Product'] as Map<String, dynamic>?;
    final collection = product?['ProductCollection'] as Map<String, dynamic>?;
    return DraftOrderItem(
      id: j['id'] as int,
      draftOrderId: j['draft_order_id'] as int,
      productId: j['product_id'] as int,
      productName: product?['name'] as String? ?? 'Product #${j['product_id']}',
      priceAtSave: (j['price_at_save'] as num).toDouble(),
      customPrice: j['custom_price'] != null ? (j['custom_price'] as num).toDouble() : null,
      quantity: j['quantity'] as int,
      imageUrl: product?['image_url'] as String?,
      stock: product?['stock_quantity'] as int? ?? 0,
      isClearance: product?['is_clearance'] as bool? ?? false,
      clearancePrice: product?['clearance_price'] != null
          ? (product!['clearance_price'] as num).toDouble()
          : null,
      productCollectionId: product?['product_collection_id'] as int?,
      dealPrice: product?['deal_price'] != null ? (product!['deal_price'] as num).toDouble() : null,
      collectionName: collection != null ? collection['name'] as String? : null,
    );
  }

  Map<String, dynamic> toSubmitJson() => {
    'product_id': productId,
    'quantity': quantity,
    if (customPrice != null) 'custom_price': customPrice,
  };

  DraftOrderItem copyWith({int? quantity}) => DraftOrderItem(
    id: id,
    draftOrderId: draftOrderId,
    productId: productId,
    productName: productName,
    priceAtSave: priceAtSave,
    customPrice: customPrice,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl,
    stock: stock,
    isClearance: isClearance,
    clearancePrice: clearancePrice,
    productCollectionId: productCollectionId,
    dealPrice: dealPrice,
    collectionName: collectionName,
  );
}

class DraftOrder {
  final int id;
  final int shopId;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DraftOrderItem> items;

  const DraftOrder({
    required this.id,
    required this.shopId,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  String get displayId => 'Draft #$id';
  int get itemCount => items.length;

  factory DraftOrder.fromJson(Map<String, dynamic> j) {
    final rawItems = (j['DraftOrderItems'] as List<dynamic>?) ?? [];
    final items = rawItems
        .map((e) => DraftOrderItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return DraftOrder(
      id: j['id'] as int,
      shopId: j['shop_id'] as int,
      totalAmount: (j['total_amount'] as num).toDouble(),
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(j['updated_at'] as String? ?? '') ?? DateTime.now(),
      items: items,
    );
  }
}
