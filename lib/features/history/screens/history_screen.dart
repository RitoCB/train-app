import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Todos';
  final _filters = ['Todos', 'Gym', 'Running', 'Marciales'];

  // Datos de ejemplo — se sustituirán por Hive/Supabase
  final _sessions = [
    const _Session(title: 'Piernas · Fuerza',    sub: 'Hoy · 5 ejercicios',          value: '6.240 kg', time: '58 min', sport: 'Gym',      icon: Icons.fitness_center,     color: AppColors.green),
    const _Session(title: 'Rodaje suave',        sub: 'Jue 4 Abr · 8,2 km',          value: '5:30/km',  time: '45 min', sport: 'Running',  icon: Icons.directions_run,     color: AppColors.blue),
    const _Session(title: 'Pecho + Tríceps',     sub: 'Mar 2 Abr · 4 ejercicios',    value: '4.900 kg', time: '52 min', sport: 'Gym',      icon: Icons.fitness_center,     color: AppColors.green),
    const _Session(title: 'Sparring BJJ',        sub: 'Lun 1 Abr · 6 rodadas',       value: '90 min',   time: 'RPE 9',  sport: 'Marciales',icon: Icons.sports_martial_arts,color: AppColors.purple),
    const _Session(title: 'Series 400m',         sub: 'Dom 31 Mar · 6 km',           value: '4:38/km',  time: '38 min', sport: 'Running',  icon: Icons.directions_run,     color: AppColors.blue),
    const _Session(title: 'Espalda + Bíceps',    sub: 'Sáb 30 Mar · 5 ejercicios',   value: '5.520 kg', time: '61 min', sport: 'Gym',      icon: Icons.fitness_center,     color: AppColors.green),
    const _Session(title: 'Técnica de llaves',   sub: 'Vie 29 Mar · sparring',        value: '4 subs',   time: '90 min', sport: 'Marciales',icon: Icons.sports_martial_arts,color: AppColors.purple),
    const _Session(title: 'Tirada larga',        sub: 'Jue 28 Mar · 16 km',          value: '5:22/km',  time: '86 min', sport: 'Running',  icon: Icons.directions_run,     color: AppColors.blue),
  ];

  List<_Session> get _filtered =>
      _filter == 'Todos' ? _sessions : _sessions.where((s) => s.sport == _filter).toList();

  // Calendario — días del mes con entrenamiento
  final Set<int> _trainDays = {2, 4, 7, 9};
  final int _today = 9;
  final int _daysInMonth = 30;
  final int _firstWeekday = 2; // Martes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            const SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: Text('Historial',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text('Abril 2026',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(0.5),
                child: Divider(height: 0.5, color: AppColors.border),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // Calendario
                  _Card(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtros
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ABRIL 2026', style: TextStyle(fontSize: 11,
                              color: AppColors.textMuted, letterSpacing: 0.08, fontWeight: FontWeight.w600)),
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
                                  border: Border.all(
                                    color: on ? AppColors.greenBorder : AppColors.border, width: 0.5),
                                ),
                                child: Text(f, style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w500,
                                  color: on ? AppColors.green : AppColors.textMuted,
                                )),
                              ),
                            );
                          }).toList()),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Días de semana
                      Row(
                        children: ['L','M','X','J','V','S','D'].map((d) =>
                          Expanded(child: Center(child: Text(d,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted))))).toList(),
                      ),
                      const SizedBox(height: 8),

                      // Grid días
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: _firstWeekday - 1 + _daysInMonth,
                        itemBuilder: (_, i) {
                          if (i < _firstWeekday - 1) return const SizedBox();
                          final day = i - (_firstWeekday - 1) + 1;
                          final isToday = day == _today;
                          final isTrain = _trainDays.contains(day);
                          return Container(
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.green
                                  : isTrain ? AppColors.greenDim
                                  : AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text('$day', style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500,
                                color: isToday ? AppColors.background
                                    : isTrain ? AppColors.green
                                    : AppColors.textMuted,
                              )),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 14),
                      // Leyenda
                      Row(children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 6),
                        const Text('Hoy', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(width: 16),
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: AppColors.greenDim, borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: AppColors.greenBorder, width: 0.5))),
                        const SizedBox(width: 6),
                        const Text('Entrenado', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ]),
                    ],
                  )),
                  const SizedBox(height: 12),

                  // Resumen del mes
                  const Row(children: [
                    Expanded(child: _MiniStat(label: 'Sesiones', value: '8',       color: AppColors.green)),
                    SizedBox(width: 8),
                    Expanded(child: _MiniStat(label: 'Horas',    value: '7,8 h',   color: AppColors.blue)),
                    SizedBox(width: 8),
                    Expanded(child: _MiniStat(label: 'Volumen',  value: '42.1K kg',color: AppColors.purple)),
                    SizedBox(width: 8),
                    Expanded(child: _MiniStat(label: 'km',       value: '24,4',    color: AppColors.amber)),
                  ]),
                  const SizedBox(height: 16),

                  // Lista sesiones
                  const Text('SESIONES RECIENTES', style: TextStyle(fontSize: 11,
                      color: AppColors.textMuted, letterSpacing: 0.08, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),

                  ..._filtered.map((s) => _SessionTile(
                    session: s,
                    onTap: () {}, // TODO: detalle de sesión
                  )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
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
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onTap});
  final _Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: session.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(session.icon, color: session.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(session.sub,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(session.value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: session.color)),
            const SizedBox(height: 2),
            Text(session.time,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ]),
      ),
    );
  }
}

// ── Modelo ───────────────────────────────────────────────────────

class _Session {
  const _Session({required this.title, required this.sub, required this.value,
      required this.time, required this.sport, required this.icon, required this.color});
  final String title, sub, value, time, sport;
  final IconData icon;
  final Color color;
}
