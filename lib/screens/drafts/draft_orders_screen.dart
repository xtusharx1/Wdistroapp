import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/draft_order.dart';
import '../../core/services/draft_order_service.dart';
import '../../core/models/cart_state.dart';
import '../../widgets/empty_state_widget.dart';
import 'draft_detail_screen.dart';

class DraftOrdersScreen extends StatefulWidget {
  final CartState cart;

  const DraftOrdersScreen({super.key, required this.cart});

  @override
  State<DraftOrdersScreen> createState() => _DraftOrdersScreenState();
}

class _DraftOrdersScreenState extends State<DraftOrdersScreen> {
  List<DraftOrder> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    try {
      final drafts = await DraftOrderService.instance.getDrafts();
      if (mounted) setState(() { _drafts = drafts; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _drafts = []; _loading = false; });
    }
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _fmtAmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$intPart.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Saved Drafts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadDrafts,
              child: _drafts.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.bookmark_border_outlined,
                      title: 'No saved drafts',
                      subtitle: 'Tap "Save as Draft" in your cart to build an order over time.',
                      buttonLabel: 'Go back',
                      onAction: () => Navigator.pop(context),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '${_drafts.length} saved draft${_drafts.length == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 24),
                            itemCount: _drafts.length,
                            itemBuilder: (_, i) => _DraftCard(
                              draft: _drafts[i],
                              fmtDate: _fmtDate,
                              fmtAmount: _fmtAmt,
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => DraftDetailScreen(
                                    draftId: _drafts[i].id,
                                    cart: widget.cart,
                                  ),
                                ));
                                _loadDrafts();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  final DraftOrder draft;
  final String Function(DateTime) fmtDate;
  final String Function(double) fmtAmount;
  final VoidCallback onTap;

  const _DraftCard({
    required this.draft,
    required this.fmtDate,
    required this.fmtAmount,
    required this.onTap,
  });

  String get _previewText {
    if (draft.items.isEmpty) return 'Empty draft';
    if (draft.items.length == 1) return draft.items[0].productName;
    return '${draft.items[0].productName} & ${draft.items.length - 1} other item${draft.items.length > 2 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bookmark_outlined, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.displayId,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _previewText,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Saved ${fmtDate(draft.updatedAt)}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Draft',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${draft.itemCount} item${draft.itemCount == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Row(
                    children: [
                      Text(
                        '\$${fmtAmount(draft.totalAmount)}',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
