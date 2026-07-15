import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class SportSelectionScreen extends StatefulWidget {
  const SportSelectionScreen({super.key});

  @override
  State<SportSelectionScreen> createState() => _SportSelectionScreenState();
}

class _SportSelectionScreenState extends State<SportSelectionScreen> {
  String? _selected;

  final _sports = [
    const _SportOption(
      id: AppConstants.sportGym,
      title: 'Gym / Fuerza',
      subtitle: 'Pesos libres, máquinas, calistenia',
      icon: Icons.fitness_center_rounded,
      color: AppColors.green,
    ),
    const _SportOption(
      id: AppConstants.sportMartial,
      title: 'Artes Marciales',
      subtitle: 'Técnica, golpeo, resistencia',
      icon: Icons.sports_martial_arts_rounded,
      color: AppColors.purple,
    ),
    const _SportOption(
      id: AppConstants.sportEndurance,
      title: 'Deportes de resistencia',
      subtitle: 'Running, natación, ciclismo',
      icon: Icons.directions_run_rounded,
      color: AppColors.blue,
    ),
    const _SportOption(
      id: AppConstants.sportCustom,
      title: 'Otro deporte',
      subtitle: 'Crea un perfil personalizado',
      icon: Icons.star_outline_rounded,
      color: AppColors.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progreso
              const _StepIndicator(current: 1, total: 3),
              const SizedBox(height: 32),

              // Título
              const Text(
                '¿Cuál es tu objetivo\ndeportivo?',
                style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary, height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalizaremos tu experiencia según tu deporte',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // Opciones
              Expanded(
                child: ListView.separated(
                  itemCount: _sports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final s = _sports[i];
                    final selected = _selected == s.id;
                    return _SportCard(
                      option: s,
                      selected: selected,
                      onTap: () => setState(() => _selected = s.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Botón continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => context.push(
                            '${AppRoutes.profileSetup}?sport=$_selected',
                          ),
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: AppColors.surface,
                    disabledForegroundColor: AppColors.textMuted,
                  ),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sport card ──────────────────────────────────────────────────

class _SportCard extends StatelessWidget {
  const _SportCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _SportOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              // ignore: deprecated_member_use
              ? option.color.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? option.color : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: option.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon, color: option.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 3),
                  Text(option.subtitle,
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary,
                      )),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? option.color : Colors.transparent,
                border: Border.all(
                  color: selected ? option.color : AppColors.borderStrong,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: AppColors.background)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step indicator ──────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i + 1 == current;
        final done = i + 1 < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: done || active ? AppColors.green : AppColors.surface,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

// ── Data class ──────────────────────────────────────────────────

class _SportOption {
  const _SportOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
