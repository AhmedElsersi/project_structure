// App session status that drives the router redirect (no imperative navigation
// after sign-in/out). Feature auth code calls [signedIn] / [signOut].
//
// Source: baytna lib/app/session/session_cubit.dart (SessionStatus is the router's
//         single source of truth; refreshListenable on the cubit stream).
// Merged: chinaparts-seller lib/core/services/session_service.dart (single-flight
//         sign-out, generation counter to re-key per-user providers);
//         corsa-customer main.dart _wireSessionHooks (start/end hooks so core
//         never imports feature cubits); lexa (offline never signs the user out).
// See docs/ARCHITECTURE.md#session.
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/auth_token_store.dart';

enum SessionStatus { unknown, unauthenticated, authenticated }

class SessionState extends Equatable {
  const SessionState({this.status = SessionStatus.unknown, this.generation = 0, this.expired = false});

  final SessionStatus status;

  /// Increments on every sign-in/out: use as a ValueKey to rebuild per-user state.
  final int generation;

  /// True when the session ended because the server rejected the token.
  final bool expired;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  @override
  List<Object?> get props => [status, generation, expired];
}

typedef SessionHook = FutureOr<void> Function();

class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._tokens) : super(const SessionState());

  final AuthTokenStore _tokens;
  final List<SessionHook> _onStart = [];
  final List<SessionHook> _onEnd = [];
  Future<void>? _signingOut;

  /// Features register work for session start/end (clear caches, subscribe to
  /// push topics...) without core importing them.
  void addHooks({SessionHook? onStart, SessionHook? onEnd}) {
    if (onStart != null) _onStart.add(onStart);
    if (onEnd != null) _onEnd.add(onEnd);
  }

  /// Reads stored tokens once at startup.
  Future<void> restore() async {
    await _tokens.load();
    emit(
      SessionState(
        status: _tokens.hasSession ? SessionStatus.authenticated : SessionStatus.unauthenticated,
        generation: state.generation + 1,
      ),
    );
    if (_tokens.hasSession) await _run(_onStart);
  }

  Future<void> signedIn(AuthTokens tokens) async {
    // A late sign-out must not wipe the new session's tokens.
    await _signingOut;
    await _tokens.save(tokens);
    emit(SessionState(status: SessionStatus.authenticated, generation: state.generation + 1));
    await _run(_onStart);
  }

  /// Single-flight: concurrent calls share one sign-out.
  /// No-op when already signed out.
  Future<void> signOut({bool expired = false}) {
    if (state.status == SessionStatus.unauthenticated) return Future<void>.value();
    return _signingOut ??= _doSignOut(expired).whenComplete(() => _signingOut = null);
  }

  /// Called by the auth interceptor when refresh fails.
  void expire() {
    if (state.status == SessionStatus.authenticated) unawaited(signOut(expired: true));
  }

  Future<void> _doSignOut(bool expired) async {
    await _run(_onEnd);
    await _tokens.clear();
    emit(SessionState(status: SessionStatus.unauthenticated, generation: state.generation + 1, expired: expired));
  }

  Future<void> _run(List<SessionHook> hooks) async {
    for (final hook in hooks) {
      try {
        await hook();
      } on Object {
        // A failing hook must never block sign-in/out.
      }
    }
  }
}
