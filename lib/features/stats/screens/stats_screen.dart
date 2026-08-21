import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _db = Supabase.instance.client;
  bool _loading = true;
  String _range = '1M';
  final _ranges = ['1M', '3M', '1A'];

  int _totalSessions = 0;
  double _totalVolume = 0;
  double _bodyWeight = 0;
  int _streak = 0;
  List<Map<String, dynamic>> _records = [];
  Map<String, int> _sportDist = {};
  List<int> _weeklySessions = [0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime get _rangeStart {
    final now = DateTime.now();
    return switch (_range) {
      '3M' => DateTime(now.year, now.month - 3, now.day),
      '1A' => DateTime(now.year - 1, now.month, now.day),
      _    => DateTime(now.year, now.month - 1, now.day),
    };
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;

      final start = _rangeStart.toIso8601String();

      // Sesiones del rango
      final sessions = await _db
          .from('sessions')
          .select()
          .eq('user_id', uid)
          .gte('created_at', start)
          .order('created_at', ascending: false);

      double vol = 0;
      final Map<String, int> dist = {};
      for (final s in sessions) {
        vol += (s['volume_kg'] as num? ?? 0);
        final sp = s['sport'] as String? ?? AppConstants.sportGym;
        dist[sp] = (dist[sp] ?? 0) + 1;
      }

      // Sesiones por semana (últimas 4)
      final now = DateTime.now();
      final weekly = List<int>.filled(4, 0);
      for (var i = 0; i < 4; i++) {
        final wStart = now.subtract(Duration(days: (3 - i) * 7 + now.weekday - 1));
        final wEnd   = wStart.add(const Duration(days: 7));
        weekly[i] = sessions.where((s) {
          final d = DateTime.parse(s['created_at'] as String);
          return d.isAfter(wStart) && d.isBefore(wEnd);
        }).length;
      }

      // Récords personales
      final records = await _db
          .from('personal_records')
          .select()
          .eq('user_id', uid)
          .order('value_kg', ascending: false)
          .limit(5);

      // Perfil
      final profile = await _db
          .from('profiles')
          .select('weight_kg')
          .eq('id', uid)
          .single();

      // Racha
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
        _totalSessions = sessions.length;
        _totalVolume   = vol;
        _bodyWeight    = (profile['weight_kg'] as num? ?? 0).toDouble();
        _streak        = streak;
        _records       = List<Map<String, dynamic>>.from(records);
        _sportDist     = dist;
        _weeklySessions = weekly;
        _loading       = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDist = _sportDist.values.fold(0, (a, b) => a + b);

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
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      backgroundColor: AppColors.surface,
                      surfaceTintColor: Colors.transparent,
                      title: const Text('Estadísticas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      actions: [
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
                          child: Row(children: _ranges.map((r) {
                            final on = _range == r;
                            return GestureDetector(
                              onTap: () { setState(() => _range = r); _loadData(); },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: on ? AppColors.surface : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                    color: on ? AppColors.textPrimary : AppColors.textMuted)),
                              ),
                            );
                          }).toList()),
                        ),
                      ],
                      bottom: const PreferredSize(preferredSize: Size.fromHeight(0.5),
                          child: Divider(height: 0.5, color: AppColors.border)),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // Métricas globales
                          Row(children: [
                            Expanded(child: _StatCard(value: '$_totalSessions', label: 'Sesiones', color: AppColors.green)),
                            const SizedBox(width: 8),
                            Expanded(child: _StatCard(value: _totalVolume.toStringAsFixed(0), label: 'Vol. kg', color: AppColors.blue)),
                            const SizedBox(width: 8),
                            Expanded(child: _StatCard(value: _bodyWeight > 0 ? '${_bodyWeight}kg' : '—', label: 'Peso', color: AppColors.amber)),
                            const SizedBox(width: 8),
                            Expanded(child: _StatCard(value: '$_streak d', label: 'Racha', color: AppColors.purple)),
                          ]),
                          const SizedBox(height: 16),

                          // Récords personales
                          if (_records.isNotEmpty) ...[
                            _SectionCard(
                              title: 'Récords personales',
                              child: Column(
                                children: _records.asMap().entries.map((e) {
                                  final colors = [AppColors.green, AppColors.blue, AppColors.purple, AppColors.amber, AppColors.red];
                                  final r = e.value;
                                  final val = (r['value_kg'] as num? ?? 0).toInt();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text(r['name'] as String? ?? '—',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                        Text('$val kg', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                            color: colors[e.key % colors.length])),
                                      ]),
                                      const SizedBox(height: 6),
                                      // Barras de progreso históricas simuladas
                                      SizedBox(height: 28, child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: List.generate(5, (i) {
                                          final pct = (0.6 + i * 0.1).clamp(0.0, 1.0);
                                          return Expanded(child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                            height: 28 * pct,
                                            decoration: BoxDecoration(
                                              color: i == 4 ? colors[e.key % colors.length]
                                                  // ignore: deprecated_member_use
                                                  : colors[e.key % colors.length].withOpacity(0.2 + i * 0.1),
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                            ),
                                          ));
                                        }),
                                      )),
                                    ]),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Sin récords
                          if (_records.isEmpty) ...[
                            const _SectionCard(
                              title: 'Récords personales',
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: Text('Completa sesiones para ver tus récords',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Distribución por deporte
                          if (_sportDist.isNotEmpty) ...[
                            _SectionCard(
                              title: 'Distribución de entrenamientos',
                              child: Column(
                                children: _sportDist.entries.map((e) {
                                  final pct = totalDist > 0 ? e.value / totalDist : 0.0;
                                  final label = switch (e.key) {
                                    AppConstants.sportMartial   => 'Artes Marciales',
                                    AppConstants.sportEndurance => 'Running',
                                    _                           => 'Gym · Fuerza',
                                  };
                                  final color = switch (e.key) {
                                    AppConstants.sportMartial   => AppColors.purple,
                                    AppConstants.sportEndurance => AppColors.blue,
                                    _                           => AppColors.green,
                                  };
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                        Text('${e.value} ses · ${(pct * 100).round()}%',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ]),
                                      const SizedBox(height: 6),
                                      ClipRRect(borderRadius: BorderRadius.circular(99),
                                          child: LinearProgressIndicator(value: pct, minHeight: 5,
                                              backgroundColor: AppColors.surfaceHigh,
                                              valueColor: AlwaysStoppedAnimation(color))),
                                    ]),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Sesiones por semana
                          _SectionCard(
                            title: 'Sesiones por semana',
                            child: _WeeklyBars(data: _weeklySessions, labels: const ['S1','S2','S3','S4']),
                          ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.color});
  final String value, label; final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ]),
  );
}

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
      const SizedBox(height: 16),
      child,
    ]),
  );
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.data, required this.labels});
  final List<int> data; final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxV = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    final max  = maxV == 0 ? 1 : maxV;
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((e) {
          final h = (e.value / max) * 56.0;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('${e.value}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Container(height: h.clamp(4.0, 56.0),
                  decoration: const BoxDecoration(color: AppColors.greenDim,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                      border: Border(top: BorderSide(color: AppColors.green, width: 1.5)))),
              const SizedBox(height: 6),
              Text(labels[e.key], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ));
        }).toList(),
      ),
    );
  }
}
