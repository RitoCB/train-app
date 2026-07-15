import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeLogo, _fadeTagline, _scaleLogo;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _fadeLogo    = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _scaleLogo   = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)));
    _fadeTagline = CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    final box     = Hive.box(AppConstants.boxSettings);
    final onboardingDone = box.get(AppConstants.keyOnboardingDone, defaultValue: false) as bool;

    if (session != null && onboardingDone) {
      context.go(AppRoutes.dashboard);
    } else if (session != null && !onboardingDone) {
      context.go(AppRoutes.sportSelection);
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(scale: _scaleLogo,
            child: FadeTransition(opacity: _fadeLogo,
              child: Container(width: 88, height: 88,
                decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(24)),
                child: const Center(child: Text('⚡', style: TextStyle(fontSize: 40)))))),
          const SizedBox(height: 20),
          FadeTransition(opacity: _fadeLogo,
            child: const Text('TrainApp', style: TextStyle(
                fontFamily: 'SpaceGrotesk', fontSize: 30, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, letterSpacing: -0.5))),
          const SizedBox(height: 8),
          FadeTransition(opacity: _fadeTagline,
            child: const Text('Entrena. Mide. Supérate.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted, letterSpacing: 0.2))),
          const SizedBox(height: 64),
          FadeTransition(opacity: _fadeTagline,
            child: const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green))),
        ]),
      ),
    );
  }
}
