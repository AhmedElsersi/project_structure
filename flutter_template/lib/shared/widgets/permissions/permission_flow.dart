// The permission UX in one call: granted → go; otherwise explain (rationale)
// → system prompt → if permanently denied, offer Settings → re-check when the
// user comes back.
//
// Source: petrobe lib/features/home/presentation/services/permissions_service.dart
//         (ensureAttendancePermissions: rationale before the request,
//         permanently-denied dialog that opens Settings, final re-check).
// Merged: chinaparts-seller lib/core/services/notification_permission_gate.dart
//         (the Settings prompt is throttled — see [SettingsPromptThrottle] —
//         so an automatic check never nags after every resume). Rejected: the
//         house-style permisssions_helper.dart with swapped Settings buttons.
// See docs/SERVICES.md#permissions.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/services/permission_service.dart';

/// Translated labels for the built-in permissions.
extension AppPermissionText on AppPermission {
  /// Short name: "Camera", "الكاميرا".
  String get label => switch (this) {
    AppPermission.camera => LocaleKeys.permissions_camera.tr(),
    AppPermission.photos => LocaleKeys.permissions_photos.tr(),
    AppPermission.location => LocaleKeys.permissions_location.tr(),
    AppPermission.notifications => LocaleKeys.permissions_notifications.tr(),
    AppPermission.microphone => LocaleKeys.permissions_microphone.tr(),
  };

  /// Default rationale title: "Allow access to Camera".
  String get rationaleTitle => LocaleKeys.permissions_rationale_title.tr(namedArgs: {'permission': label});

  /// Default rationale message (replace with a feature-specific one when you can).
  String get rationaleMessage => switch (this) {
    AppPermission.camera => LocaleKeys.permissions_camera_rationale.tr(),
    AppPermission.photos => LocaleKeys.permissions_photos_rationale.tr(),
    AppPermission.location => LocaleKeys.permissions_location_rationale.tr(),
    AppPermission.notifications => LocaleKeys.permissions_notifications_rationale.tr(),
    AppPermission.microphone => LocaleKeys.permissions_microphone_rationale.tr(),
  };
}

/// Limits how often the "open Settings" dialog may appear per permission
/// (in memory, per app run). Pass one to [ensurePermission] for checks that
/// run automatically (on resume, on a tab switch); leave it out for checks the
/// user started with a tap.
class SettingsPromptThrottle {
  SettingsPromptThrottle({this.interval = const Duration(days: 1), DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final Duration interval;
  final DateTime Function() _now;
  final Map<AppPermission, DateTime> _shownAt = {};

  bool isDue(AppPermission permission) {
    final last = _shownAt[permission];
    return last == null || _now().difference(last) >= interval;
  }

  void markShown(AppPermission permission) => _shownAt[permission] = _now();
}

/// Returns true when [permission] is usable (granted or limited).
///
/// ```dart
/// final ok = await ensurePermission(
///   context, AppPermission.camera, getIt<PermissionService>(),
///   rationaleTitle: AppPermission.camera.rationaleTitle,
///   rationaleMessage: LocaleKeys.profile_camera_reason.tr(),
/// );
/// ```
Future<bool> ensurePermission(
  BuildContext context,
  AppPermission permission,
  PermissionService service, {
  required String rationaleTitle,
  required String rationaleMessage,
  SettingsPromptThrottle? throttle,
  Duration settingsReturnTimeout = const Duration(minutes: 5),
}) async {
  var status = await service.status(permission);
  if (status.isUsable) return true;
  if (status == AppPermissionStatus.restricted) return false;

  if (status == AppPermissionStatus.denied) {
    if (!context.mounted) return false;
    final proceed = await _showRationale(context, title: rationaleTitle, message: rationaleMessage);
    if (!proceed) return false;
    status = await service.request(permission);
    if (status.isUsable) return true;
    // Denied again but still askable: respect the answer for now.
    if (status != AppPermissionStatus.permanentlyDenied) return false;
  }

  // Permanently denied: only the Settings app can change it.
  if (throttle != null && !throttle.isDue(permission)) return false;
  if (!context.mounted) return false;
  throttle?.markShown(permission);
  final openSettings = await _showSettingsPrompt(context, permission);
  if (!openSettings) return false;

  final comeBack = _ResumeWaiter();
  try {
    if (await service.openSettings()) await comeBack.wait(settingsReturnTimeout);
  } finally {
    comeBack.dispose();
  }
  return (await service.status(permission)).isUsable;
}

Future<bool> _showRationale(BuildContext context, {required String title, required String message}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(LocaleKeys.permissions_not_now.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(LocaleKeys.permissions_continue.tr()),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> _showSettingsPrompt(BuildContext context, AppPermission permission) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(LocaleKeys.permissions_settings_title.tr()),
      content: Text(LocaleKeys.permissions_settings_message.tr(namedArgs: {'permission': permission.label})),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(LocaleKeys.permissions_not_now.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(LocaleKeys.permissions_open_settings.tr()),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Completes when the app returns to the foreground (after Settings).
class _ResumeWaiter {
  _ResumeWaiter() {
    _listener = AppLifecycleListener(
      onResume: () {
        if (!_resumed.isCompleted) _resumed.complete();
      },
    );
  }

  late final AppLifecycleListener _listener;
  final Completer<void> _resumed = Completer<void>();

  Future<void> wait(Duration timeout) => _resumed.future.timeout(timeout, onTimeout: () {});

  void dispose() => _listener.dispose();
}
