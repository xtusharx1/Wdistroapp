import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/models/order.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      OrderStatus.pending   => ('Pending',        AppColors.statusPending,    AppColors.statusPendingBg),
      OrderStatus.approved  => ('Approved',       AppColors.statusApproved,   AppColors.statusApprovedBg),
      OrderStatus.dispatched => ('Dispatched',    AppColors.statusDispatched, AppColors.statusDispatchedBg),
      OrderStatus.delivered  => ('Delivered',     AppColors.statusDelivered,  AppColors.statusDeliveredBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
