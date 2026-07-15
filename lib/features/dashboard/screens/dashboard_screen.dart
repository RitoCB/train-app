import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box    = Hive.box(AppConstants.boxSettings);
    final sport  = box.get(AppConstants.keySportType, defaultValue: AppConstants.sportGym) as String;
    final name   = box.get('user_name', defaultValue: 'Atleta') as String;

    return switch (sport) {
      AppConstants.sportMartial   => _MartialDashboard(name: name),
      AppConstants.sportEndurance => _EnduranceDashboard(name: name),
      _                           => _GymDashboard(name: name),
    };
  }
}

// ════════════════════════════════════════════════════════════════
// GYM DASHBOARD
// ════════════════════════════════════════════════════════════════

class _GymDashboard extends StatelessWidget {
  const _GymDashboard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _AppBar(name: name, badge: 'Gym · Fuerza', badgeColor: AppColors.green),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Métricas
                  const _MetricsRow(items: [
                    _Metric(label: 'Sesiones mes',    value: '18',      color: AppColors.green,  delta: '▲ +3'),
                    _Metric(label: 'Volumen (kg)',     value: '24.850',  color: AppColors.blue,   delta: '▲ +8%'),
                    _Metric(label: 'Peso corporal',   value: '82,4 kg', color: AppColors.amber,  delta: '▼ −0,6'),
                    _Metric(label: 'Racha',           value: '7 días',  color: AppColors.purple, delta: '🏅 Récord'),
                  ]),
                  const SizedBox(height: 16),

