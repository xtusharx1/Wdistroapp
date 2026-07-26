class ShopPermit {
  final int id;
  final int shopId;
  final String permitType;
  final String documentUrl;
  final String originalFileName;
  final int uploadedBy;
  final DateTime uploadedAt;
  final String status; // Pending | Approved | Rejected
  final String? remarks;
  final DateTime createdAt;

  const ShopPermit({
    required this.id,
    required this.shopId,
    required this.permitType,
    required this.documentUrl,
    required this.originalFileName,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.status,
    this.remarks,
    required this.createdAt,
  });

  factory ShopPermit.fromJson(Map<String, dynamic> j) => ShopPermit(
        id: j['id'] as int,
        shopId: j['shop_id'] as int,
        permitType: j['permit_type'] as String,
        documentUrl: j['document_url'] as String,
        originalFileName: j['original_file_name'] as String,
        uploadedBy: j['uploaded_by'] as int,
        uploadedAt: DateTime.parse(j['uploaded_at'] as String),
        status: j['status'] as String,
        remarks: j['remarks'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
