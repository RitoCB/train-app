import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _range = '1M';
  final _ranges = ['1M', '3M', '1A'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: _ranges.map((r) {
                      final on = _range == r;
                      return GestureDetector(
                        onTap: () => setState(() => _range = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: on ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(r, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: on ? AppColors.textPrimary : AppColors.textMuted,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(0.5),
                child: Divider(height: 0.5, color: AppColors.border),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // Métricas globales
                  const Row(children: [
                    Expanded(child: _StatCard(value: '18', label: 'Sesiones', color: AppColors.green, delta: '▲ +3')),
                    SizedBox(width: 8),
                    Expanded(child: _StatCard(value: '24.850', label: 'Volumen kg', color: AppColors.blue, delta: '▲ +8%')),
                    SizedBox(width: 8),
                    Expanded(child: _StatCard(value: '82,4', label: 'Peso kg', color: AppColors.amber, delta: '▼ −0,6')),
                    SizedBox(width: 8),
                    Expanded(child: _StatCard(value: '7', label: 'Racha días', color: AppColors.purple, delta: '🏅')),
                  ]),
                  const SizedBox(height: 16),

                  // Evolución pesos máximos
                  const _SectionCard(
                    title: 'Evolución de pesos máximos',
                    child: Column(children: [
                      _LiftProgress(name: 'Sentadilla',    current: 115, bars: [85, 95, 100, 110, 115], color: AppColors.green),
                      SizedBox(height: 20),
                      _LiftProgress(name: 'Press banca',   current: 90,  bars: [70, 75, 80, 85, 90],  color: AppColors.blue),
                      SizedBox(height: 20),
                      _LiftProgress(name: 'Peso muerto',   current: 145, bars: [110, 120, 130, 140, 145], color: AppColors.purple),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Evolución peso corporal
                  const _SectionCard(
                    title: 'Evolución del peso corporal',
                    child: Column(children: [
                      _WeightChart(
                        points: [84.8, 84.2, 83.7, 83.1, 82.8, 82.4],
                        labels: ['Dic', 'Ene', 'Feb', 'Mar', 'Abr', 'Hoy'],
                        color: AppColors.amber,
                      ),
                      SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _InfoBox(label: 'Pérdida total', value: '−2,4 kg', color: AppColors.green)),
                        SizedBox(width: 8),
                        Expanded(child: _InfoBox(label: 'Objetivo', value: '78 kg', color: AppColors.textSecondary)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Distribución de entrenamientos
                  const _SectionCard(
                    title: 'Distribución de entrenamientos',
                    child: Column(children: [
                      _DistRow(label: 'Gym · Fuerza',    sessions: 11, pct: 0.61, color: AppColors.green),
                      SizedBox(height: 12),
                      _DistRow(label: 'Running',          sessions: 5,  pct: 0.28, color: AppColors.blue),
                      SizedBox(height: 12),
                      _DistRow(label: 'Artes Marciales', sessions: 2,  pct: 0.11, color: AppColors.purple),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Racha semanal
                  const _SectionCard(
                    title: 'Sesiones por semana',
                    child: _WeeklyBars(
                      data: [3, 2, 4, 1],
                      labels: ['S1', 'S2', 'S3', 'S4'],
                    ),
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

// ── Widgets ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.color, required this.delta});
  final String value, label, delta;
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
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(delta, style: TextStyle(fontSize: 10, color: color)),
      ]),
    );
  }
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted,
            letterSpacing: 0.08, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _LiftProgress extends StatelessWidget {
  const _LiftProgress({required this.name, required this.current, required this.bars, required this.color});
  final String name;
  final int current;
  final List<int> bars;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = bars.reduce((a, b) => a > b ? a : b);
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        Text('$current kg', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: 36,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars.asMap().entries.map((e) {
            final isLast = e.key == bars.length - 1;
            final h = (e.value / maxVal) * 32;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: h,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: isLast ? color : color.withOpacity(0.2 + e.key * 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 4),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Dic', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
        Text('Hoy', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ]),
    ]);
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.points, required this.labels, required this.color});
  final List<double> points;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final minV = points.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxV = points.reduce((a, b) => a > b ? a : b) + 0.5;
    final range = maxV - minV;

    return SizedBox(
      height: 90,
      child: CustomPaint(
        painter: _LinePainter(points: points, min: minV, range: range, color: color),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 70),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels.map((l) =>
                Text(l, style: const TextStyle(fontSize: 9, color: AppColors.textMuted))).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.points, required this.min, required this.range, required this.color});
  final List<double> points;
  final double min, range;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final h = size.height - 20;
    final w = size.width;
    final step = w / (points.length - 1);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = step * i;
      final y = h - ((points[i] - min) / range) * h;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Punto final
    final lastX = step * (points.length - 1);
    final lastY = h - ((points.last - min) / range) * h;
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _DistRow extends StatelessWidget {
  const _DistRow({required this.label, required this.sessions, required this.pct, required this.color});
  final String label;
  final int sessions;
  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        Text('$sessions sesiones · ${(pct * 100).round()}%',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: pct, minHeight: 5,
          backgroundColor: AppColors.surfaceHigh,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.data, required this.labels});
  final List<int> data;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxV = data.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((e) {
          final h = maxV == 0 ? 0.0 : (e.value / maxV) * 56.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${e.value}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Container(
                  height: h.clamp(6.0, 56.0),
                  decoration: const BoxDecoration(
                    color: AppColors.greenDim,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    border: Border(top: BorderSide(color: AppColors.green, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(labels[e.key], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
} 
