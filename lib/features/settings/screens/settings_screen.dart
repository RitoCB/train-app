import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Sección activa del menú lateral
  String _section = 'perfil';

  // Notificaciones
  bool _notifSession  = true;
  bool _notifWeekly   = true;
  bool _notifPR       = true;
  bool _notifQuiet    = false;

  // Unidades
  String _weightUnit = 'kg';
  String _distUnit   = 'km';

  late final Box _box;
  String _name   = '';
  String _sport  = '';
  String _level  = '';
  String _freq   = '';
  double _weight = 0;

  @override
  void initState() {
    super.initState();
    _box    = Hive.box(AppConstants.boxSettings);
    _name   = _box.get('user_name',    defaultValue: 'Atleta') as String;
    _sport  = _box.get(AppConstants.keySportType, defaultValue: AppConstants.sportGym) as String;
    _level  = _box.get('level',        defaultValue: 'intermediate') as String;
    _freq   = _box.get('frequency',    defaultValue: '4') as String;
    _weight = (_box.get('user_weight', defaultValue: 0.0) as num).toDouble();
  }

  String get _sportLabel => switch (_sport) {
    AppConstants.sportGym       => 'Gym · Fuerza',
    AppConstants.sportMartial   => 'Artes Marciales',
    AppConstants.sportEndurance => 'Resistencia',
    _                           => 'Personalizado',
  };

  String get _levelLabel => switch (_level) {
    'beginner' => 'Principiante',
    'advanced' => 'Avanzado',
    _          => 'Intermedio',
  };

  String get _initials => _name.isNotEmpty ? _name[0].toUpperCase() : 'A';

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
        content: const Text('¿Seguro que quieres cerrar sesión?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _box.put(AppConstants.keyOnboardingDone, false);
      // ignore: use_build_context_synchronously
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              height: 60,
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Ajustes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.green,
                    child: Text(_initials,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.background)),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.5, color: AppColors.border),

            Expanded(
              child: Row(
                children: [
                  // Menú lateral
                  _SideMenu(
                    selected: _section,
                    name: _name,
                    initials: _initials,
                    sportLabel: _sportLabel,
                    onSelect: (s) => setState(() => _section = s),
                    onLogout: _logout,
                  ),
                  const VerticalDivider(width: 0.5, color: AppColors.border),

                  // Contenido
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: switch (_section) {
                        'notificaciones' => _NotifSection(
                          session: _notifSession,  onSession:  (v) => setState(() => _notifSession  = v),
                          weekly:  _notifWeekly,   onWeekly:   (v) => setState(() => _notifWeekly   = v),
                          pr:      _notifPR,        onPR:       (v) => setState(() => _notifPR       = v),
                          quiet:   _notifQuiet,     onQuiet:    (v) => setState(() => _notifQuiet    = v),
                        ),
                        'unidades' => _UnitsSection(
                          weightUnit: _weightUnit, onWeight: (v) => setState(() => _weightUnit = v),
                          distUnit:   _distUnit,   onDist:   (v) => setState(() => _distUnit   = v),
                        ),
                        'privacidad' => const _PrivacySection(),
                        _ => _ProfileSection(
                          sportLabel:  _sportLabel,
                          levelLabel:  _levelLabel,
                          freq:        _freq,
                          weight:      _weight,
                          onEditSport: () => context.push(AppRoutes.sportSelection),
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// MENÚ LATERAL
// ════════════════════════════════════════════════════════════════

class _SideMenu extends StatelessWidget {
  const _SideMenu({
    required this.selected, required this.name, required this.initials,
    required this.sportLabel, required this.onSelect, required this.onLogout,
  });

  final String selected, name, initials, sportLabel;
  final void Function(String) onSelect;
  final VoidCallback onLogout;

  static const _items = [
    ('perfil',           'Perfil deportivo',  Icons.person_outline_rounded),
    ('notificaciones',   'Notificaciones',    Icons.notifications_none_rounded),
    ('privacidad',       'Privacidad',        Icons.lock_outline_rounded),
    ('unidades',         'Unidades',          Icons.straighten_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.green,
                child: Text(initials,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.background)),
              ),
              const SizedBox(height: 8),
              Text(name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(sportLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const Divider(height: 0.5, color: AppColors.border),

          // Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                children: _items.map((item) {
                  final on = selected == item.$1;
                  return GestureDetector(
                    onTap: () => onSelect(item.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: on ? AppColors.greenDim : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(item.$3, size: 16,
                            color: on ? AppColors.green : AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.$2,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                  color: on ? AppColors.green : AppColors.textSecondary)),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 0.5, color: AppColors.border),
          // Cerrar sesión
          GestureDetector(
            onTap: onLogout,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.logout_rounded, size: 16, color: AppColors.red),
                SizedBox(width: 8),
                Text('Cerrar sesión', style: TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SECCIONES DE CONTENIDO
// ════════════════════════════════════════════════════════════════

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.sportLabel, required this.levelLabel,
    required this.freq, required this.weight, required this.onEditSport,
  });
  final String sportLabel, levelLabel, freq;
  final double weight;
  final VoidCallback onEditSport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Perfil deportivo'),
        _SettingRow(label: 'Deporte principal', value: sportLabel, onTap: onEditSport),
        _SettingRow(label: 'Frecuencia semanal', value: '$freq días por semana'),
        _SettingRow(label: 'Peso corporal', value: weight > 0 ? '$weight kg' : '—'),
        _SettingRow(label: 'Nivel de experiencia', value: levelLabel),
        const SizedBox(height: 24),
        const _SectionTitle('Integraciones'),
        const _SettingRow(label: 'Apple Health', value: 'No conectado', valueColor: AppColors.textMuted),
        const _SettingRow(label: 'Google Fit',  value: 'No conectado', valueColor: AppColors.textMuted),
        const _SettingRow(label: 'Strava',      value: 'No conectado', valueColor: AppColors.textMuted),
      ],
    );
  }
}

class _NotifSection extends StatelessWidget {
  const _NotifSection({
    required this.session,  required this.onSession,
    required this.weekly,   required this.onWeekly,
    required this.pr,       required this.onPR,
    required this.quiet,    required this.onQuiet,
  });
  final bool session, weekly, pr, quiet;
  final ValueChanged<bool> onSession, onWeekly, onPR, onQuiet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Notificaciones'),
        _ToggleRow(label: 'Recordatorio de sesión', sub: '30 min antes del entreno',
            value: session, onChanged: onSession),
        _ToggleRow(label: 'Resumen semanal', sub: 'Cada domingo a las 20:00',
            value: weekly, onChanged: onWeekly),
        _ToggleRow(label: 'Nuevos récords', sub: 'Alerta cuando superes un PR',
            value: pr, onChanged: onPR),
        _ToggleRow(label: 'Modo no molestar', sub: 'Silenciar de 23:00 a 08:00',
            value: quiet, onChanged: onQuiet),
      ],
    );
  }
}

