import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Scaffold base para pantallas con AppBar estándar de TrainApp.
/// Para pantallas del shell (con bottom nav) no hace falta usarlo —
/// el ShellRoute ya provee el Scaffold exterior.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.showAppBar = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showAppBar;
  final EdgeInsets padding;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              leading: leading,
              actions: actions,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(0.5),
                child: Divider(height: 0.5, color: AppColors.border),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: body,
        ),
      ),
    );
  }
}
