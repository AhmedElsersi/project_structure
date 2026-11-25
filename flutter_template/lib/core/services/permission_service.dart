// Runtime permissions behind an app-level interface (status, request, open
// settings), so features and tests never touch permission_handler directly.
//
// Source: petrobe lib/features/home/presentation/services/permissions_service.dart
//         (status → request → permanently denied → settings; granted or
//         limited both count as usable; when-in-use location first).
// The UI flow (rationale and settings dialogs) lives in
// lib/shared/widgets/permissions/permission_flow.dart.
// See docs/SERVICES.md#permissions.
import 'package:permission_handler/permission_handler.dart';

/// Permissions the template knows about. Add more here and map them in
/// [PermissionHandlerService._map].
enum AppPermission { camera, photos, location, notifications, microphone }

enum AppPermissionStatus {
  granted,

  /// iOS limited photo library / provisional notifications: usable.
  limited,

  /// Not granted yet; asking again shows the system prompt.
  denied,

  /// The system will not prompt again; only Settings can change it.
  permanentlyDenied,

  /// Blocked by the OS (parental controls / MDM); the user cannot change it.
  restricted;

  bool get isUsable => this == granted || this == limited;
}

abstract interface class PermissionService {
  Future<AppPermissionStatus> status(AppPermission permission);

  /// Shows the system prompt when the OS allows it and returns the result.
  Future<AppPermissionStatus> request(AppPermission permission);

  /// Opens this app's page in the system settings. False when it couldn't.
  Future<bool> openSettings();
}

/// Production implementation on permission_handler. Platform setup (Info.plist
/// usage strings, AndroidManifest permissions, Podfile macros) is documented in
/// docs/SERVICES.md#permissions.
class PermissionHandlerService implements PermissionService {
  const PermissionHandlerService();

  @override
  Future<AppPermissionStatus> status(AppPermission permission) async {
    try {
      return _from(await _map(permission).status);
    } on Object {
      // Unsupported platform / missing manifest entry: treat as not granted.
      return AppPermissionStatus.denied;
    }
  }

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    try {
      return _from(await _map(permission).request());
    } on Object {
      return AppPermissionStatus.denied;
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } on Object {
      return false;
    }
  }

  static Permission _map(AppPermission permission) => switch (permission) {
    AppPermission.camera => Permission.camera,
    AppPermission.photos => Permission.photos,
    // When-in-use first: "always" can only be requested after it is granted.
    AppPermission.location => Permission.locationWhenInUse,
    AppPermission.notifications => Permission.notification,
    AppPermission.microphone => Permission.microphone,
  };

  static AppPermissionStatus _from(PermissionStatus status) => switch (status) {
    PermissionStatus.granted => AppPermissionStatus.granted,
    PermissionStatus.limited || PermissionStatus.provisional => AppPermissionStatus.limited,
    PermissionStatus.denied => AppPermissionStatus.denied,
    PermissionStatus.permanentlyDenied => AppPermissionStatus.permanentlyDenied,
    PermissionStatus.restricted => AppPermissionStatus.restricted,
  };
}