class _UnitsSection extends StatelessWidget {
  const _UnitsSection({
    required this.weightUnit, required this.onWeight,
    required this.distUnit,   required this.onDist,
  });
  final String weightUnit, distUnit;
  final ValueChanged<String> onWeight, onDist;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Unidades de medida'),
        const SizedBox(height: 4),
        _SegmentRow(
          label: 'Sistema de peso',
          options: const ['kg', 'lb'],
          selected: weightUnit,
          onSelect: onWeight,
        ),
        const SizedBox(height: 16),
        _SegmentRow(
          label: 'Distancia',
          options: const ['km', 'mi'],
          selected: distUnit,
          onSelect: onDist,
        ),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Privacidad y datos'),
        _SettingRow(label: 'Exportar mis datos', value: 'JSON / CSV', onTap: () {}),
        _SettingRow(label: 'Eliminar historial', value: '', valueColor: AppColors.red, onTap: () {}),
        _SettingRow(label: 'Eliminar cuenta',    value: '', valueColor: AppColors.red, onTap: () {}),
        const SizedBox(height: 24),
        const _SectionTitle('Acerca de'),
        const _SettingRow(label: 'Versión', value: '1.0.0'),
        _SettingRow(label: 'Términos de uso', value: '', onTap: () {}),
        _SettingRow(label: 'Política de privacidad', value: '', onTap: () {}),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// COMPONENTES REUTILIZABLES
// ════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.textMuted, letterSpacing: 0.08)),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value, this.onTap, this.valueColor});
  final String label, value;
  final VoidCallback? onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
          if (value.isNotEmpty)
            Text(value,
                style: TextStyle(fontSize: 12, color: valueColor ?? AppColors.textMuted)),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
            ),
        ]),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.sub, required this.value, required this.onChanged});
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        )),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 22,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? AppColors.green : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: value ? AppColors.background : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({required this.label, required this.options, required this.selected, required this.onSelect});
  final String label, selected;
  final List<String> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: options.map((o) {
              final on = o == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(o),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: on ? AppColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(o, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: on ? AppColors.textPrimary : AppColors.textMuted,
                      )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
