import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/order.dart';
import '../../core/services/api_client.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loadingInvoice = false;
  String? _pdfUrl;
  int? _invoiceId;
  DateTime? _invoiceDate;
  DateTime? _invoiceUpdatedAt;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    setState(() {
      _loadingInvoice = true;
    });
    try {
      final res = await ApiClient.instance.get('/invoices/${widget.order.id}');
      if (res['success'] == true && res['data']?['invoice'] != null) {
        final inv = res['data']['invoice'] as Map<String, dynamic>;
        setState(() {
          _pdfUrl = inv['pdf_url'] as String?;
          _invoiceId = inv['id'] as int?;
          _invoiceDate = inv['generated_at'] != null
              ? DateTime.tryParse(inv['generated_at'] as String)
              : null;
          _invoiceUpdatedAt = inv['updatedAt'] != null
              ? DateTime.tryParse(inv['updatedAt'] as String)
              : (inv['updated_at'] != null
                  ? DateTime.tryParse(inv['updated_at'] as String)
                  : null);
        });
      }
    } catch (_) {
      // Invoice may not exist yet — that's fine
    } finally {
      setState(() {
        _loadingInvoice = false;
      });
    }
  }

  Future<void> _openInvoice() async {
    if (_pdfUrl == null) return;
    final url = Uri.parse(_pdfUrl!);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open invoice: $e')),
        );
      }
    }
  }

  String _fmtDateTime(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $h:$m ${d.hour < 12 ? "AM" : "PM"}';
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _fmtAmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$integerPart.${parts[1]}';
  }

  String _statusLabel(OrderStatus s) => switch (s) {
    OrderStatus.pending => 'Awaiting Review',
    OrderStatus.approved => 'Quantities Approved',
    OrderStatus.dispatched => 'Order Dispatched',
    OrderStatus.delivered => 'Order Delivered',
  };

  Color _statusColor(OrderStatus s) => switch (s) {
    OrderStatus.pending => AppColors.statusPending,
    OrderStatus.approved => AppColors.statusApproved,
    OrderStatus.dispatched => AppColors.statusDispatched,
    OrderStatus.delivered => AppColors.statusDelivered,
  };

  int get _stepsDone => switch (widget.order.status) {
    OrderStatus.pending => 1,
    OrderStatus.approved => 2,
    OrderStatus.dispatched => 3,
    OrderStatus.delivered => 4,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Order Details')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeline(),
                  const Divider(height: 1),
                  _buildInvoiceCard(context),
                  _buildItemsSummaryCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context) {
    final bool hasInvoice = _pdfUrl != null && _pdfUrl!.isNotEmpty;
    final bool invoiceGenerated = _invoiceId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Invoice',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Invoice Status Badge
                if (!_loadingInvoice)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: invoiceGenerated
                          ? AppColors.greenLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: invoiceGenerated
                            ? AppColors.green
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      invoiceGenerated ? 'Generated' : 'Not Generated',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: invoiceGenerated
                            ? AppColors.green
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (_loadingInvoice)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else if (invoiceGenerated) ...[
              // Invoice Number
              _invoiceInfoRow(
                'Invoice No.',
                'INV-$_invoiceId',
              ),
              const SizedBox(height: 8),
              // Invoice Date
              if (_invoiceDate != null)
                _invoiceInfoRow(
                  'Invoice Date',
                  _fmtDate(_invoiceDate!),
                ),
              if (_invoiceDate != null) const SizedBox(height: 8),
              // Last Updated
              if (_invoiceUpdatedAt != null)
                _invoiceInfoRow(
                  'Last Updated',
                  _fmtDate(_invoiceUpdatedAt!),
                ),
              const SizedBox(height: 16),
              // View Invoice button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: hasInvoice ? _openInvoice : null,
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: Text(
                    'View Invoice',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Invoice not available yet.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: Text(
                    'View Invoice',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _invoiceInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSummaryCard(BuildContext context) {
    final previewText = widget.order.items.isNotEmpty
        ? widget.order.items.length == 1
              ? widget.order.items[0].name
              : '${widget.order.items[0].name} & ${widget.order.items.length - 1} other item(s)'
        : 'No items';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Items Summary',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              previewText,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _showItemsBottomSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View Items & Price Summary',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final isPending = widget.order.status == OrderStatus.pending;
        final requestedTotal = widget.order.items.fold<double>(
          0,
          (sum, item) => sum + (item.price * item.requestedQty),
        );
        final approvedTotal = widget.order.items.fold<double>(
          0,
          (sum, item) => sum + (item.activePrice * (item.approvedQty ?? item.requestedQty)),
        );
        final qtyMultiplier = (OrderItemDetail item) => item.approvedQty ?? item.requestedQty;
        final originalApprovedSubtotal = widget.order.items.fold<double>(
          0,
          (sum, item) => sum + (item.price * qtyMultiplier(item)),
        );
        final totalDiscount = widget.order.items.fold<double>(
          0,
          (sum, item) => sum + ((item.price - item.activePrice) * qtyMultiplier(item)),
        );

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Items',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.order.items.length,
                    itemBuilder: (_, idx) {
                      final item = widget.order.items[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        item.customPrice != null
                                            ? '\$${_fmtAmt(item.customPrice!)} each (Custom)'
                                            : '\$${_fmtAmt(item.price)} each',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${_fmtAmt(item.total)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _qtyChip(
                                  'REQUESTED',
                                  item.requestedQty.toString(),
                                  AppColors.surface,
                                  AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                if (item.approvedQty != null)
                                  _qtyChip(
                                    'APPROVED',
                                    item.approvedQty.toString(),
                                    AppColors.greenLight,
                                    AppColors.green,
                                  )
                                else
                                  _qtyChip(
                                    'APPROVED',
                                    '—',
                                    AppColors.orangeLight,
                                    AppColors.orange,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (!isPending) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Previous Amount (Requested)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '\$${_fmtAmt(requestedTotal)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (totalDiscount > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Original Approved Subtotal',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '\$${_fmtAmt(originalApprovedSubtotal)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Discount',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '-\$${_fmtAmt(totalDiscount)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'New Updated Amount (Approved)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '\$${_fmtAmt(approvedTotal)}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Total',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '\$${_fmtAmt(requestedTotal)}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.order.displayId,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(
                    widget.order.status,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(widget.order.status),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(widget.order.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.order.itemCount} items',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Placed on ${_fmtDate(widget.order.placedAt)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      ('Order Placed', widget.order.placedAt),
      ('Quantities Approved', widget.order.approvedAt),
      ('Order Dispatched', widget.order.dispatchedAt),
      ('Order Delivered', widget.order.deliveredAt),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER TIMELINE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final idx = e.key;
            final (label, dt) = e.value;
            final done = idx < _stepsDone;
            final isLast = idx == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? AppColors.primary : Colors.transparent,
                        border: done
                            ? null
                            : Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: done
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: AppColors.white,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 36,
                        color: done ? AppColors.primary : AppColors.border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: done
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: done
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                        if (done && dt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _fmtDateTime(dt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ] else if (!done) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Pending',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                        if (!isLast) const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _qtyChip(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
