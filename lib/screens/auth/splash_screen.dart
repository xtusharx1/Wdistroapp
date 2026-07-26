import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../widgets/w_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    // If a session was restored in main(), go straight to the app
    if (AppState.instance.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const WLogo(size: 80),
              const SizedBox(height: 20),
              Text('W Distro',
                  style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Wholesale ordering, made simple',
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
              const Spacer(flex: 2),
              const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
