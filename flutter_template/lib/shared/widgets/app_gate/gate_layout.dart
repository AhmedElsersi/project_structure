// Shared full-screen layout for the maintenance and force-update views:
// centred icon, title, message and actions, readable width, scrollable.
//
// Source: baytna lib/features/config/presentation/widgets/app_gate.dart
//         (_GateScaffold: icon badge, headline, body, actions beneath).
// Merged: corsa-customer system_config_gate.dart (badge + result view, max
//         content width). Styles come from the theme only.
import 'package:flutter/material.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';

class GateLayout extends StatelessWidget {
  const GateLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.symmetric(horizontal: context.pageGutter, vertical: AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                        child: Icon(icon, size: AppSizes.iconLg, color: scheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  if (actions.isNotEmpty) ...[AppSpacing.gapXl, ...actions],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small spinner sized for use inside a button while it is busy.
class GateButtonProgress extends StatelessWidget {
  const GateButtonProgress({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppSizes.iconSm,
    child: CircularProgressIndicator(strokeWidth: AppSpacing.xxs, color: Theme.of(context).colorScheme.onPrimary),
  );
}
