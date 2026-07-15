import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class ProfileSuccessScreen extends StatelessWidget {
  const ProfileSuccessScreen({super.key});

  String _sportLabel(String sport) => switch (sport) {
        AppConstants.sportGym      => 'Gym · Fuerza',
        AppConstants.sportMartial  => 'Artes Marciales',
        AppConstants.sportEndurance => 'Resistencia',
        _                          => 'Personalizado',
      };

  Future<void> _goToDashboard(BuildContext context) async {
    final box = Hive.box(AppConstants.boxSettings);
    await box.put(AppConstants.keyOnboardingDone, true);
    if (context.mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final box    = Hive.box(AppConstants.boxSettings);
    final sport  = box.get(AppConstants.keySportType, defaultValue: AppConstants.sportGym) as String;
    final name   = box.get('user_name',   defaultValue: '') as String;
    final weight = box.get('user_weight', defaultValue: 0.0);
    final freq   = box.get('frequency',   defaultValue: '4') as String;
    final level  = box.get('level',       defaultValue: 'intermediate') as String;

    final levelLabel = switch (level) {
      'beginner'    => 'Principiante',
      'advanced'    => 'Avanzado',
      _             => 'Intermedio',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const Spacer(),

              // Icono de éxito
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.greenDim,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.greenBorder, width: 0.5),
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.green, size: 38),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                name.isNotEmpty ? '¡Listo, $name!' : '¡Perfil creado con éxito!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Tu cuenta está lista. Hemos configurado tu perfil de ${_sportLabel(sport)}.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Resumen del perfil
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: _SummaryItem(label: 'Deporte', value: _sportLabel(sport))),
                      Expanded(child: _SummaryItem(label: 'Nivel', value: levelLabel)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _SummaryItem(label: 'Frecuencia', value: '$freq días / semana')),
                      Expanded(child: _SummaryItem(
                        label: 'Peso actual',
                        value: weight > 0 ? '$weight kg' : '—',
                      )),
                    ]),
                  ],
                ),
              ),

              const Spacer(),

              // Botón principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _goToDashboard(context),
                  child: const Text('Ir al dashboard →'),
                ),
              ),
              const SizedBox(height: 14),

              // Editar configuración
              TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                child: const Text('Editar configuración', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted,
                  letterSpacing: 0.08, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
