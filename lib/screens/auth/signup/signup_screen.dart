import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_client.dart';
import '../../../widgets/step_indicator.dart';
import 'step_basic.dart';
import 'step_business.dart';
import 'step_account.dart';
import 'step_review.dart';

class SignupData {
  String shopName = '';
  String ownerName = '';
  String email = '';
  String phone = '';
  String address = '';
  String city = '';
  String state = '';
  String zip = '';
  String sellerPermit = '';
  String tobaccoLicense = '';
  String password = '';
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 0;
  final _data = SignupData();
  bool _submitting = false;
  String? _error;

  final _stepLabels = ['Basic', 'Business', 'Account', 'Review'];

  void _next() => setState(() => _step = (_step + 1).clamp(0, 3));
  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step = _step - 1);
    }
  }

  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });
    try {
      // Create standalone Shop directly via single API call
      await AuthService.instance.registerShop(
        ownerName: _data.ownerName,
        email: _data.email,
        password: _data.password,
        shopName: _data.shopName,
        sellerPermit: _data.sellerPermit,
        tobaccoLicense: _data.tobaccoLicense.isNotEmpty ? _data.tobaccoLicense : null,
        phone: _data.phone,
        address: _data.address,
        city: _data.city,
        state: _data.state,
        zip: _data.zip,
      );

      if (mounted) Navigator.pushReplacementNamed(context, '/request-submitted');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to connect. Check your internet.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        title: const Text('Create Account'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: StepIndicator(currentStep: _step + 1, totalSteps: 4)),
                    const SizedBox(width: 10),
                    Text(_stepLabels[_step],
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Step ${_step + 1} of 4',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.red))),
                ]),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                StepBasic(data: _data, onNext: _next, onCancel: () => Navigator.pop(context)),
                StepBusiness(data: _data, onNext: _next, onBack: _back),
                StepAccount(data: _data, onNext: _next, onBack: _back),
                StepReview(
                  data: _data,
                  onSubmit: _submitting ? () {} : _submit,
                  onBack: _back,
                  onEdit: (s) => setState(() => _step = s),
                  submitting: _submitting,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
