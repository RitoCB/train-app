import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = Supabase.instance.client;
  String _section = 'perfil';

  bool _notifSession = true;
  bool _notifWeekly  = true;
  bool _notifPR      = true;
  bool _notifQuiet   = false;
  String _weightUnit = 'kg';
  String _distUnit   = 'km';

  String _name      = '';
  String _sport     = '';
  String _level     = '';
  String _freq      = '';
  double _weight    = 0;
  String? _avatarUrl;
  bool _uploadingAvatar = false;

  Box get _box => Hive.box(AppConstants.boxSettings);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _name   = _box.get('user_name',    defaultValue: 'Atleta') as String;
    _sport  = _box.get(AppConstants.keySportType, defaultValue: AppConstants.sportGym) as String;
    _level  = _box.get('level',        defaultValue: 'intermediate') as String;
    _freq   = _box.get('frequency',    defaultValue: '4') as String;
    _weight = (_box.get('user_weight', defaultValue: 0.0) as num).toDouble();

    try {
      final uid = _db.auth.currentUser?.id;
      if (uid != null) {
        final profile = await _db.from('profiles').select().eq('id', uid).single();
        if (mounted) {
          setState(() {
          _name      = profile['name']       as String? ?? _name;
          _weight    = (profile['weight_kg'] as num? ?? 0).toDouble();
          _avatarUrl = profile['avatar_url'] as String?;
        });
        }
      }
    } catch (_) {}
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

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final uid  = _db.auth.currentUser?.id;
      if (uid == null) return;
      final file = File(picked.path);
      final ext  = picked.path.split('.').last;
      final path = '$uid/avatar.$ext';

      await _db.storage.from('avatars').upload(
        path, file,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = _db.storage.from('avatars').getPublicUrl(path);
      await _db.from('profiles').update({'avatar_url': url}).eq('id', uid);

      if (mounted) setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al subir la foto: $e'),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _saveProfile(String newName, double newWeight) async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid != null) {
        await _db.from('profiles').update({
          'name': newName,
          'weight_kg': newWeight,
        }).eq('id', uid);
      }
      await _box.put('user_name',   newName);
      await _box.put('user_weight', newWeight);
      if (mounted) setState(() { _name = newName; _weight = newWeight; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Perfil actualizado'),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al guardar: $e'),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
      }
    }
  }

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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red, foregroundColor: Colors.white),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _db.auth.signOut();
      await _box.put(AppConstants.keyOnboardingDone, false);
      if (mounted) context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // TopBar
          Container(
            height: 60,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Expanded(child: Text('Ajustes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary))),
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: _avatarWidget(radius: 16, fontSize: 12),
              ),
            ]),
          ),
          const Divider(height: 0.5, color: AppColors.border),

          Expanded(
            child: Row(children: [
              // Menú lateral
              _SideMenu(
                selected:   _section,
                name:       _name,
                initials:   _initials,
                sportLabel: _sportLabel,
                avatarUrl:  _avatarUrl,
                onSelect:   (s) => setState(() => _section = s),
                onLogout:   _logout,
                onAvatarTap: _pickAndUploadAvatar,
              ),
              const VerticalDivider(width: 0.5, color: AppColors.border),

              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: switch (_section) {
                    'notificaciones' => _NotifSection(
                      session: _notifSession, onSession: (v) => setState(() => _notifSession = v),
                      weekly:  _notifWeekly,  onWeekly:  (v) => setState(() => _notifWeekly  = v),
                      pr:      _notifPR,       onPR:      (v) => setState(() => _notifPR      = v),
                      quiet:   _notifQuiet,    onQuiet:   (v) => setState(() => _notifQuiet   = v),
                    ),
                    'unidades' => _UnitsSection(
                      weightUnit: _weightUnit, onWeight: (v) => setState(() => _weightUnit = v),
                      distUnit:   _distUnit,   onDist:   (v) => setState(() => _distUnit   = v),
                    ),
                    'privacidad' => const _PrivacySection(),
                    _ => _ProfileContent(
                      name:           _name,
                      weight:         _weight,
                      sportLabel:     _sportLabel,
                      levelLabel:     _levelLabel,
                      freq:           _freq,
                      avatarUrl:      _avatarUrl,
                      uploading:      _uploadingAvatar,
                      onUploadAvatar: _pickAndUploadAvatar,
                      onSave:         _saveProfile,
                      onEditSport:    () => context.push(AppRoutes.sportSelection),
                    ),
                  },
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _avatarWidget({required double radius, required double fontSize}) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.green,
          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
          child: _avatarUrl == null
              ? Text(_initials, style: TextStyle(fontSize: fontSize,
                  fontWeight: FontWeight.w700, color: AppColors.background))
              : null,
        ),
        if (_uploadingAvatar)
          const Positioned.fill(child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.green)),
      ],
    );
  }
}

