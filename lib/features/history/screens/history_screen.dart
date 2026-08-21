import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = Supabase.instance.client;
  bool _loading = true;
  String _filter = 'Todos';
  final _filters = ['Todos', 'Gym', 'Running', 'Marciales'];

  List<Map<String, dynamic>> _sessions = [];
  int _totalSessions = 0;
  double _totalHours = 0;
  double _totalVolume = 0;
  double _totalKm = 0;
  final Set<int> _trainDays = {};
  final int _today = DateTime.now().day;
  final int _daysInMonth = DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month);
  final int _firstWeekday = DateTime(DateTime.now().year, DateTime.now().month, 1).weekday;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;

      final now   = DateTime.now();
      final month = DateTime(now.year, now.month, 1).toIso8601String();

      final sessions = await _db
          .from('sessions')
          .select()
          .eq('user_id', uid)
          .gte('created_at', month)
          .order('created_at', ascending: false);

      final Set<int> trainDays = {};
      double hours = 0, volume = 0, km = 0;

      for (final s in sessions) {
        final d = DateTime.parse(s['created_at'] as String).toLocal();
        trainDays.add(d.day);
        hours  += (s['duration_sec'] as num? ?? 0) / 3600;
        volume += (s['volume_kg'] as num? ?? 0);
        if ((s['sport'] as String? ?? '') == AppConstants.sportEndurance) {
          km += (s['volume_kg'] as num? ?? 0);
        }
      }

      if (mounted) {
        setState(() {
        _sessions      = List<Map<String, dynamic>>.from(sessions);
        _totalSessions = sessions.length;
        _totalHours    = hours;
        _totalVolume   = volume;
        _totalKm       = km;
        _trainDays.clear();
        _trainDays.addAll(trainDays);
        _loading       = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'Todos') return _sessions;
    final sportMap = {'Gym': AppConstants.sportGym, 'Running': AppConstants.sportEndurance, 'Marciales': AppConstants.sportMartial};
    return _sessions.where((s) => s['sport'] == sportMap[_filter]).toList();
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    final box   = Hive.box(AppConstants.boxSettings);
    final sport = box.get(AppConstants.keySportType, defaultValue: AppConstants.sportGym) as String;

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
                      title: const Text('Historial',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      actions: [
                        Padding(padding: const EdgeInsets.only(right: 16),
                            child: Text('${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
                      ],
                      bottom: const PreferredSize(preferredSize: Size.fromHeight(0.5),
                          child: Divider(height: 0.5, color: AppColors.border)),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // Calendario
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border, width: 0.5)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(_monthName(DateTime.now().month).toUpperCase(),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted,
                                        letterSpacing: 0.08, fontWeight: FontWeight.w600)),
                                Row(children: _filters.map((f) {
                                  final on = _filter == f;
                                  return GestureDetector(
                                    onTap: () => setState(() => _filter = f),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: on ? AppColors.greenDim : AppColors.surfaceHigh,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: on ? AppColors.greenBorder : AppColors.border, width: 0.5),
                                      ),
                                      child: Text(f, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                                          color: on ? AppColors.green : AppColors.textMuted)),
                                    ),
                                  );
                                }).toList()),
                              ]),
                              const SizedBox(height: 12),
                              Row(children: ['L','M','X','J','V','S','D'].map((d) =>
                                  Expanded(child: Center(child: Text(d,
                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted))))).toList()),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1.1),
                                itemCount: _firstWeekday - 1 + _daysInMonth,
                                itemBuilder: (_, i) {
                                  if (i < _firstWeekday - 1) return const SizedBox();
                                  final day     = i - (_firstWeekday - 1) + 1;
                                  final isToday = day == _today;
                                  final isTrain = _trainDays.contains(day);
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isToday ? AppColors.green : isTrain ? AppColors.greenDim : AppColors.surfaceHigh,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(child: Text('$day', style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w500,
                                      color: isToday ? AppColors.background : isTrain ? AppColors.green : AppColors.textMuted,
                                    ))),
                                  );
                                },
                              ),
                            ]),
                          ),
                          const SizedBox(height: 12),

                          // Resumen
                          Row(children: [
                            Expanded(child: _MiniStat(label: 'Sesiones', value: '$_totalSessions', color: AppColors.green)),
                            const SizedBox(width: 8),
                            Expanded(child: _MiniStat(label: 'Horas', value: _totalHours.toStringAsFixed(1), color: AppColors.blue)),
                            const SizedBox(width: 8),
                            Expanded(child: _MiniStat(label: 'Vol. kg', value: _totalVolume.toStringAsFixed(0), color: AppColors.purple)),
                            const SizedBox(width: 8),
                            Expanded(child: _MiniStat(label: 'km', value: _totalKm.toStringAsFixed(1), color: AppColors.amber)),
                          ]),
                          const SizedBox(height: 16),

                          const Text('SESIONES RECIENTES', style: TextStyle(fontSize: 11,
                              color: AppColors.textMuted, letterSpacing: 0.08, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),

                          if (_filtered.isEmpty)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No hay sesiones este mes',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            )),

                          ..._filtered.map((s) {
                            final sportVal = s['sport'] as String? ?? sport;
                            final color = switch (sportVal) {
                              AppConstants.sportMartial   => AppColors.purple,
                              AppConstants.sportEndurance => AppColors.blue,
                              _                           => AppColors.green,
                            };
                            final icon = switch (sportVal) {
                              AppConstants.sportMartial   => Icons.sports_martial_arts,
                              AppConstants.sportEndurance => Icons.directions_run,
                              _                           => Icons.fitness_center,
                            };
                            final vol  = (s['volume_kg'] as num? ?? 0).toInt();
                            final dur  = (s['duration_sec'] as num? ?? 0).toInt();
                            final mins = dur ~/ 60;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border, width: 0.5)),
                              child: Row(children: [
                                Container(width: 40, height: 40,
                                    // ignore: deprecated_member_use
                                    decoration: BoxDecoration(color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10)),
                                    child: Icon(icon, color: color, size: 18)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(s['title'] as String? ?? 'Sesión',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                  Text('${_formatDate(s['created_at'] as String)} · $mins min',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text(vol > 0 ? '$vol kg' : '—',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
                                  Text('RPE ${s['rpe'] ?? '—'}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ]),
                              ]),
                            );
                          }),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _monthName(int m) => ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
      'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'][m - 1];
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label, value; final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ]),
  );
}
