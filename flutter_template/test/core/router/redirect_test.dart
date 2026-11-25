// Tests for lib/core/router/redirect.dart. Source: new
//
// Merged: markspulse test/app/router/redirect_test.dart (cross product of every
//         session state × every location; "one hop settles" invariant).
import 'package:app_template/core/router/redirect.dart';
import 'package:app_template/core/session/session_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

const _splash = '/splash';
const _home = '/';
const _signIn = '/sign-in';
const _protected = '/profile';

const _noAuth = RedirectConfig(splash: _splash, home: _home);
const _withAuth = RedirectConfig(splash: _splash, home: _home, signIn: _signIn, protectedPrefixes: [_protected]);
const _protectedNoSignIn = RedirectConfig(splash: _splash, home: _home, protectedPrefixes: [_protected]);

const Map<String, RedirectConfig> _configs = {
  'no auth feature': _noAuth,
  'sign-in + protected prefixes': _withAuth,
  'protected prefixes, no sign-in route': _protectedNoSignIn,
};

/// Every kind of location the router can be asked about.
const List<String> _locations = [
  _splash,
  _home,
  '$_splash?from=%2Fx',
  '$_splash?from=%2Fprofile%2F7',
  '$_splash?from=',
  '$_splash?from=%2Fsplash',
  '/x',
  '/x?tab=2',
  _protected,
  '$_protected/7',
  '/profiles', // not inside /profile
  _signIn,
  '$_signIn?from=%2Fprofile%2F7',
  '/settings',
  '',
];

/// Cold-start deep links to the sign-in screen. See the skipped test below.
const List<String> _splashFromSignIn = ['$_splash?from=%2Fsign-in', '$_splash?from=%2Fsign-in%3Ffrom%3D%2Fprofile'];

String? _go(SessionStatus status, String location, [RedirectConfig config = _withAuth]) =>
    computeRedirect(status, location, config);

void main() {
  group('unknown session holds on the splash', () {
    test('the splash itself is not redirected', () {
      expect(_go(SessionStatus.unknown, _splash), isNull);
      expect(_go(SessionStatus.unknown, '$_splash?from=%2Fx'), isNull);
    });

    test('any other location goes to the splash and remembers it in `from`', () {
      final target = Uri.parse(_go(SessionStatus.unknown, '/x?tab=2')!);
      expect(target.path, _splash);
      expect(target.queryParameters['from'], '/x?tab=2');
      expect(Uri.parse(_go(SessionStatus.unknown, _home)!).queryParameters['from'], _home);
    });
  });

  group('leaving the splash once the session is resolved', () {
    for (final status in [SessionStatus.unauthenticated, SessionStatus.authenticated]) {
      test('${status.name}: no `from` (or a `from` pointing at the splash) → home', () {
        expect(_go(status, _splash), _home);
        expect(_go(status, '$_splash?from='), _home);
        expect(_go(status, '$_splash?from=%2Fsplash'), _home);
      });

      test('${status.name}: the remembered deep link is restored', () {
        expect(_go(status, '$_splash?from=%2Fx%3Ftab%3D2'), '/x?tab=2');
      });
    }

    test('authenticated: a protected deep link is restored', () {
      expect(_go(SessionStatus.authenticated, '$_splash?from=%2Fprofile%2F7'), '/profile/7');
    });

    test('unauthenticated: a protected deep link goes through sign-in and is kept in `from`', () {
      expect(_go(SessionStatus.unauthenticated, '$_splash?from=%2Fprofile%2F7'), '$_signIn?from=%2Fprofile%2F7');
      expect(_go(SessionStatus.unauthenticated, '$_splash?from=%2Fprofile%2F7', _protectedNoSignIn), _home);
    });
  });

  group('protected locations', () {
    test('signed out → sign-in, keeping the target in `from`', () {
      final target = Uri.parse(_go(SessionStatus.unauthenticated, '/profile/7')!);
      expect(target.path, _signIn);
      expect(target.queryParameters['from'], '/profile/7');
    });

    test('signed out without a sign-in route → home', () {
      expect(_go(SessionStatus.unauthenticated, _protected, _protectedNoSignIn), _home);
    });

    test('signed in → stays', () {
      expect(_go(SessionStatus.authenticated, '/profile/7'), isNull);
    });

    test('prefixes match on a path boundary, not a substring', () {
      expect(_withAuth.isProtected('/profile'), isTrue);
      expect(_withAuth.isProtected('/profile/7'), isTrue);
      expect(_withAuth.isProtected('/profiles'), isFalse);
      expect(_go(SessionStatus.unauthenticated, '/profiles'), isNull);
    });

    test('public locations are open to everyone', () {
      for (final status in [SessionStatus.unauthenticated, SessionStatus.authenticated]) {
        expect(_go(status, '/x'), isNull);
        expect(_go(status, _home), isNull);
      }
    });
  });

  group('sign-in screen', () {
    test('signed out → stays on sign-in', () {
      expect(_go(SessionStatus.unauthenticated, _signIn), isNull);
      expect(_go(SessionStatus.unauthenticated, '$_signIn?from=%2Fprofile%2F7'), isNull);
    });

    test('signed in → leaves to `from`, or home', () {
      expect(_go(SessionStatus.authenticated, '$_signIn?from=%2Fprofile%2F7'), '/profile/7');
      expect(_go(SessionStatus.authenticated, _signIn), _home);
    });

    test('without an auth feature the sign-in path is just another location', () {
      expect(_go(SessionStatus.authenticated, _signIn, _noAuth), isNull);
    });
  });

  // The property that matters: go_router re-runs the redirect after applying
  // one, so a target that is itself redirected costs an extra hop (or, in the
  // worst case, ping-pongs into a blank screen).
  group('one hop always settles', () {
    _configs.forEach((name, config) {
      test(name, () {
        for (final status in SessionStatus.values) {
          for (final location in _locations) {
            final first = computeRedirect(status, location, config);
            if (first == null) continue;
            expect(first, isNot(location), reason: '${status.name}: $location redirected to itself');
            expect(
              computeRedirect(status, first, config),
              isNull,
              reason: '${status.name}: $location → $first → not settled',
            );
          }
        }
      });
    });

    test('including a cold-start deep link to the sign-in screen', () {
      for (final location in _splashFromSignIn) {
        final first = _go(SessionStatus.authenticated, location);
        expect(_go(SessionStatus.authenticated, first!), isNull, reason: '$location → $first → not settled');
      }
    });

    test('every status has at least one settled location', () {
      _configs.forEach((name, config) {
        for (final status in SessionStatus.values) {
          final settled = _locations.where((l) => computeRedirect(status, l, config) == null);
          expect(settled, isNotEmpty, reason: '$name/${status.name} can never settle');
        }
      });
    });

    test('nothing ever loops (at most two hops, even in the known two-hop case)', () {
      _configs.forEach((name, config) {
        for (final status in SessionStatus.values) {
          for (final location in [..._locations, ..._splashFromSignIn]) {
            final first = computeRedirect(status, location, config);
            if (first == null) continue;
            final second = computeRedirect(status, first, config);
            if (second == null) continue;
            expect(computeRedirect(status, second, config), isNull, reason: '$name: $location → $first → $second');
          }
        }
      });
    });
  });
}
