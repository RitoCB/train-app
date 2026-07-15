import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/onboarding/screens/sport_selection_screen.dart';
import '../../features/onboarding/screens/profile_setup_screen.dart';
import '../../features/onboarding/screens/profile_success_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/session/screens/session_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../constants/app_constants.dart';

// Rutas con nombre — úsalas siempre con AppRoutes.xxx
class AppRoutes {
  AppRoutes._();

  static const splash          = '/';
  static const welcome         = '/welcome';
  static const login           = '/login';
  static const register        = '/register';
  static const forgotPassword  = '/forgot-password';
  static const sportSelection  = '/onboarding/sport';
  static const profileSetup    = '/onboarding/profile';
  static const profileSuccess  = '/onboarding/success';
  static const dashboard       = '/dashboard';
  static const session         = '/session';
  static const history         = '/history';
  static const stats           = '/stats';
  static const settings        = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: [

    // ── Flujo de entrada ──────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (_, __) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (_, __) => const ForgotPasswordScreen(),
    ),

    // ── Onboarding ───────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.sportSelection,
      builder: (_, __) => const SportSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      builder: (context, state) {
        final sport = state.uri.queryParameters['sport'] ??
            AppConstants.sportGym;
        return ProfileSetupScreen(sport: sport);
      },
    ),
    GoRoute(
      path: AppRoutes.profileSuccess,
      builder: (_, __) => const ProfileSuccessScreen(),
    ),

    // ── App principal (ShellRoute para bottom nav) ────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.history,
          builder: (_, __) => const HistoryScreen(),
        ),
        GoRoute(
          path: AppRoutes.stats,
          builder: (_, __) => const StatsScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    ),

    // ── Sesión activa (pantalla completa sin nav) ─────────────────
    GoRoute(
      path: AppRoutes.session,
      builder: (_, __) => const SessionScreen(),
    ),
  ],
);

// Shell con bottom navigation bar
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    AppRoutes.dashboard,
    AppRoutes.history,
    AppRoutes.stats,
    AppRoutes.settings,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexOf(location);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
