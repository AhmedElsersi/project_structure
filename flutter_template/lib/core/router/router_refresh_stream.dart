// Listenable over one or more streams, for GoRouter.refreshListenable.
//
// Source: baytna lib/app/router/router_refresh_stream.dart; lexa-student
//         lib/core/routing/go_router_refresh_stream.dart (multi-stream variant).
import 'dart:async';

import 'package:flutter/foundation.dart';

class RouterRefreshStream extends ChangeNotifier {
  RouterRefreshStream(List<Stream<Object?>> streams) {
    _subscriptions = [for (final s in streams) s.listen((_) => notifyListeners())];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
