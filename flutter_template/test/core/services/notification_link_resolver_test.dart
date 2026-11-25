// Tests for lib/core/services/push/notification_link_resolver.dart. Source: new
import 'package:app_template/core/services/push/notification_link_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationLinkResolver', () {
    late NotificationLinkResolver resolver;

    setUp(() {
      resolver = NotificationLinkResolver(fallbackLocation: '/notifications')
        ..register('item', (p) => p['id'] == null ? null : '/items/${p['id']}')
        ..register('Order', (p) => '/orders/${p['id']}')
        ..register('broken', (p) => throw StateError('bad builder'));
    });

    test('maps a registered type to its location', () {
      expect(resolver.resolve({'type': 'item', 'id': 42}), '/items/42');
      expect(resolver.resolve({'type': ' ORDER ', 'id': '7'}), '/orders/7', reason: 'type is case-insensitive');
    });

    test('unknown types and incomplete payloads use the fallback', () {
      expect(resolver.resolve({'type': 'promo'}), '/notifications');
      expect(resolver.resolve({'id': 1}), '/notifications');
      expect(resolver.resolve({'type': 'item'}), '/notifications', reason: 'builder returned null');
      expect(resolver.resolve({'type': 'broken'}), '/notifications', reason: 'builder threw');
    });

    test('empty payloads resolve to nothing', () {
      expect(resolver.resolve(null), isNull);
      expect(resolver.resolve({}), isNull);
    });

    test('without a fallback, unknown payloads stay put', () {
      final bare = NotificationLinkResolver()..register('item', (p) => '/items/${p['id']}');
      expect(bare.resolve({'type': 'other'}), isNull);
      expect(bare.canResolve('ITEM'), isTrue);
    });

    test('custom type key', () {
      final custom = NotificationLinkResolver(typeKey: 'link_type')..register('chat', (p) => '/chats/${p['id']}');
      expect(custom.resolve({'link_type': 'chat', 'id': 3}), '/chats/3');
    });
  });

  group('PendingLink', () {
    test('holds until ready, then releases exactly once', () {
      final link = PendingLink()..hold('/items/1');
      expect(link.isHeld, isTrue);
      expect(link.release(ready: false), isNull);
      expect(link.isHeld, isTrue);
      expect(link.release(ready: true), '/items/1');
      expect(link.release(ready: true), isNull);
      expect(link.isHeld, isFalse);
    });

    test('the newest tap wins; null and blank are ignored', () {
      final link = PendingLink()
        ..hold('/items/1')
        ..hold('/items/2')
        ..hold(null)
        ..hold('  ');
      expect(link.location, '/items/2');
    });

    test('flush navigates once when ready', () {
      final visited = <String>[];
      final link = PendingLink()..hold('/orders/9');
      expect(link.flush(ready: false, go: visited.add), isFalse);
      expect(link.flush(ready: true, go: visited.add), isTrue);
      expect(link.flush(ready: true, go: visited.add), isFalse);
      expect(visited, ['/orders/9']);
    });

    test('clear drops the parked link (sign-out)', () {
      final link = PendingLink()..hold('/items/1');
      link.clear();
      expect(link.release(ready: true), isNull);
    });
  });
}
