import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.sport});
  final String sport;
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _ageCtrl    = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _loading = false;

  final Set<String> _tracking = {'weights', 'body'};
  String _frequency = '4';
  String _level     = 'intermediate';

  static const _trackingOptions = [
    _Chip(id: 'weights',   label: 'Pesos levantados'),
    _Chip(id: 'body',      label: 'Peso corporal'),
    _Chip(id: 'nutrition', label: 'Nutrición'),
    _Chip(id: 'sleep',     label: 'Sueño'),
    _Chip(id: 'cardio',    label: 'Cardio'),
  ];
  static const _freqOptions  = ['2', '3', '4', '5+'];
  static const _levelOptions = [
    _Chip(id: 'beginner',     label: 'Principiante'),
    _Chip(id: 'intermediate', label: 'Intermedio'),
    _Chip(id: 'advanced',     label: 'Avanzado'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose();
    _weightCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final name   = _nameCtrl.text.trim();
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final height = int.tryParse(_heightCtrl.text) ?? 0;

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id':        uid,
          'name':      name,
          'sport':     widget.sport,
          'level':     _level,
          'frequency': _frequency,
          'weight_kg': weight,
          'height_cm': height,
        });
      }

      // Guardar también en Hive para acceso offline
      final box = Hive.box(AppConstants.boxSettings);
      await box.put(AppConstants.keySportType, widget.sport);
      await box.put('user_name',   name);
      await box.put('user_weight', weight);
      await box.put('user_height', height);
      await box.put('tracking',    _tracking.toList());
      await box.put('frequency',   _frequency);
      await box.put('level',       _level);

      if (mounted) context.pushReplacement(AppRoutes.profileSuccess);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al guardar el perfil: $e'),
        backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
      ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop())),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(borderRadius: BorderRadius.circular(99),
              child: const LinearProgressIndicator(value: 0.66, minHeight: 4,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation(AppColors.green))),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Configura tu perfil',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Usaremos estos datos para personalizar tus métricas',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 28),

                  Row(children: [
                    Expanded(child: _buildField('Nombre',       _nameCtrl,   'Alex', TextInputType.name)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('Edad',         _ageCtrl,    '28',   TextInputType.number, suffix: 'años', maxLen: 3)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _buildField('Peso actual',  _weightCtrl, '82',   TextInputType.number, suffix: 'kg')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('Estatura',     _heightCtrl, '178',  TextInputType.number, suffix: 'cm', maxLen: 3)),
                  ]),
                  const SizedBox(height: 24),

                  _secTitle('¿Qué deseas rastrear?'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8,
                    children: _trackingOptions.map((c) {
                      final on = _tracking.contains(c.id);
                      return _ChipBtn(label: c.label, selected: on,
                          onTap: () => setState(() => on ? _tracking.remove(c.id) : _tracking.add(c.id)));
                    }).toList()),
                  const SizedBox(height: 24),

                  _secTitle('Frecuencia semanal'),
                  const SizedBox(height: 10),
                  Row(children: _freqOptions.map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ChipBtn(label: '$f días', selected: _frequency == f,
                        onTap: () => setState(() => _frequency = f)),
                  )).toList()),
                  const SizedBox(height: 24),

                  _secTitle('Nivel de experiencia'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8,
                    children: _levelOptions.map((c) => _ChipBtn(
                      label: c.label, selected: _level == c.id,
                      onTap: () => setState(() => _level = c.id),
                    )).toList()),
                  const SizedBox(height: 32),

                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                          : const Text('Crear perfil'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _secTitle(String t) => Text(t, style: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.08));

  Widget _buildField(String label, TextEditingController ctrl, String hint, TextInputType type,
      {String? suffix, int? maxLen}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl, keyboardType: type, maxLength: maxLen,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(hintText: hint, counterText: '',
              suffixText: suffix, suffixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
        ),
      ]);
}

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({required this.label, required this.selected, required this.onTap});
  final String label; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.greenDim : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.greenBorder : AppColors.borderStrong, width: 0.5),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: selected ? AppColors.green : AppColors.textSecondary)),
    ),
  );
}

class _Chip {
  const _Chip({required this.id, required this.label});
  final String id, label;
}
