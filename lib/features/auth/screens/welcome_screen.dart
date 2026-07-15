import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Bienvenido a TrainApp',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Registra tus entrenamientos,\nsigue tu progreso y alcanza tus objetivos.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Feature pills
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeaturePill(icon: Icons.fitness_center, label: 'Gym', color: AppColors.green),
                  SizedBox(width: 10),
                  _FeaturePill(icon: Icons.directions_run, label: 'Running', color: AppColors.blue),
                  SizedBox(width: 10),
                  _FeaturePill(icon: Icons.sports_martial_arts, label: 'Marciales', color: AppColors.purple),
                ],
              ),

              const Spacer(flex: 3),

              // Botones
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text('Iniciar sesión'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.register),
                  child: const Text('Crear cuenta nueva'),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Al continuar aceptas nuestros Términos de uso',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