// ── Side Menu ─────────────────────────────────────────────────────

class _SideMenu extends StatelessWidget {
  const _SideMenu({
    required this.selected,    required this.name,
    required this.initials,    required this.sportLabel,
    required this.avatarUrl,   required this.onSelect,
    required this.onLogout,    required this.onAvatarTap,
  });

  final String selected, name, initials, sportLabel;
  final String? avatarUrl;
  final void Function(String) onSelect;
  final VoidCallback onLogout, onAvatarTap;

  static const _items = [
    ('perfil',         'Perfil deportivo', Icons.person_outline_rounded),
    ('notificaciones', 'Notificaciones',   Icons.notifications_none_rounded),
    ('privacidad',     'Privacidad',       Icons.lock_outline_rounded),
    ('unidades',       'Unidades',         Icons.straighten_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(children: [
        // Avatar en el menú lateral
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.green,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(initials, style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w700, color: AppColors.background))
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(sportLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        const Divider(height: 0.5, color: AppColors.border),

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
                      Expanded(child: Text(item.$2, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: on ? AppColors.green : AppColors.textSecondary))),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const Divider(height: 0.5, color: AppColors.border),
        GestureDetector(
          onTap: onLogout,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.logout_rounded, size: 16, color: AppColors.red),
              SizedBox(width: 8),
              Text('Cerrar sesión', style: TextStyle(fontSize: 12,
                  color: AppColors.red, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Perfil editable ───────────────────────────────────────────────

class _ProfileContent extends StatefulWidget {
  const _ProfileContent({
    required this.name,        required this.weight,
    required this.sportLabel,  required this.levelLabel,
    required this.freq,        required this.avatarUrl,
    required this.uploading,   required this.onUploadAvatar,
    required this.onSave,      required this.onEditSport,
  });

  final String name, sportLabel, levelLabel, freq;
  final double weight;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback onUploadAvatar, onEditSport;
  final Future<void> Function(String name, double weight) onSave;

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _weightCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.name);
    _weightCtrl = TextEditingController(
        text: widget.weight > 0 ? '${widget.weight}' : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Avatar grande — toda el área es táctil
      Center(
        child: GestureDetector(
          onTap: widget.onUploadAvatar,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 100, height: 100,
            child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.green,
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!) : null,
                child: widget.avatarUrl == null
                    ? Text(
                        widget.name.isNotEmpty
                            ? widget.name[0].toUpperCase() : 'A',
                        style: const TextStyle(fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.background))
                    : null,
              ),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.green, shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: widget.uploading
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: AppColors.background))
                    : const Icon(Icons.camera_alt_rounded, size: 16,
                        color: AppColors.background),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Center(child: Text('Pulsa para cambiar la foto',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
      const SizedBox(height: 24),

      // Campos editables
      _sectionTitle('Datos personales'),
      _label('Nombre'),
      const SizedBox(height: 6),
      TextField(
        controller: _nameCtrl,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(hintText: 'Tu nombre'),
      ),
      const SizedBox(height: 16),
      _label('Peso actual'),
      const SizedBox(height: 6),
      TextField(
        controller: _weightCtrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: '80',
          suffixText: 'kg',
          suffixStyle: TextStyle(color: AppColors.textMuted),
        ),
      ),
      const SizedBox(height: 24),

      _sectionTitle('Perfil deportivo'),
      _SettingRow(label: 'Deporte principal',    value: widget.sportLabel, onTap: widget.onEditSport),
      _SettingRow(label: 'Frecuencia semanal',   value: '${widget.freq} días / semana'),
      _SettingRow(label: 'Nivel de experiencia', value: widget.levelLabel),
      const SizedBox(height: 24),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saving ? null : () async {
            setState(() => _saving = true);
            final w = double.tryParse(
                _weightCtrl.text.replaceAll(',', '.')) ?? widget.weight;
            await widget.onSave(_nameCtrl.text.trim(), w);
            if (mounted) setState(() => _saving = false);
          },
          child: _saving
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      color: AppColors.background))
              : const Text('Guardar cambios'),
        ),
      ),
      const SizedBox(height: 24),

      _sectionTitle('Integraciones'),
      const _SettingRow(label: 'Apple Health', value: 'No conectado', valueColor: AppColors.textMuted),
      const _SettingRow(label: 'Google Fit',   value: 'No conectado', valueColor: AppColors.textMuted),
      const _SettingRow(label: 'Strava',       value: 'No conectado', valueColor: AppColors.textMuted),
    ]);
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11,
        fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.08)),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary));
}

