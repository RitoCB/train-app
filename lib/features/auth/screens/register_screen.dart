import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _acceptTerms    = false;
  bool _loading        = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _surnameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes aceptar los términos de uso'),
        backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        data: {
          'name': '${_nameCtrl.text.trim()} ${_surnameCtrl.text.trim()}'.trim(),
        },
      );
      if (mounted) context.go(AppRoutes.sportSelection);
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Error al crear la cuenta. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
  ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Crear cuenta',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Empieza a registrar tus entrenamientos',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              Row(children: [
                Expanded(child: _field('Nombre',   _nameCtrl,    'Alex',  TextInputAction.next)),
                const SizedBox(width: 12),
                Expanded(child: _field('Apellido', _surnameCtrl, 'López', TextInputAction.next)),
              ]),
              const SizedBox(height: 14),
              _label('Correo electrónico'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(hintText: 'tu@correo.com'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Introduce tu correo';
                  if (!v.contains('@')) return 'Correo no válido';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _label('Contraseña'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl, obscureText: _obscurePass,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(hintText: '••••••••',
                    suffixIcon: _eyeIcon(_obscurePass, () => setState(() => _obscurePass = !_obscurePass))),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Introduce una contraseña';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _label('Confirmar contraseña'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmCtrl, obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _submit(),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(hintText: '••••••••',
                    suffixIcon: _eyeIcon(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm))),
                validator: (v) => v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 18),

              GestureDetector(
                onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _acceptTerms ? AppColors.greenDim : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _acceptTerms ? AppColors.green : AppColors.borderStrong, width: 0.5),
                      ),
                      child: _acceptTerms ? const Icon(Icons.check, size: 13, color: AppColors.green) : null,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text(
                      'Acepto los Términos de uso y la Política de privacidad',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                    )),
                  ]),
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                      : const Text('Crear cuenta'),
                ),
              ),
              const SizedBox(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('¿Ya tienes cuenta? ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => context.pushReplacement(AppRoutes.login),
                  child: const Text('Inicia sesión',
                      style: TextStyle(fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, TextInputAction action) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label), const SizedBox(height: 6),
        TextFormField(controller: ctrl, textInputAction: action,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(hintText: hint),
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
      ]);

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary));

  Widget _eyeIcon(bool obs, VoidCallback onTap) => IconButton(
      icon: Icon(obs ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 18, color: AppColors.textMuted),
      onPressed: onTap);
}