                  // Volumen semanal
                  const _SectionCard(
                    title: 'Volumen semanal',
                    child: _BarChart(
                      bars: [58, 74, 50, 96, 88, 70, 110],
                      labels: ['S1','S2','S3','S4','S5','S6','S7'],
                      activeIndex: 6,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Récords personales
                  const _SectionCard(
                    title: 'Récords personales',
                    child: Column(children: [
                      _ProgressRow(label: 'Sentadilla',    current: 115, target: 140, color: AppColors.green),
                      SizedBox(height: 12),
                      _ProgressRow(label: 'Press banca',   current: 90,  target: 120, color: AppColors.blue),
                      SizedBox(height: 12),
                      _ProgressRow(label: 'Peso muerto',   current: 145, target: 180, color: AppColors.purple),
                      SizedBox(height: 12),
                      _ProgressRow(label: 'Press militar', current: 65,  target: 85,  color: AppColors.amber),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Historial reciente
                  const _SectionCard(
                    title: 'Historial reciente',
                    child: Column(children: [
                      _ActivityRow(icon: Icons.fitness_center, title: 'Piernas · Fuerza',  sub: 'Hoy · 58 min',      value: '6.240 kg', color: AppColors.green),
                      _ActivityRow(icon: Icons.fitness_center, title: 'Pecho + Tríceps',   sub: 'Ayer · 52 min',     value: '4.900 kg', color: AppColors.blue),
                      _ActivityRow(icon: Icons.fitness_center, title: 'Espalda + Bíceps',  sub: 'Hace 2 días · 61 min', value: '5.520 kg', color: AppColors.purple),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Próxima sesión
                  _NextSession(
                    title: 'Empuje — Hombros',
                    subtitle: 'Mañana · Estimado 55 min · 5 ejercicios',
                    exercises: const ['Press militar  4×6–8', 'Elevaciones laterales  3×12', 'Fondos en paralelas  3×10'],
                    onStart: () => context.push(AppRoutes.session),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// MARTIAL ARTS DASHBOARD
// ════════════════════════════════════════════════════════════════

class _MartialDashboard extends StatelessWidget {
  const _MartialDashboard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _AppBar(name: name, badge: 'MMA · BJJ', badgeColor: AppColors.purple),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _MetricsRow(items: [
                    _Metric(label: 'Sesiones mes',  value: '14',      color: AppColors.purple, delta: '▲ +2'),
                    _Metric(label: 'Horas de mat',  value: '21,5 h',  color: AppColors.blue,   delta: 'Esta semana: 4,5h'),
                    _Metric(label: 'Cinturón',      value: 'Azul',    color: AppColors.amber,  delta: 'BJJ · 1a 4m'),
                    _Metric(label: 'Competición',   value: '18 días', color: AppColors.red,    delta: 'Copa regional'),
                  ]),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    title: 'Progreso por aspecto',
                    child: Column(children: [
                      _ProgressRow(label: 'Llaves',     current: 78, target: 100, color: AppColors.purple),
                      SizedBox(height: 12),
                      _ProgressRow(label: 'Golpeo',     current: 62, target: 100, color: AppColors.blue),
                      SizedBox(height: 12),
                      _ProgressRow(label: 'Resistencia',current: 41, target: 100, color: AppColors.red),
                      SizedBox(height: 12),
                      _ProgressRow(label: 'Clinch',     current: 71, target: 100, color: AppColors.amber),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  const _SectionCard(
                    title: 'Historial reciente',
                    child: Column(children: [
                      _ActivityRow(icon: Icons.sports_martial_arts, title: 'Técnica de llaves + sparring', sub: 'Lunes · 90 min · RPE 8',      value: '4 subs',    color: AppColors.purple),
                      _ActivityRow(icon: Icons.sports_martial_arts, title: 'Muay Thai · Combinaciones',    sub: 'Miércoles · 75 min · RPE 7',  value: '320 golpes', color: AppColors.blue),
                      _ActivityRow(icon: Icons.sports_martial_arts, title: 'Rodadas libres BJJ',           sub: 'Jueves · 60 min · RPE 9',     value: '6 rodadas', color: AppColors.green),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _NextSession(
                    title: 'Sparring técnico',
                    subtitle: 'Viernes · 18:30 · Foco: resistencia',
                    exercises: const ['Calentamiento  15 min', 'Sparring técnico  3×5 min', 'Rodadas libres  3×5 min'],
                    color: AppColors.purple,
                    onStart: () => context.push(AppRoutes.session),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// ENDURANCE DASHBOARD
// ════════════════════════════════════════════════════════════════

class _EnduranceDashboard extends StatelessWidget {
  const _EnduranceDashboard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _AppBar(name: name, badge: 'Carrera · Running', badgeColor: AppColors.blue),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _MetricsRow(items: [
                    _Metric(label: 'Distancia mes', value: '142 km', color: AppColors.blue,   delta: '▲ +18 km'),
                    _Metric(label: 'Mejor ritmo',   value: '4:32',   color: AppColors.green,  delta: 'min/km · 5K'),
                    _Metric(label: 'FC media',      value: '158 bpm',color: AppColors.red,    delta: 'Zona 3'),
                    _Metric(label: 'VO₂ max',       value: '52,4',   color: AppColors.amber,  delta: '▲ +1,2'),
                  ]),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    title: 'Objetivos de distancia',
                    child: Column(children: [
                      _ProgressRow(label: '5K personal',    current: 72, target: 100, color: AppColors.blue,   unit: '22:40 → 21:00'),
                      SizedBox(height: 12),
                      _ProgressRow(label: '10K personal',   current: 55, target: 100, color: AppColors.green,  unit: '47:30 → 45:00'),
                      SizedBox(height: 12),
                      _ProgressRow(label: 'Media maratón',  current: 30, target: 100, color: AppColors.amber,  unit: 'Preparación'),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  const _SectionCard(
                    title: 'Actividades recientes',
                    child: Column(children: [
                      _ActivityRow(icon: Icons.directions_run, title: 'Rodaje suave', sub: 'Hoy · 8,2 km · 45 min',    value: '5:30/km', color: AppColors.blue),
                      _ActivityRow(icon: Icons.directions_run, title: 'Series 400m',  sub: 'Ayer · 6,0 km · 38 min',   value: '4:38/km', color: AppColors.amber),
                      _ActivityRow(icon: Icons.directions_run, title: 'Tirada larga', sub: 'Dom · 16 km · 86 min',     value: '5:22/km', color: AppColors.green),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _NextSession(
                    title: 'Series de velocidad',
                    subtitle: 'Mañana · 8 km · Foco: ritmo',
                    exercises: const ['Calentamiento  2 km', 'Series 400m ×6', 'Vuelta a la calma  2 km'],
                    color: AppColors.blue,
                    onStart: () => context.push(AppRoutes.session),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════════

class _AppBar extends StatelessWidget {
  const _AppBar({required this.name, required this.badge, required this.badgeColor});
  final String name;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Text('Hola, $name 👋',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            // ignore: deprecated_member_use
            border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.5),
          ),
          child: Text(badge, style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.w500)),
        ),
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.green,
          child: Text(initials,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.background)),
        ),
        const SizedBox(width: 16),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0.5),
        child: Divider(height: 0.5, color: AppColors.border),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.items});
  final List<_Metric> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((m) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: items.last == m ? 0 : 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted,
                  letterSpacing: 0.06, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(m.value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: m.color)),
              const SizedBox(height: 3),
              Text(m.delta, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _Metric {
  const _Metric({required this.label, required this.value, required this.color, required this.delta});
  final String label, value, delta;
  final Color color;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted,
              letterSpacing: 0.08, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.current, required this.target,
      required this.color, this.unit});
  final String label;
  final int current, target;
  final Color color;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final pct = (current / target).clamp(0.0, 1.0);
    final right = unit ?? '$current / $target kg';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            Text(right, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct, minHeight: 5,
            backgroundColor: AppColors.surfaceHigh,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.icon, required this.title, required this.sub,
      required this.value, required this.color});
  final IconData icon;
  final String title, sub, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            Text(sub,   style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        )),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _NextSession extends StatelessWidget {
  const _NextSession({
    required this.title, required this.subtitle,
    required this.exercises, required this.onStart,
    this.color = AppColors.green,
  });
  final String title, subtitle;
  final List<String> exercises;
  final VoidCallback onStart;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.18), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              // ignore: deprecated_member_use
              border: Border.all(color: color.withOpacity(0.3), width: 0.5),
            ),
            child: Text('PRÓXIMA SESIÓN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.1)),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          ...exercises.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(e, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ]),
          )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: AppColors.background),
              child: const Text('Iniciar sesión →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars, required this.labels,
      required this.activeIndex, required this.color});
  final List<int> bars;
  final List<String> labels;
  final int activeIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = bars.reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (i) {
          final active = i == activeIndex;
          final h = (bars[i] / maxVal) * 72;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: h,
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: active ? color.withOpacity(0.35) : color.withOpacity(0.15),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      border: Border(top: BorderSide(
                        // ignore: deprecated_member_use
                        color: active ? color : color.withOpacity(0.4), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i], style: TextStyle(
                    fontSize: 10,
                    color: active ? color : AppColors.textMuted,
                  )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
