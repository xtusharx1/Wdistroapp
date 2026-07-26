class Product {
  final int id;
  final String name;
  final String category;
  final String mainCategory;
  final String subCategory;
  final String requiredLicense;
  final double price;
  final int stock;
  final String imageLabel;
  final String? imageUrl;
  final String? description;
  final bool isClearance;
  final double? clearancePrice;
  final bool isFeatured;
  final int? featuredOrder;
  final List<Product>? variations;
  final int? variationGroupId;
  final int? productCollectionId;
  final double? dealPrice;
  final String? collectionName;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.mainCategory,
    required this.subCategory,
    required this.requiredLicense,
    required this.price,
    required this.stock,
    required this.imageLabel,
    this.imageUrl,
    this.description,
    this.isClearance = false,
    this.clearancePrice,
    this.isFeatured = false,
    this.featuredOrder,
    this.variations,
    this.variationGroupId,
    this.productCollectionId,
    this.dealPrice,
    this.collectionName,
  });

  /// The price to use everywhere (cart, checkout, display).
  /// Returns dealPrice if present, otherwise clearancePrice, otherwise the regular price.
  double get effectivePrice => dealPrice ?? ((isClearance && clearancePrice != null) ? clearancePrice! : price);

  factory Product.fromJson(Map<String, dynamic> j) {
    final name = j['name'] as String? ?? '';
    final cat = j['category'] as String? ?? 'General';
    final isClearance = j['is_clearance'] as bool? ?? false;
    final collection = j['ProductCollection'] as Map<String, dynamic>?;
    return Product(
      id: j['id'] as int,
      name: name,
      category: cat,
      mainCategory: j['main_category'] as String? ?? j['mainCategory'] as String? ?? cat,
      subCategory: j['sub_category'] as String? ?? j['subCategory'] as String? ?? cat,
      requiredLicense: j['required_license'] as String? ?? j['requiredLicense'] as String? ?? 'Seller Permit',
      price: (j['price'] as num).toDouble(),
      stock: j['stock_quantity'] as int? ?? 0,
      imageLabel: _labelFromName(name),
      imageUrl: j['image_url'] as String?,
      description: j['description'] as String?,
      isClearance: isClearance,
      clearancePrice: isClearance && j['clearance_price'] != null
          ? (j['clearance_price'] as num).toDouble()
          : null,
      isFeatured: j['is_featured'] as bool? ?? false,
      featuredOrder: j['featured_order'] as int?,
      variationGroupId: j['variation_group_id'] as int?,
      variations: (j['variations'] as List<dynamic>?)
          ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      productCollectionId: j['product_collection_id'] as int?,
      dealPrice: j['deal_price'] != null ? (j['deal_price'] as num).toDouble() : null,
      collectionName: collection != null ? collection['name'] as String? : null,
    );
  }

  static String _labelFromName(String name) {
    final words = name.split(' ');
    return words.isNotEmpty ? words.first.toUpperCase() : 'ITEM';
  }

  static const List<Product> sampleProducts = [];
}
