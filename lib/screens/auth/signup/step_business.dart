import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'signup_screen.dart';

class StepBusiness extends StatefulWidget {
  final SignupData data;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepBusiness({super.key, required this.data, required this.onNext, required this.onBack});

  @override
  State<StepBusiness> createState() => _StepBusinessState();
}

class _StepBusinessState extends State<StepBusiness> {
  late final _addrCtrl = TextEditingController(text: widget.data.address);
  late final _cityCtrl = TextEditingController(text: widget.data.city);
  late final _stateCtrl = TextEditingController(text: widget.data.state);
  late final _zipCtrl = TextEditingController(text: widget.data.zip);
  late final _permitCtrl = TextEditingController(text: widget.data.sellerPermit);
  late final _licenseCtrl = TextEditingController(text: widget.data.tobaccoLicense);

  @override
  void dispose() {
    _addrCtrl.dispose(); _cityCtrl.dispose(); _stateCtrl.dispose();
    _zipCtrl.dispose(); _permitCtrl.dispose(); _licenseCtrl.dispose();
    super.dispose();
  }

  void _next() {
    widget.data.address = _addrCtrl.text;
    widget.data.city = _cityCtrl.text;
    widget.data.state = _stateCtrl.text;
    widget.data.zip = _zipCtrl.text;
    widget.data.sellerPermit = _permitCtrl.text;
    widget.data.tobaccoLicense = _licenseCtrl.text;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business details',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Where your business is located and registered.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _label('Business address'),
          TextFormField(
            controller: _addrCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          _label('City'),
          TextFormField(controller: _cityCtrl),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('State'),
                TextFormField(controller: _stateCtrl),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('ZIP code'),
                TextFormField(controller: _zipCtrl, keyboardType: TextInputType.number),
              ])),
            ],
          ),
          const SizedBox(height: 16),
          _label('Seller Permit Number (Mandatory)'),
          TextFormField(
            controller: _permitCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.badge_outlined, size: 18, color: AppColors.textSecondary),
              hintText: 'Enter your seller permit number',
            ),
          ),
          const SizedBox(height: 16),
          _label('Tobacco License Number'),
          TextFormField(
            controller: _licenseCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.card_membership_outlined, size: 18, color: AppColors.textSecondary),
              hintText: 'Enter tobacco license number (optional)',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'If you are planning to purchase any tobacco products, please mention the tobacco license number from the state.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: widget.onBack, child: const Text('Back'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _next, child: const Text('Next'))),
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
}
