// Maps a notification payload to a go_router location (pure), and holds a
// cold-start link until the session/router can take it (flushed once).
//
// Source: chinaparts-customer lib/core/services/notification_link_handler.dart
//         (pure payload → destination function, unit-testable; unknown or
//         incomplete payloads fall back instead of crashing).
// Merged: chinaparts-seller push_notification_service.dart (pending link held
//         until there is a session, retried on router changes);
//         markspulse lib/domain/notifications/pending_deep_link.dart (hold a
//         ROUTE, newest tap wins, released at most once, cleared on sign-out).
// Core never imports features: each feature registers its own builder from
// its `<feature>_di.dart`.
// See docs/SERVICES.md#push.

/// Builds a location from a payload; return null when the payload is
/// incomplete (e.g. no id) so the resolver can fall back.
typedef NotificationLinkBuilder = String? Function(Map<String, dynamic> payload);

class NotificationLinkResolver {
  NotificationLinkResolver({this.typeKey = 'type', this.fallbackLocation});

  /// Payload key holding the destination type (`{"type": "item", "id": 5}`).
  final String typeKey;

  /// Where unknown / incomplete payloads go (e.g. the notifications list).
  /// Null = stay where the user is.
  String? fallbackLocation;

  final Map<String, NotificationLinkBuilder> _builders = {};

  /// Registers a destination for [type] (case-insensitive):
  /// `resolver.register('item', (p) => p['id'] == null ? null : '/items/${p['id']}')`.
  void register(String type, NotificationLinkBuilder builder) => _builders[_normalize(type)] = builder;

  bool canResolve(String type) => _builders.containsKey(_normalize(type));

  /// The location for [payload], or [fallbackLocation]. Never throws: a
  /// builder that throws counts as "incomplete payload".
  String? resolve(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) return null;
    final rawType = payload[typeKey];
    final builder = rawType == null ? null : _builders[_normalize('$rawType')];
    if (builder == null) return fallbackLocation;
    try {
      final location = builder(payload)?.trim();
      return location == null || location.isEmpty ? fallbackLocation : location;
    } on Object {
      return fallbackLocation;
    }
  }

  static String _normalize(String type) => type.trim().toLowerCase();
}

/// One parked destination. A tap on a cold start must not navigate before the
/// router and session are ready (the auth redirect would bounce it to the
/// splash and lose it), so it is held here and released once.
///
/// ```dart
/// pendingLink.hold(resolver.resolve(await push.initialMessage()));
/// // later, whenever the session / router changes:
/// pendingLink.flush(ready: session.isAuthenticated && !onSplash, go: router.go);
/// ```
class PendingLink {
  String? _held;

  bool get isHeld => _held != null;

  /// The parked location (without consuming it).
  String? get location => _held;

  /// Parks [location]; a newer tap replaces an older one. Null is ignored.
  void hold(String? location) {
    if (location == null || location.trim().isEmpty) return;
    _held = location;
  }

  /// Returns the parked location ONCE when [ready], else null (and keeps it).
  String? release({required bool ready}) {
    final held = _held;
    if (held == null || !ready) return null;
    _held = null;
    return held;
  }

  /// Releases into [go] when [ready]. Returns whether it navigated.
  bool flush({required bool ready, required void Function(String location) go}) {
    final location = release(ready: ready);
    if (location == null) return false;
    go(location);
    return true;
  }

  /// Drops anything parked (call on sign-out so one account's tap never
  /// opens inside another's session).
  void clear() => _held = null;
}
