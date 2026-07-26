import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_state.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup/signup_screen.dart';
import 'screens/auth/request_submitted_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Restore saved session before showing UI
    await AppState.instance.restoreSession();
  } catch (e) {
    debugPrint("Session restore failed: $e");
  }
  runApp(const WDistroApp());
}

class WDistroApp extends StatelessWidget {
  const WDistroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'W Distro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/':                  (_) => const SplashScreen(),
        '/login':             (_) => const LoginScreen(),
        '/signup':            (_) => const SignupScreen(),
        '/request-submitted': (_) => const RequestSubmittedScreen(),
        '/main':              (_) => const MainShell(),
      },
    );
  }
}
