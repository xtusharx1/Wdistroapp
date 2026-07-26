import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'signup_screen.dart';

class StepReview extends StatelessWidget {
  final SignupData data;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final void Function(int step) onEdit;
  final bool submitting;

  const StepReview({
    super.key,
    required this.data,
    required this.onSubmit,
    required this.onBack,
    required this.onEdit,
    this.submitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review your details',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Confirm everything looks right before submitting.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _section('Basic information', onEdit: () => onEdit(0), rows: [
            ('Business', data.shopName.isEmpty ? '—' : data.shopName),
            ('Owner', data.ownerName.isEmpty ? '—' : data.ownerName),
            ('Email', data.email.isEmpty ? '—' : data.email),
            ('Phone', data.phone.isEmpty ? '—' : data.phone),
          ]),
          const SizedBox(height: 16),
          _section('Business details', onEdit: () => onEdit(1), rows: [
            ('Address', data.address.isEmpty ? '—' : data.address),
            ('City, State, ZIP', '${data.city}, ${data.state} – ${data.zip}'),
            ('Seller Permit', data.sellerPermit.isEmpty ? '—' : data.sellerPermit),
            ('Tobacco License', data.tobaccoLicense.isEmpty ? 'Not Provided' : data.tobaccoLicense),
          ]),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Text('Request Access'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onBack, child: const Text('Back')),
          const SizedBox(height: 12),
          Center(
            child: Text('Your account will be reviewed by admin before approval.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, {required VoidCallback onEdit, required List<(String, String)> rows}) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: onEdit,
                  child: Row(children: [
                    const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text('Edit', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rows.map((row) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                SizedBox(width: 90,
                    child: Text(row.$1, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))),
                Expanded(
                  child: Text(row.$2,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
