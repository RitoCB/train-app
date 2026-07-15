import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color = AppColors.green,
    this.foreground = AppColors.background,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;
  final Color foreground;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 0.5),
          foregroundColor: color,
        ),
        child: _child(),
      );
    }
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
      ),
      child: _child(),
    );
  }

  Widget _child() => isLoading
      ? const SizedBox(
          height: 20, width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : Text(label);
}
