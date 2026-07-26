import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/draft_order.dart';
import '../../core/models/cart_state.dart';
import '../../core/services/draft_order_service.dart';
import '../../core/services/api_client.dart';
import '../../widgets/product_image_placeholder.dart';
import '../cart/order_success_screen.dart';

class DraftDetailScreen extends StatefulWidget {
  final int draftId;
  final CartState cart;

  const DraftDetailScreen({super.key, required this.draftId, required this.cart});

  @override
  State<DraftDetailScreen> createState() => _DraftDetailScreenState();
}

class _DraftDetailScreenState extends State<DraftDetailScreen> {
  DraftOrder? _draft;
  List<DraftOrderItem> _items = [];
  bool _loading = true;
  bool _saving = false;
  bool _submitting = false;
  bool _isDirty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    try {
      final draft = await DraftOrderService.instance.getDraft(widget.draftId);
      if (mounted) {
        setState(() {
          _draft = draft;
          _items = draft.items.map((i) => i.copyWith()).toList();
          _loading = false;
          _isDirty = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Failed to load draft'; });
    }
  }

  double get _draftTotal => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  void _increment(int index) {
    final item = _items[index];
    if (item.quantity >= item.stock) {
      setState(() => _error = 'Requested quantity exceeds available stock for ${item.productName}');
      return;
    }
    setState(() {
      _items[index] = item.copyWith(quantity: item.quantity + 1);
      _isDirty = true;
      _error = null;
    });
  }

  void _decrement(int index) {
    final item = _items[index];
    if (item.quantity <= 1) {
      _removeItem(index);
      return;
    }
    setState(() {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
      _isDirty = true;
      _error = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _isDirty = true;
      _error = null;
    });
  }

  Future<void> _saveDraft() async {
    if (_items.isEmpty) {
      setState(() => _error = 'Draft must have at least one item');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final updated = await DraftOrderService.instance.updateDraft(widget.draftId, _items);
      if (mounted) {
        setState(() {
          _draft = updated;
          _items = updated.items.map((i) => i.copyWith()).toList();
          _saving = false;
          _isDirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.green),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _saving = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Failed to save draft'; });
    }
  }

  Future<void> _submitDraft() async {
    if (_items.isEmpty) {
      setState(() => _error = 'Draft must have at least one item');
      return;
    }

    setState(() { _submitting = true; _error = null; });

    try {
      // Save any unsaved changes first
      if (_isDirty) {
        await DraftOrderService.instance.updateDraft(widget.draftId, _items);
      }

      final orderData = await DraftOrderService.instance.submitDraft(widget.draftId);
      final displayId = orderData['displayId'] as String? ?? 'WS-${orderData['id']}';

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: displayId),
        ));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _submitting = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _submitting = false; _error = 'Failed to submit draft'; });
    }
  }

  Future<void> _deleteDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text('Delete Draft', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text('Are you sure you want to delete this draft? This cannot be undone.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DraftOrderService.instance.deleteDraft(widget.draftId);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete draft'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$intPart.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null && _draft == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(title: const Text('Draft Order')),
        body: Center(child: Text(_error!, style: GoogleFonts.inter(color: AppColors.red))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(_draft?.displayId ?? 'Draft Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red),
            onPressed: _submitting || _saving ? null : _deleteDraft,
            tooltip: 'Delete draft',
          ),
        ],
      ),
      body: Column(
        children: [
          // Draft notice banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryLight,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a draft. No inventory is reserved until you submit.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('No items in draft',
                            style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text('All items were removed.',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.divider)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ProductImagePlaceholder(
                                label: item.productName.split(' ').first.toUpperCase(),
                                height: 56,
                                width: 56,
                                imageUrl: item.imageUrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\$${_fmt(item.effectivePrice)} each',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  if (item.stock < 10 && item.stock > 0)
                                    Text(
                                      '${item.stock} in stock',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.orange),
                                    ),
                                  if (item.stock == 0)
                                    Text(
                                      'Out of stock',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.red, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                _qtyBtn(Icons.remove, () => _decrement(i)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('${item.quantity}',
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                ),
                                _qtyBtn(Icons.add, () => _increment(i)),
                              ],
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _removeItem(i),
                              child: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Draft Total',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('\$${_fmt(_draftTotal)}',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.red), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          if (_isDirty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _saving || _submitting ? null : _saveDraft,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : Text('Save Changes',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_submitting || _saving || _items.isEmpty) ? null : _submitDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                  : Text(
                      'Submit Order  ·  \$${_fmt(_draftTotal)}',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
