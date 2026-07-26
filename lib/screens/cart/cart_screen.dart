import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/cart_state.dart';
import '../../core/services/order_service.dart';
import '../../core/services/draft_order_service.dart';
import '../../core/services/api_client.dart';
import '../../core/state/app_state.dart';
import '../../widgets/product_image_placeholder.dart';
import '../../widgets/empty_state_widget.dart';
import 'order_success_screen.dart';

class CartScreen extends StatefulWidget {
  final CartState cart;

  const CartScreen({super.key, required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placing = false;
  bool _savingDraft = false;
  String? _error;

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$integerPart.${parts[1]}';
  }

  Future<void> _saveAsDraft() async {
    final shop = AppState.instance.shop;
    if (shop == null) {
      setState(() => _error = 'No shop associated with your account.');
      return;
    }

    setState(() { _savingDraft = true; _error = null; });

    try {
      await DraftOrderService.instance.createDraft(widget.cart.items.toList());
      if (mounted) {
        setState(() => _savingDraft = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft saved! Find it in Profile → Saved Drafts.',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _savingDraft = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _savingDraft = false; _error = 'Failed to save draft. Please try again.'; });
    }
  }

  Future<void> _placeOrder() async {
    final shop = AppState.instance.shop;
    if (shop == null) {
      setState(() => _error = 'No shop associated with your account. Please contact admin.');
      return;
    }

    setState(() { _placing = true; _error = null; });

    for (final item in widget.cart.items) {
      if (item.quantity > item.product.stock) {
        setState(() {
          _error = 'Requested quantity exceeds available stock.';
          _placing = false;
        });
        return;
      }
    }

    try {
      final order = await OrderService.instance.createOrder(
        shopId: shop.id,
        items: widget.cart.items.toList(),
      );
      widget.cart.clear();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: order.displayId),
        ));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to place order. Please try again.');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: widget.cart,
          builder: (_, __) => Text('Cart (${widget.cart.itemCount})'),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.cart,
        builder: (context, _) {
          if (widget.cart.items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Browse products and add items to place an order.',
              buttonLabel: 'Browse products',
              onAction: () => Navigator.pop(context),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: widget.cart.items.length,
                  itemBuilder: (_, i) {
                    final item = widget.cart.items[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ProductImagePlaceholder(
                              label: item.product.imageLabel,
                              height: 64,
                              width: 64,
                              imageUrl: item.product.imageUrl,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name,
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                if (item.product.dealPrice != null || (item.product.isClearance && item.product.clearancePrice != null)) ...[
                                  Text('\$${_fmt(item.product.price)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        decoration: TextDecoration.lineThrough,
                                      )),
                                  Text('\$${_fmt(item.product.dealPrice ?? item.product.clearancePrice!)}',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEA580C))),
                                ] else
                                  Text('\$${_fmt(item.product.price)}',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              _qtyBtn(Icons.remove, () {
                                widget.cart.decrement(item.product.id);
                                setState(() { _error = null; });
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('${item.quantity}',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              ),
                              _qtyBtn(Icons.add, () {
                                try {
                                  widget.cart.increment(item.product.id);
                                  setState(() { _error = null; });
                                } catch (e) {
                                  setState(() { _error = e.toString(); });
                                }
                              }),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Text('\$${_fmt(item.subtotal)}',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                                color: (item.product.dealPrice != null || item.product.isClearance) ? const Color(0xFFEA580C) : AppColors.textPrimary)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildSummary(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(
        children: [
          _row('Total', '\$${_fmt(widget.cart.total)}', bold: true),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.red), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_placing || _savingDraft) ? null : _placeOrder,
            child: _placing
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : Text('Place order  ·  \$${_fmt(widget.cart.total)}',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: (_placing || _savingDraft) ? null : _saveAsDraft,
              icon: _savingDraft
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.bookmark_border_outlined, size: 18, color: AppColors.primary),
              label: Text(
                _savingDraft ? 'Saving draft…' : 'Save as Draft',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold
        ? GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)
        : GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