// ── Secciones ─────────────────────────────────────────────────────

class _NotifSection extends StatelessWidget {
  const _NotifSection({
    required this.session, required this.onSession,
    required this.weekly,  required this.onWeekly,
    required this.pr,      required this.onPR,
    required this.quiet,   required this.onQuiet,
  });
  final bool session, weekly, pr, quiet;
  final ValueChanged<bool> onSession, onWeekly, onPR, onQuiet;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _SectionTitle('Notificaciones'),
    _ToggleRow(label: 'Recordatorio de sesión', sub: '30 min antes del entreno', value: session, onChanged: onSession),
    _ToggleRow(label: 'Resumen semanal',         sub: 'Cada domingo a las 20:00', value: weekly,  onChanged: onWeekly),
    _ToggleRow(label: 'Nuevos récords',          sub: 'Alerta cuando superes un PR', value: pr,   onChanged: onPR),
    _ToggleRow(label: 'Modo no molestar',        sub: 'Silenciar de 23:00 a 08:00', value: quiet, onChanged: onQuiet),
  ]);
}

class _UnitsSection extends StatelessWidget {
  const _UnitsSection({
    required this.weightUnit, required this.onWeight,
    required this.distUnit,   required this.onDist,
  });
  final String weightUnit, distUnit;
  final ValueChanged<String> onWeight, onDist;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _SectionTitle('Unidades de medida'),
    const SizedBox(height: 4),
    _SegmentRow(label: 'Sistema de peso', options: const ['kg', 'lb'], selected: weightUnit, onSelect: onWeight),
    const SizedBox(height: 16),
    _SegmentRow(label: 'Distancia',       options: const ['km', 'mi'], selected: distUnit,   onSelect: onDist),
  ]);
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _SectionTitle('Privacidad y datos'),
    _SettingRow(label: 'Exportar mis datos', value: 'JSON / CSV', onTap: () {}),
    _SettingRow(label: 'Eliminar historial', value: '', valueColor: AppColors.red, onTap: () {}),
    _SettingRow(label: 'Eliminar cuenta',    value: '', valueColor: AppColors.red, onTap: () {}),
    const SizedBox(height: 24),
    const _SectionTitle('Acerca de'),
    const _SettingRow(label: 'Versión', value: '1.0.0'),
    _SettingRow(label: 'Términos de uso',        value: '', onTap: () {}),
    _SettingRow(label: 'Política de privacidad', value: '', onTap: () {}),
  ]);
}

// ── Componentes comunes ───────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11,
        fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.08)),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value, this.onTap, this.valueColor});
  final String label, value;
  final VoidCallback? onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
        if (value.isNotEmpty)
          Text(value, style: TextStyle(fontSize: 12, color: valueColor ?? AppColors.textMuted)),
        if (onTap != null)
          const Padding(padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted)),
      ]),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.sub, required this.value, required this.onChanged});
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ])),
      GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40, height: 22,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: value ? AppColors.green : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(11)),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 16, height: 16,
              decoration: BoxDecoration(
                  color: value ? AppColors.background : AppColors.textMuted,
                  shape: BoxShape.circle)),
        ),
      ),
    ]),
  );
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({required this.label, required this.options,
      required this.selected, required this.onSelect});
  final String label, selected;
  final List<String> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary)),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
      child: Row(children: options.map((o) {
        final on = o == selected;
        return Expanded(child: GestureDetector(
          onTap: () => onSelect(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
                color: on ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text(o, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w500,
                color: on ? AppColors.textPrimary : AppColors.textMuted))),
          ),
        ));
      }).toList()),
    ),
  ]);
}
