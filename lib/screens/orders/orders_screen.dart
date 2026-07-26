import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/order.dart';
import '../../core/services/order_service.dart';
import '../../core/state/app_state.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/empty_state_widget.dart';
import 'order_detail_screen.dart';

import '../../core/models/cart_state.dart';
import '../products/product_list_screen.dart';

class OrdersScreen extends StatefulWidget {
  final CartState? cart;
  const OrdersScreen({super.key, this.cart});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final shopId = AppState.instance.shop?.id;
      final orders = await OrderService.instance.getOrders(shopId: shopId);
      if (mounted)
        setState(() {
          _orders = orders;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _orders = [];
          _loading = false;
        });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('My Orders')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                      subtitle:
                          'Once you place an order, you\'ll be able to track it here.',
                      buttonLabel: 'Start ordering',
                      onAction: () {
                        if (widget.cart != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductListScreen(cart: widget.cart!),
                            ),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            '${_orders.length} orders',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 6, bottom: 20),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) => _OrderCard(
                              order: _orders[i],
                              fmtDate: _fmtDate,
                              fmtAmount: _fmtAmt,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OrderDetailScreen(order: _orders[i]),
                                  ),
                                );
                                _loadOrders(); // Refresh on return
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

class _OrderCard extends StatelessWidget {
  final Order order;
  final String Function(DateTime) fmtDate;
  final String Function(double) fmtAmount;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.fmtDate,
    required this.fmtAmount,
    required this.onTap,
  });

  Color get _statusColor => switch (order.status) {
    OrderStatus.pending => AppColors.statusPending,
    OrderStatus.approved => AppColors.statusApproved,
    OrderStatus.dispatched => AppColors.statusDispatched,
    OrderStatus.delivered => AppColors.statusDelivered,
  };

  Color get _statusBg => switch (order.status) {
    OrderStatus.pending => AppColors.statusPendingBg,
    OrderStatus.approved => AppColors.statusApprovedBg,
    OrderStatus.dispatched => AppColors.statusDispatchedBg,
    OrderStatus.delivered => AppColors.statusDeliveredBg,
  };

  String get _statusLabel => switch (order.status) {
    OrderStatus.pending => 'Pending',
    OrderStatus.approved => 'Approved',
    OrderStatus.dispatched => 'Dispatched',
    OrderStatus.delivered => 'Delivered',
  };

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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.displayId,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fmtDate(order.placedAt),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${fmtAmount(order.total)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
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
