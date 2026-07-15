import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final Timer _timer;
  int _seconds      = 0;
  int _totalVolume  = 0;
  int _totalSets    = 0;
  int _rpe          = 7;
  bool _saving      = false;
  final _notesCtrl  = TextEditingController();

  final List<_Exercise> _exercises = [
    _Exercise(name: 'Sentadilla con barra', tag: 'Completado',
      sets: [_Set(reps: 8, weight: 100, done: true), _Set(reps: 6, weight: 110, done: true),
             _Set(reps: 5, weight: 115, done: true), _Set(reps: 5, weight: 115, done: true)]),
    _Exercise(name: 'Prensa de piernas', tag: 'En curso',
      sets: [_Set(reps: 10, weight: 180, done: true), _Set(reps: 8, weight: 200, done: true),
             _Set(reps: 0,  weight: 200, done: false), _Set(reps: 0, weight: 200, done: false)]),
    _Exercise(name: 'Extensión de cuádriceps', tag: 'Pendiente',
      sets: [_Set(reps: 12, weight: 60, done: false), _Set(reps: 12, weight: 60, done: false),
             _Set(reps: 12, weight: 60, done: false)]),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
    _recalculate();
  }

  void _recalculate() {
    int vol = 0, sets = 0;
    for (final ex in _exercises) {
      for (final s in ex.sets) {
        if (s.done && s.reps > 0) { vol += s.reps * s.weight; sets++; }
      }
    }
    _totalVolume = vol; _totalSets = sets;
  }

  String get _elapsed {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  void _toggleSet(int exIdx, int setIdx) {
    setState(() {
      _exercises[exIdx].sets[setIdx].done = !_exercises[exIdx].sets[setIdx].done;
      _recalculate();
    });
  }

  Future<void> _saveSession() async {
    _timer.cancel();
    setState(() => _saving = true);
    try {
      final box   = Hive.box(AppConstants.boxSettings);
      final sport = box.get(AppConstants.keySportType, defaultValue: AppConstants.sportGym) as String;
      final uid   = Supabase.instance.client.auth.currentUser?.id;

      if (uid != null) {
        await Supabase.instance.client.from('sessions').insert({
          'user_id':      uid,
          'title':        'Piernas · Fuerza',
          'sport':        sport,
          'duration_sec': _seconds,
          'volume_kg':    _totalVolume.toDouble(),
          'total_sets':   _totalSets,
          'rpe':          _rpe,
          'notes':        _notesCtrl.text.trim(),
        });
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al guardar: $e'),
        backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
      ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _finishSession() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Finalizar sesión?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _SummaryTile(label: 'Duración',            value: _elapsed),
          _SummaryTile(label: 'Series completadas',  value: '$_totalSets'),
          _SummaryTile(label: 'Volumen total',       value: '$_totalVolume kg'),
          _SummaryTile(label: 'RPE',                 value: '$_rpe / 10'),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _timer.cancel(); },
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: _saving ? null : () { Navigator.pop(context); _saveSession(); },
            child: _saving
                ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                : const Text('Guardar y salir'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _timer.cancel(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        title: const Text('Sesión activa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.greenDim, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.greenBorder, width: 0.5)),
            child: const Text('En curso', style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w500)),
          ),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(0.5),
            child: Divider(height: 0.5, color: AppColors.border)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SessionHeader(elapsed: _elapsed, totalSets: _totalSets, totalVolume: _totalVolume,
                exercisesDone: _exercises.where((e) => e.tag == 'Completado').length,
                totalExercises: _exercises.length),
            const SizedBox(height: 20),

            ..._exercises.asMap().entries.map((e) =>
              _ExerciseCard(exercise: e.value, index: e.key, onToggleSet: (si) => _toggleSet(e.key, si))),

            const SizedBox(height: 16),

            // RPE
            _SectionCard(title: 'Esfuerzo percibido (RPE)', child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (i) {
                  final v = i + 1; final active = v == _rpe;
                  return GestureDetector(
                    onTap: () => setState(() => _rpe = v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: active ? AppColors.greenDim : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: active ? AppColors.green : AppColors.border, width: 0.5),
                      ),
                      child: Center(child: Text('$v', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: active ? AppColors.green : AppColors.textMuted))),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Muy fácil', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                Text('Máximo',   style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ]),
            ])),
            const SizedBox(height: 12),

            // Notas
            _SectionCard(title: 'Notas de sesión', child: TextField(
              controller: _notesCtrl, maxLines: 3,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cómo te has sentido, ajustes para la próxima...',
                border: InputBorder.none, enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero,
              ),
            )),
            const SizedBox(height: 24),

            SizedBox(width: double.infinity,
              child: ElevatedButton(onPressed: _finishSession, child: const Text('Finalizar sesión'))),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.elapsed, required this.totalSets, required this.totalVolume,
      required this.exercisesDone, required this.totalExercises});
  final String elapsed;
  final int totalSets, totalVolume, exercisesDone, totalExercises;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Piernas · Fuerza',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        Text(elapsed, style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 28,
            fontWeight: FontWeight.w600, color: AppColors.green)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _StatBox(label: 'Series',      value: '$totalSets',              color: AppColors.green)),
        const SizedBox(width: 8),
        Expanded(child: _StatBox(label: 'Volumen kg',  value: '$totalVolume',            color: AppColors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _StatBox(label: 'Ejercicios',  value: '$exercisesDone/$totalExercises', color: AppColors.purple)),
      ]),
    ]),
  );
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.color});
  final String label, value; final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.index, required this.onToggleSet});
  final _Exercise exercise; final int index; final void Function(int) onToggleSet;

  Color get _tagColor => switch (exercise.tag) {
    'Completado' => AppColors.green,
    'En curso'   => AppColors.amber,
    _            => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // ignore: deprecated_member_use
          color: exercise.tag == 'En curso' ? AppColors.amber.withOpacity(0.3) : AppColors.border,
          width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(exercise.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          // ignore: deprecated_member_use
          decoration: BoxDecoration(color: _tagColor.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
          child: Text(exercise.tag, style: TextStyle(fontSize: 10, color: _tagColor, fontWeight: FontWeight.w500))),
      ]),
      const SizedBox(height: 12),
      Row(children: exercise.sets.asMap().entries.map((e) {
        final si = e.key; final s = e.value;
        return Expanded(child: GestureDetector(
          onTap: () => onToggleSet(si),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: s.done ? AppColors.greenDim : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: s.done ? AppColors.greenBorder : AppColors.border, width: 0.5),
            ),
            child: Column(children: [
              Text('S${si+1}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Text(s.done && s.reps > 0 ? '${s.weight}×${s.reps}' : '—',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                    color: s.done ? AppColors.green : AppColors.textSecondary)),
            ]),
          ),
        ));
      }).toList()),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title; final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted,
          letterSpacing: 0.08, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      child,
    ]),
  );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      Text(value,  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]),
  );
}

class _Exercise {
  _Exercise({required this.name, required this.tag, required this.sets});
  final String name, tag;
  final List<_Set> sets;
}

class _Set {
  _Set({required this.reps, required this.weight, required this.done});
  final int reps, weight;
  bool done;
}
