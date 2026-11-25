// Pure, context-free redirect rule for GoRouter (unit-tested in
// test/core/router/redirect_test.dart).
//
// Source: markspulse lib/app/router/redirect.dart (pure computeRedirect; "every
//         branch returns null for the locations it is satisfied by", so one hop
//         always settles and never ping-pongs into a blank screen).
// Merged: baytna session_cubit (status-driven, no navigation after login);
//         corsa-customer (cold-start deep link kept in `from` and restored).
// See docs/ARCHITECTURE.md#routing.
import '../session/session_cubit.dart';

class RedirectConfig {
  const RedirectConfig({required this.splash, required this.home, this.signIn, this.protectedPrefixes = const []});

  final String splash;
  final String home;

  /// Sign-in route; null while the app has no auth feature.
  final String? signIn;

  /// Locations that require an authenticated session (e.g. `/profile`).
  final List<String> protectedPrefixes;

  bool isProtected(String location) => protectedPrefixes.any((p) => location == p || location.startsWith('$p/'));
}

/// [location] is `state.uri.toString()` (path + query).
String? computeRedirect(SessionStatus status, String location, RedirectConfig config) {
  final uri = Uri.parse(location);
  final path = uri.path;

  switch (status) {
    case SessionStatus.unknown:
      // Hold on the splash until the session is resolved; remember the target.
      if (path == config.splash) return null;
      return Uri(path: config.splash, queryParameters: {'from': location}).toString();

    case SessionStatus.unauthenticated:
    case SessionStatus.authenticated:
      if (path == config.splash) {
        final from = uri.queryParameters['from'];
        final target = (from == null || from.isEmpty || Uri.parse(from).path == config.splash) ? config.home : from;
        // The restored target may itself need a redirect (protected link while
        // signed out, sign-in while signed in): resolve it here so one hop settles.
        return computeRedirect(status, target, config) ?? target;
      }
      final signIn = config.signIn;
      if (status == SessionStatus.unauthenticated && config.isProtected(path)) {
        return signIn == null ? config.home : Uri(path: signIn, queryParameters: {'from': location}).toString();
      }
      if (status == SessionStatus.authenticated && signIn != null && path == signIn) {
        final from = uri.queryParameters['from'];
        return (from == null || from.isEmpty) ? config.home : from;
      }
      return null;
  }
}
