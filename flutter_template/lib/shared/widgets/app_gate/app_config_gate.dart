// Sits in MaterialApp.builder, above the router: maintenance and force update
// replace the whole app (no deep link can get around them); an optional
// update shows a sheet once; the config refreshes on resume.
//
// Source: chinaparts-customer lib/features/app_config/presentation/widgets/
//         app_config_gate.dart (gate above the router, refreshIfStale on
//         resume, optional sheet hosted by the root navigator and delayed
//         until the splash has routed away).
// Merged: baytna lib/features/config/presentation/widgets/app_gate.dart
//         (post-frame prompt with bounded retries while the Navigator
//         attaches; server maintenance message per language wins);
//         corsa-customer system_config_gate.dart (426 / 503 from any request);
//         tebbr lib/main.dart _SystemConfigGate (refresh on resume).
// See docs/SERVICES.md#app-config.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_config/app_config_cubit.dart';
import '../../../core/app_config/update_policy.dart';
import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/router/app_routes.dart';
import '../feedback/app_snackbar.dart';
import 'force_update_view.dart';
import 'maintenance_view.dart';
import 'optional_update_sheet.dart';

/// Opens the store listing. Receives the config's store URL for this
/// platform (may be null — fall back to `AppEnv.storeUrl`). Returns whether
/// something opened.
typedef StoreOpener = Future<bool> Function(String? configStoreUrl);

/// Requires an [AppConfigCubit] above it (BlocProvider around MaterialApp).
///
/// ```dart
/// AppConfigGate(
///   onOpenStore: (url) => urlService.open(url ?? AppEnv.storeUrl),
///   child: child,
/// )
/// ```
class AppConfigGate extends StatefulWidget {
  const AppConfigGate({super.key, required this.child, this.onOpenStore, this.navigatorKey});

  final Widget child;

  /// Null hides the store buttons.
  final StoreOpener? onOpenStore;

  /// Navigator that hosts the optional sheet. Defaults to
  /// [AppRoutes.rootNavigatorKey].
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<AppConfigGate> createState() => _AppConfigGateState();
}

class _AppConfigGateState extends State<AppConfigGate> {
  static const int _maxNavigatorAttempts = 10;

  late final AppLifecycleListener _lifecycle;
  bool _promptScheduled = false;
  bool _promptShowing = false;
  VoidCallback? _routeListener;
  Listenable? _routeListenable;

  GlobalKey<NavigatorState> get _navigatorKey => widget.navigatorKey ?? AppRoutes.rootNavigatorKey;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(context.read<AppConfigCubit>().refreshIfStale()));
    // The cubit may already want the prompt (loaded before the gate mounted).
    if (context.read<AppConfigCubit>().state.shouldShowOptionalPrompt) _schedulePrompt();
  }

  @override
  void dispose() {
    _stopWaitingForRoute();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppConfigCubit, AppConfigState>(
    listenWhen: (previous, current) => !previous.shouldShowOptionalPrompt && current.shouldShowOptionalPrompt,
    listener: (_, _) => _schedulePrompt(),
    buildWhen: (previous, current) =>
        previous.decision != current.decision ||
        previous.message != current.message ||
        previous.isLoading != current.isLoading ||
        previous.config != current.config,
    builder: (context, state) => switch (state.decision) {
      GateDecision.maintenance => MaintenanceView(
        message: state.message ?? state.config?.maintenanceMessageFor(Localizations.localeOf(context).languageCode),
        isLoading: state.isLoading,
        onRetry: () => unawaited(context.read<AppConfigCubit>().load()),
      ),
      GateDecision.forceUpdate => ForceUpdateView(
        message: state.message,
        onUpdate: widget.onOpenStore == null ? null : () => unawaited(_openStore()),
      ),
      GateDecision.optionalUpdate || GateDecision.none => widget.child,
    },
  );

  Future<void> _openStore() async {
    final opener = widget.onOpenStore;
    if (opener == null) return;
    final opened = await opener(context.read<AppConfigCubit>().storeUrl);
    if (opened || !mounted) return;
    AppSnackBar.errorMessage(LocaleKeys.app_gate_store_unavailable.tr(), context: context);
  }

  /// Shows the optional sheet after the frame, through the root navigator,
  /// once that navigator exists and the splash has routed away (a sheet over
  /// the splash would be dropped by the splash's redirect).
  void _schedulePrompt([int attempt = 0]) {
    if (_promptScheduled || _promptShowing) return;
    _promptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptScheduled = false;
      if (!mounted || !context.read<AppConfigCubit>().state.shouldShowOptionalPrompt) return;

      final navContext = _navigatorKey.currentContext;
      if (navContext == null) {
        // The router builds its Navigator in this same frame on a cold start.
        if (attempt < _maxNavigatorAttempts) _schedulePrompt(attempt + 1);
        return;
      }
      final router = GoRouter.maybeOf(navContext);
      if (router != null && _isOnSplash(router)) {
        _waitForRouteChange(router);
        return;
      }
      unawaited(_showPrompt(navContext));
    });
  }

  bool _isOnSplash(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path == AppRoutes.splash;

  void _waitForRouteChange(GoRouter router) {
    if (_routeListener != null) return;
    void listener() {
      if (_isOnSplash(router)) return;
      _stopWaitingForRoute();
      _schedulePrompt();
    }

    _routeListenable = router.routerDelegate;
    _routeListener = listener;
    router.routerDelegate.addListener(listener);
  }

  void _stopWaitingForRoute() {
    final listener = _routeListener;
    if (listener != null) _routeListenable?.removeListener(listener);
    _routeListener = null;
    _routeListenable = null;
  }

  Future<void> _showPrompt(BuildContext navContext) async {
    _promptShowing = true;
    try {
      // Marked first: once per latest build, even if the app dies while open.
      await context.read<AppConfigCubit>().markOptionalPromptShown();
      if (!navContext.mounted) return;
      await OptionalUpdateSheet.show(
        navContext,
        onUpdate: widget.onOpenStore == null ? null : () => unawaited(_openStore()),
      );
    } finally {
      _promptShowing = false;
    }
  }
}
