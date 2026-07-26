import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'signup_screen.dart';

class StepBasic extends StatefulWidget {
  final SignupData data;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const StepBasic({super.key, required this.data, required this.onNext, required this.onCancel});

  @override
  State<StepBasic> createState() => _StepBasicState();
}

class _StepBasicState extends State<StepBasic> {
  late final _shopCtrl = TextEditingController(text: widget.data.shopName);
  late final _ownerCtrl = TextEditingController(text: widget.data.ownerName);
  late final _emailCtrl = TextEditingController(text: widget.data.email);
  late final _phoneCtrl = TextEditingController(text: widget.data.phone);

  @override
  void dispose() {
    _shopCtrl.dispose(); _ownerCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  void _next() {
    widget.data.shopName = _shopCtrl.text;
    widget.data.ownerName = _ownerCtrl.text;
    widget.data.email = _emailCtrl.text;
    widget.data.phone = _phoneCtrl.text;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic information',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text("Let's start with your shop and contact details.",
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.mail_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Email address will be used for login',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _label('Business / Shop name'),
          _field(_shopCtrl, Icons.store_outlined),
          const SizedBox(height: 16),
          _label('Owner name'),
          _field(_ownerCtrl, Icons.person_outline),
          const SizedBox(height: 16),
          _label('Email address'),
          _field(_emailCtrl, Icons.mail_outline, type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _label('Phone number'),
          _field(_phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(onPressed: _next, child: const Text('Next')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
  );

  Widget _field(TextEditingController ctrl, IconData icon, {TextInputType? type}) => TextFormField(
    controller: ctrl,
    keyboardType: type,
    decoration: InputDecoration(prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary)),
  );
}
