import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent    = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
      );
      if (mounted) setState(() { _loading = false; _sent = true; });
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: _sent ? _successView() : _formView(),
        ),
      ),
    );
  }

  Widget _formView() => Form(
    key: _formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(color: AppColors.greenDim, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.greenBorder, width: 0.5)),
        child: const Icon(Icons.lock_outline_rounded, color: AppColors.green, size: 24)),
      const SizedBox(height: 20),
      const Text('Recuperar contraseña',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Introduce tu correo y te enviaremos un enlace para restablecer tu contraseña.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
      const SizedBox(height: 32),
      const Text('Correo electrónico',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _submit(),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(hintText: 'tu@correo.com'),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Introduce tu correo';
          if (!v.contains('@')) return 'Correo no válido';
          return null;
        },
      ),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
              : const Text('Enviar enlace de recuperación'),
        ),
      ),
    ]),
  );

  Widget _successView() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(color: AppColors.greenDim, shape: BoxShape.circle,
            border: Border.all(color: AppColors.greenBorder, width: 0.5)),
        child: const Icon(Icons.mark_email_read_outlined, color: AppColors.green, size: 32)),
      const SizedBox(height: 24),
      const Text('Correo enviado',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      const SizedBox(height: 10),
      Text('Hemos enviado un enlace a\n${_emailCtrl.text}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
          textAlign: TextAlign.center),
      const SizedBox(height: 36),
      SizedBox(width: double.infinity,
        child: ElevatedButton(onPressed: () => context.pop(), child: const Text('Volver al login'))),
    ],
  );
}
