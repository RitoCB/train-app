import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go(AppRoutes.dashboard);
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Error al iniciar sesión. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Iniciar sesión',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Accede a tu cuenta TrainApp',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 36),

              const _FieldLabel('Correo electrónico'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(hintText: 'tu@correo.com'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Introduce tu correo';
                  if (!v.contains('@')) return 'Correo no válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const _FieldLabel('Contraseña'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18, color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Introduce tu contraseña';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(foregroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                      : const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 28),
              const _DividerRow(label: 'o continúa con'),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _OAuthButton(label: 'Google', icon: Icons.g_mobiledata_rounded, onPressed: () {})),
                const SizedBox(width: 12),
                Expanded(child: _OAuthButton(label: 'Apple', icon: Icons.apple, onPressed: () {})),
              ]),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('¿Sin cuenta? ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => context.pushReplacement(AppRoutes.register),
                  child: const Text('Regístrate gratis',
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
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary));
}

class _DividerRow extends StatelessWidget {
  const _DividerRow({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider(color: AppColors.border)),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
    const Expanded(child: Divider(color: AppColors.border)),
  ]);
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({required this.label, required this.icon, required this.onPressed});
  final String label; final IconData icon; final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 20, color: AppColors.textSecondary),
    label: Text(label),
    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48),
        side: const BorderSide(color: AppColors.border, width: 0.5),
        foregroundColor: AppColors.textSecondary),
  );
}
