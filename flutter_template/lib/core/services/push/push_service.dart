// Push notifications behind an interface; the template ships a no-op. Firebase
// Messaging is an opt-in module (docs/SERVICES.md#push has the recipe).
//
// Source: chinaparts-seller lib/core/services/push_notification_service.dart
//         (init, permission, token refresh, opened-message stream, the message
//         that cold-started the app), reduced to a plugin-free contract.
// Approved decision C7: Firebase is opt-in; the template builds and tests with
// zero accounts. Rejected: static NotificationService with a fresh plugin per
// call (brgr, tebbr, instaops — decision D14).
// See docs/SERVICES.md#push.

abstract interface class PushService {
  /// Sets up channels / handlers. Safe to call more than once.
  Future<void> init();

  /// Shows the OS prompt when allowed. True when notifications may be shown.
  Future<bool> requestPermission();

  /// Device token now and on every refresh; null after sign-out / deletion.
  /// Register it with the backend only while there is a session.
  Stream<String?> get tokenStream;

  /// Data payloads of notifications the user TAPPED while the app was running
  /// or in the background. Resolve them with `NotificationLinkResolver`.
  Stream<Map<String, dynamic>> get onMessageOpened;

  /// The payload of the notification that cold-started the app, if any.
  /// Hold it in `PendingLink` until the router and session are ready.
  Future<Map<String, dynamic>?> initialMessage();
}

/// Default implementation: no plugin, no prompts, no messages.
class NoopPushService implements PushService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Stream<String?> get tokenStream => const Stream<String?>.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpened => const Stream<Map<String, dynamic>>.empty();

  @override
  Future<Map<String, dynamic>?> initialMessage() async => null;
}
