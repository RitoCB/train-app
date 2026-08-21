import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = Supabase.instance.client;
  bool _loading = true;

  // Métricas
  int _sessionCount = 0;
  double _totalVolume = 0;
  double _bodyWeight = 0;
  int _streak = 0;
  List<Map<String, dynamic>> _recentSessions = [];
  List<Map<String, dynamic>> _personalRecords = [];
  List<int> _weeklyVolume = [0, 0, 0, 0, 0, 0, 0];

  late String _sport;
  late String _name;

  @override
  void initState() {
    super.initState();
    final box = Hive.box(AppConstants.boxSettings);
    _sport = box.get(AppConstants.keySportType, defaultValue: AppConstants.sportGym) as String;
    _name  = box.get('user_name', defaultValue: 'Atleta') as String;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;

      final now   = DateTime.now();
      final month = DateTime(now.year, now.month, 1).toIso8601String();

      // Sesiones del mes
      final sessions = await _db
          .from('sessions')
          .select()
          .eq('user_id', uid)
          .gte('created_at', month)
          .order('created_at', ascending: false);

      // Volumen total del mes
      double vol = 0;
      for (final s in sessions) {
        vol += (s['volume_kg'] as num? ?? 0).toDouble();
      }

      // Sesiones recientes (últimas 5)
      final recent = await _db
          .from('sessions')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(5);

      // Récords personales
      final records = await _db
          .from('personal_records')
          .select()
          .eq('user_id', uid)
          .order('value_kg', ascending: false)
          .limit(4);

      // Peso corporal más reciente
      final profile = await _db
          .from('profiles')
          .select('weight_kg, name')
          .eq('id', uid)
          .single();

      // Volumen por semana (últimas 7 semanas)
      final weeklyData = List<int>.filled(7, 0);
      for (var i = 0; i < 7; i++) {
        final weekStart = now.subtract(Duration(days: (6 - i) * 7));
        final weekEnd   = weekStart.add(const Duration(days: 7));
        final weekSessions = await _db
            .from('sessions')
            .select('volume_kg')
            .eq('user_id', uid)
            .gte('created_at', weekStart.toIso8601String())
            .lt('created_at', weekEnd.toIso8601String());
        int wVol = 0;
        for (final s in weekSessions) {
          wVol += (s['volume_kg'] as num? ?? 0).toInt();
        }
        weeklyData[i] = wVol;
      }

      // Racha de días consecutivos
      final allSessions = await _db
          .from('sessions')
          .select('created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      int streak = 0;
      DateTime check = DateTime(now.year, now.month, now.day);
      final sessionDays = allSessions.map((s) {
        final d = DateTime.parse(s['created_at'] as String);
        return DateTime(d.year, d.month, d.day);
      }).toSet();

      while (sessionDays.contains(check)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      }

      if (mounted) {
        setState(() {
          _sessionCount    = sessions.length;
          _totalVolume     = vol;
          _bodyWeight      = (profile['weight_kg'] as num? ?? 0).toDouble();
          _name            = (profile['name'] as String? ?? _name);
          _recentSessions  = List<Map<String, dynamic>>.from(recent);
          _personalRecords = List<Map<String, dynamic>>.from(records);
          _weeklyVolume    = weeklyData;
          _streak          = streak;
          _loading         = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.green))
            : RefreshIndicator(
                color: AppColors.green,
                backgroundColor: AppColors.surface,
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    _AppBar(name: _name, sport: _sport),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Métricas principales
                          _MetricsRow(
                            sessionCount: _sessionCount,
                            totalVolume:  _totalVolume,
                            bodyWeight:   _bodyWeight,
                            streak:       _streak,
                            sport:        _sport,
                          ),
                          const SizedBox(height: 16),

                          // Gráfico volumen semanal
                          if (_sport == AppConstants.sportGym) ...[
                            _SectionCard(
                              title: 'Volumen semanal',
                              child: _BarChart(
                                bars: _weeklyVolume,
                                labels: const ['S1','S2','S3','S4','S5','S6','S7'],
                                activeIndex: 6,
                                color: AppColors.green,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Récords personales
                          if (_personalRecords.isNotEmpty) ...[
                            _SectionCard(
                              title: 'Récords personales',
                              child: Column(
                                children: _personalRecords.asMap().entries.map((e) {
                                  final colors = [AppColors.green, AppColors.blue, AppColors.purple, AppColors.amber];
                                  final r = e.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ProgressRow(
                                      label:   r['name'] as String? ?? '—',
                                      current: (r['value_kg'] as num? ?? 0).toInt(),
                                      target:  ((r['value_kg'] as num? ?? 0) * 1.2).toInt(),
                                      color:   colors[e.key % colors.length],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Historial reciente
                          if (_recentSessions.isNotEmpty)
                            _SectionCard(
                              title: 'Historial reciente',
                              child: Column(
                                children: _recentSessions.map((s) => _SessionRow(session: s, sport: _sport)).toList(),
                              ),
                            ),
                          if (_recentSessions.isEmpty)
                            _EmptyState(onStart: () => context.push(AppRoutes.session)),
                          const SizedBox(height: 12),

                          // Próxima sesión
                          _NextSession(onStart: () => context.push(AppRoutes.session)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({required this.name, required this.sport});
  final String name, sport;

  String get _badge => switch (sport) {
    AppConstants.sportMartial   => 'MMA · BJJ',
    AppConstants.sportEndurance => 'Carrera · Running',
    _                           => 'Gym · Fuerza',
  };

  Color get _color => switch (sport) {
    AppConstants.sportMartial   => AppColors.purple,
    AppConstants.sportEndurance => AppColors.blue,
    _                           => AppColors.green,
  };

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text('Hola, $name 👋',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: _color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            // ignore: deprecated_member_use
            border: Border.all(color: _color.withOpacity(0.3), width: 0.5),
          ),
          child: Text(_badge, style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w500)),
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

// ── Métricas ──────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.sessionCount, required this.totalVolume,
    required this.bodyWeight,   required this.streak, required this.sport,
  });
  final int sessionCount, streak;
  final double totalVolume, bodyWeight;
  final String sport;

  @override
  Widget build(BuildContext context) {
    final volLabel = sport == AppConstants.sportEndurance
        ? '${totalVolume.toStringAsFixed(0)} km'
        : '${totalVolume.toStringAsFixed(0)} kg';

    return Row(children: [
      Expanded(child: _MetricCard(label: 'Sesiones mes', value: '$sessionCount', color: AppColors.green, delta: 'Este mes')),
      const SizedBox(width: 8),
      Expanded(child: _MetricCard(label: sport == AppConstants.sportEndurance ? 'Distancia' : 'Volumen', value: volLabel, color: AppColors.blue, delta: 'Total mes')),
      const SizedBox(width: 8),
      Expanded(child: _MetricCard(label: 'Peso', value: bodyWeight > 0 ? '${bodyWeight}kg' : '—', color: AppColors.amber, delta: 'Actual')),
      const SizedBox(width: 8),
      Expanded(child: _MetricCard(label: 'Racha', value: '$streak d', color: AppColors.purple, delta: streak > 0 ? '🔥 Activa' : 'Sin racha')),
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.color, required this.delta});
  final String label, value, delta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted,
            letterSpacing: 0.06, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 3),
        Text(delta, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ]),
    );
  }
}

// ── Widgets compartidos ───────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title; final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted,
          letterSpacing: 0.08, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.current, required this.target, required this.color});
  final String label; final int current, target; final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        Text('$current kg', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: pct, minHeight: 5,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(color))),
    ]);
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.sport});
  final Map<String, dynamic> session;
  final String sport;

  String _formatDate(String iso) {
    final d = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return 'Hace $diff días';
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (sport) {
      AppConstants.sportMartial   => AppColors.purple,
      AppConstants.sportEndurance => AppColors.blue,
      _                           => AppColors.green,
    };
    final icon = switch (sport) {
      AppConstants.sportMartial   => Icons.sports_martial_arts,
      AppConstants.sportEndurance => Icons.directions_run,
      _                           => Icons.fitness_center,
    };
    final vol  = (session['volume_kg'] as num? ?? 0).toInt();
    final dur  = (session['duration_sec'] as num? ?? 0).toInt();
    final mins = dur ~/ 60;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 38, height: 38,
            // ignore: deprecated_member_use
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(session['title'] as String? ?? 'Sesión',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          Text('${_formatDate(session['created_at'] as String)} · $mins min',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        Text(vol > 0 ? '$vol kg' : '${(session['rpe'] ?? '—')} RPE',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(children: [
      const Icon(Icons.fitness_center_outlined, color: AppColors.textMuted, size: 36),
      const SizedBox(height: 12),
      const Text('Aún no tienes sesiones',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      const Text('Registra tu primer entrenamiento para ver tus estadísticas',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onStart, child: const Text('Iniciar primera sesión')),
    ]),
  );
}

class _NextSession extends StatelessWidget {
  const _NextSession({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      // ignore: deprecated_member_use
      color: AppColors.green.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
      // ignore: deprecated_member_use
      border: Border.all(color: AppColors.green.withOpacity(0.18), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.greenDim, borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.greenBorder, width: 0.5)),
        child: const Text('NUEVA SESIÓN', style: TextStyle(fontSize: 10,
            fontWeight: FontWeight.w600, color: AppColors.green, letterSpacing: 0.1)),
      ),
      const SizedBox(height: 12),
      const Text('¿Listo para entrenar?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      const Text('Registra tu sesión y actualiza tus estadísticas',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity,
          child: ElevatedButton(onPressed: onStart, child: const Text('Iniciar sesión →'))),
    ]),
  );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars, required this.labels, required this.activeIndex, required this.color});
  final List<int> bars; final List<String> labels; final int activeIndex; final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = bars.isEmpty ? 1 : bars.reduce((a, b) => a > b ? a : b);
    final max    = maxVal == 0 ? 1 : maxVal;
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (i) {
          final active = i == activeIndex;
          final h = (bars[i] / max) * 72;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(height: h.clamp(4.0, 72.0),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: active ? color.withOpacity(0.35) : color.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  // ignore: deprecated_member_use
                  border: Border(top: BorderSide(color: active ? color : color.withOpacity(0.4), width: 1.5)),
                )),
              const SizedBox(height: 6),
              Text(labels[i], style: TextStyle(fontSize: 10, color: active ? color : AppColors.textMuted)),
            ]),
          ));
        }),
      ),
    );
  }
}
