// Slim app-wide banner at the top while offline, and a brief "back online"
// after recovery. Overlays the app instead of wrapping it, so the router and
// every screen below keep their state and never rebuild.
//
// Source: baytna lib/core/widgets/offline_banner.dart (one bar for the whole app
//         under the status bar, reassuring wording, cubit-driven).
// Merged: tebbr lib/core/utilities/widgets/no_internet/no_internet_gate.dart
//         (Stack over the router-driven app; the tree stays alive); "back
//         online" confirmation is new.
// See docs/WIDGETS.md#offline-banner.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/services/connectivity/connectivity_cubit.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

/// Requires a [ConnectivityCubit] above it (BlocProvider around MaterialApp).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child, this.backOnlineDuration = const Duration(seconds: 3)});

  final Widget child;

  /// How long "You're back online" stays after recovery.
  final Duration backOnlineDuration;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      PositionedDirectional(top: 0, start: 0, end: 0, child: _BannerHost(backOnlineDuration: backOnlineDuration)),
    ],
  );
}

enum _BannerKind { hidden, offline, backOnline }

class _BannerHost extends StatefulWidget {
  const _BannerHost({required this.backOnlineDuration});

  final Duration backOnlineDuration;

  @override
  State<_BannerHost> createState() => _BannerHostState();
}

class _BannerHostState extends State<_BannerHost> {
  late _BannerKind _kind;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _kind = context.read<ConnectivityCubit>().state.isOffline ? _BannerKind.offline : _BannerKind.hidden;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onStatus(ConnectivityStatus status) {
    _hideTimer?.cancel();
    if (status.isOffline) {
      setState(() => _kind = _BannerKind.offline);
      return;
    }
    if (_kind != _BannerKind.offline) return;
    setState(() => _kind = _BannerKind.backOnline);
    _hideTimer = Timer(widget.backOnlineDuration, () {
      if (mounted) setState(() => _kind = _BannerKind.hidden);
    });
  }

  @override
  Widget build(BuildContext context) => BlocListener<ConnectivityCubit, ConnectivityStatus>(
    listener: (_, status) => _onStatus(status),
    child: AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.medium),
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: AlignmentDirectional.topStart,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: switch (_kind) {
        _BannerKind.hidden => const SizedBox.shrink(key: ValueKey(_BannerKind.hidden)),
        _BannerKind.offline => const _Bar(key: ValueKey(_BannerKind.offline), offline: true),
        _BannerKind.backOnline => const _Bar(key: ValueKey(_BannerKind.backOnline), offline: false),
      },
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({super.key, required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final tone = context.palette.toneColors(offline ? StatusTone.warning : StatusTone.success);
    final text = offline ? LocaleKeys.states_offline.tr() : LocaleKeys.states_back_online.tr();
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: tone.container,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                  size: AppSizes.iconSm,
                  color: tone.onContainer,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: tone.onContainer),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
