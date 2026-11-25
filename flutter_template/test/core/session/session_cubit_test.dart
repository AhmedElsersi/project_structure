// Tests for lib/core/session/session_cubit.dart. Source: new
import 'dart:async';

import 'package:app_template/core/session/session_cubit.dart';
import 'package:app_template/core/storage/auth_token_store.dart';
import 'package:app_template/core/storage/secure_store.dart';
import 'package:app_template/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecureStore secure;
  late AuthTokenStore tokens;
  late SessionCubit cubit;
  late List<SessionState> emitted;
  late StreamSubscription<SessionState> sub;
  late List<String> log;

  setUp(() {
    secure = MemorySecureStore();
    tokens = AuthTokenStore(secure);
    cubit = SessionCubit(tokens);
    emitted = [];
    log = [];
    sub = cubit.stream.listen(emitted.add);
  });

  tearDown(() async {
    await sub.cancel();
    await cubit.close();
  });

  void addLoggingHooks([String tag = '']) =>
      cubit.addHooks(onStart: () => log.add('start$tag'), onEnd: () => log.add('end$tag'));

  test('starts unknown', () {
    expect(cubit.state, const SessionState());
    expect(cubit.state.status, SessionStatus.unknown);
    expect(cubit.state.isAuthenticated, isFalse);
  });

  group('restore', () {
    test('without a stored token → unauthenticated, no start hooks', () async {
      addLoggingHooks();
      await cubit.restore();
      expect(cubit.state, const SessionState(status: SessionStatus.unauthenticated, generation: 1));
      expect(log, isEmpty);
    });

    test('with a stored token → authenticated and start hooks run', () async {
      await secure.write(StorageKeys.accessToken, 'a1');
      addLoggingHooks();
      await cubit.restore();
      expect(cubit.state, const SessionState(status: SessionStatus.authenticated, generation: 1));
      expect(cubit.state.isAuthenticated, isTrue);
      expect(log, ['start']);
    });
  });

  test('signedIn saves tokens, authenticates, bumps generation, runs start hooks in order', () async {
    await cubit.restore();
    addLoggingHooks('1');
    addLoggingHooks('2');
    await cubit.signedIn(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));

    expect(cubit.state, const SessionState(status: SessionStatus.authenticated, generation: 2));
    expect(tokens.accessToken, 'a1');
    expect(await secure.read(StorageKeys.refreshToken), 'r1');
    expect(log, ['start1', 'start2']);
  });

  test('signOut runs end hooks while the token still exists, then clears and bumps generation', () async {
    await cubit.signedIn(const AuthTokens(accessToken: 'a1'));
    bool? hadTokenDuringHook;
    cubit.addHooks(onEnd: () => hadTokenDuringHook = tokens.hasSession);

    await cubit.signOut();

    expect(hadTokenDuringHook, isTrue);
    expect(cubit.state, const SessionState(status: SessionStatus.unauthenticated, generation: 2));
    expect(tokens.hasSession, isFalse);
    expect(await secure.read(StorageKeys.accessToken), isNull);
  });

  test('signOut is single-flight: concurrent calls share one sign-out', () async {
    await cubit.signedIn(const AuthTokens(accessToken: 'a1'));
    final gate = Completer<void>();
    var endRuns = 0;
    cubit.addHooks(
      onEnd: () async {
        endRuns++;
        await gate.future;
      },
    );
    emitted.clear();

    final first = cubit.signOut();
    final second = cubit.signOut();
    cubit.expire();
    gate.complete();
    await Future.wait([first, second]);
    await pumpEventQueue();

    expect(endRuns, 1);
    expect(emitted, [const SessionState(status: SessionStatus.unauthenticated, generation: 2)]);
  });

  test('a later sign-out after the first completed runs again', () async {
    var endRuns = 0;
    cubit.addHooks(onEnd: () => endRuns++);
    await cubit.signedIn(const AuthTokens(accessToken: 'a1'));
    await cubit.signOut();
    await cubit.signedIn(const AuthTokens(accessToken: 'a2'));
    await cubit.signOut();
    expect(endRuns, 2);
    expect(cubit.state.generation, 4);
  });

  group('expire', () {
    test('signs an authenticated user out with expired: true', () async {
      await cubit.signedIn(const AuthTokens(accessToken: 'a1'));
      addLoggingHooks();
      cubit.expire();
      await pumpEventQueue();
      expect(cubit.state, const SessionState(status: SessionStatus.unauthenticated, generation: 2, expired: true));
      expect(log, ['end']);
      expect(tokens.hasSession, isFalse);
    });

    test('does nothing while unknown or unauthenticated', () async {
      addLoggingHooks();
      cubit.expire();
      await pumpEventQueue();
      expect(cubit.state.status, SessionStatus.unknown);

      await cubit.restore();
      cubit.expire();
      await pumpEventQueue();
      expect(cubit.state, const SessionState(status: SessionStatus.unauthenticated, generation: 1));
      expect(log, isEmpty);
    });

    test('two expiries (e.g. two failed refreshes) sign out once', () async {
      await cubit.signedIn(const AuthTokens(accessToken: 'a1'));
      var endRuns = 0;
      cubit.addHooks(onEnd: () => endRuns++);
      cubit
        ..expire()
        ..expire();
      await pumpEventQueue();
      expect(endRuns, 1);
      expect(cubit.state.generation, 2);
    });

    test('a new sign-in clears the expired flag', () async {
      await cubit.signedIn(const AuthTokens(accessToken: 'a1'));
      cubit.expire();
      await pumpEventQueue();
      await cubit.signedIn(const AuthTokens(accessToken: 'a2'));
      expect(cubit.state.expired, isFalse);
      expect(cubit.state.isAuthenticated, isTrue);
    });
  });

  group('failing hooks never block', () {
    test('sign-in: later hooks still run and the user is authenticated', () async {
      cubit
        ..addHooks(onStart: () => throw StateError('sync failure'))
        ..addHooks(onStart: () async => throw StateError('async failure'))
        ..addHooks(onStart: () => log.add('third'));
      await cubit.signedIn(const AuthTokens(accessToken: 'a1'));
      expect(cubit.state.isAuthenticated, isTrue);
      expect(log, ['third']);
    });

    test('sign-out: tokens are still cleared', () async {
      await cubit.signedIn(const AuthTokens(accessToken: 'a1'));
      cubit.addHooks(onEnd: () async => throw StateError('push unsubscribe failed'));
      await cubit.signOut();
      expect(cubit.state.status, SessionStatus.unauthenticated);
      expect(tokens.hasSession, isFalse);
    });
  });
}
