// ItemsRepositoryImpl against the REAL ApiClient + MockInterceptor (latency
// zero) and the feature's mock API over assets/mocks/items.json: paging,
// search, 404, 422 field errors, create.
//
// Source: new (repository tests through the real interceptor stack, like
//         test/core/network/api_client_test.dart).
import 'dart:convert';
import 'dart:io';

import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/logging/app_logger.dart';
import 'package:app_template/core/network/api_client.dart';
import 'package:app_template/core/network/mock/mock_interceptor.dart';
import 'package:app_template/core/result/result.dart';
import 'package:app_template/core/storage/auth_token_store.dart';
import 'package:app_template/core/storage/secure_store.dart';
import 'package:app_template/features/sample_feature/data/data_sources/items_remote_data_source.dart';
import 'package:app_template/features/sample_feature/data/mock/items_mock_api.dart';
import 'package:app_template/features/sample_feature/data/repositories/items_repository_impl.dart';
import 'package:app_template/features/sample_feature/domain/entities/create_item_input.dart';
import 'package:app_template/features/sample_feature/domain/entities/item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads assets straight from disk (no Flutter asset bundle needed).
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(Uint8List.fromList(File(key).readAsBytesSync()));
}

void main() {
  late ItemsRepositoryImpl repository;
  late MockInterceptor mock;
  var language = 'en';

  final seed = (jsonDecode(File(itemsMockAsset).readAsStringSync()) as Map<String, dynamic>)['items'] as List<dynamic>;

  setUp(() {
    language = 'en';
    mock = MockInterceptor(latency: Duration.zero, bundle: _DiskBundle());
    registerItemsMockApi(mock);
    final client = ApiClient(
      baseUrl: 'https://mock.local/api',
      tokens: AuthTokenStore(MemorySecureStore()),
      logger: AppLogger(enabled: false),
      languageCode: () => language,
      appHeaders: () => const {},
      onSessionExpired: () {},
      onAppStatus: (_, _) {},
      mock: mock,
    );
    repository = ItemsRepositoryImpl(ItemsRemoteDataSource(client));
  });

  T ok<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  Failure err<T>(Result<T> result) => switch (result) {
    Ok(:final value) => fail('Expected Err, got $value'),
    Err(:final failure) => failure,
  };

  test('the seed has ~40 neutral items with picsum placeholders', () {
    expect(seed.length, 40);
    for (final row in seed.cast<Map<String, dynamic>>()) {
      final url = row['image_url'] as String?;
      if (url != null) expect(url, startsWith('https://picsum.photos/seed/'));
    }
  });

  test('pages through all items, 15 per page', () async {
    final first = ok(await repository.fetchPage(1));
    expect(first.items, hasLength(15));
    expect(first.page, 1);
    expect(first.hasMore, isTrue);
    expect(first.total, 40);
    expect(first.items.first.title, 'Sample item 01');

    final last = ok(await repository.fetchPage(3));
    expect(last.items, hasLength(10));
    expect(last.hasMore, isFalse);
    expect(last.items.last.title, 'Sample item 40');

    expect(ok(await repository.fetchPage(4)).items, isEmpty);
  });

  test('the seed exercises the fallbacks (unknown status, missing image)', () async {
    final page = ok(await repository.fetchPage(1));
    expect(page.items.firstWhere((i) => i.id == '7').status, ItemStatus.unknown);
    expect(page.items.firstWhere((i) => i.id == '5').imageUrl, isNull);
  });

  test('search filters by title (case-insensitive) and pages the matches', () async {
    final page = ok(await repository.fetchPage(1, query: 'ITEM 1'));
    expect(
      page.items.map((i) => i.title),
      ['Sample item 10', ...List.generate(9, (i) => 'Sample item 1${i + 1}')]..sort(),
    );
    expect(page.total, 10);
    expect(page.hasMore, isFalse);
    expect(ok(await repository.fetchPage(1, query: 'zzz')).items, isEmpty);
  });

  test('byId returns the item, or NotFoundFailure with the localized sentence', () async {
    expect(ok(await repository.byId('3')).title, 'Sample item 03');
    final failure = err(await repository.byId('999'));
    expect(failure, isA<NotFoundFailure>());
    // No server message: the UI shows the app's own translated sentence.
    expect(failure.serverMessage, isNull);
  });

  test('create: 422 field errors for a short or taken title, in the request language', () async {
    final short = err(await repository.create(const CreateItemInput(title: 'ab')));
    expect(short, isA<ValidationFailure>());
    expect((short as ValidationFailure).fieldError('title'), 'The title must be at least 3 characters');

    final taken = err(await repository.create(const CreateItemInput(title: 'Taken')));
    expect((taken as ValidationFailure).fieldError('title'), 'This title is already used');

    language = 'ar';
    final arabic = err(await repository.create(const CreateItemInput(title: 'taken')));
    expect((arabic as ValidationFailure).fieldError('title'), 'هذا العنوان مستخدم بالفعل');
  });

  test('create: 201 returns the item, which then leads the list and is fetchable', () async {
    final created = ok(
      await repository.create(
        const CreateItemInput(title: 'Brand new', description: 'Desc', status: ItemStatus.active),
      ),
    );
    expect(created.id, '41');
    expect(created.title, 'Brand new');
    expect(created.status, ItemStatus.active);

    final first = ok(await repository.fetchPage(1));
    expect(first.items.first, created);
    expect(first.total, 41);
    expect(ok(await repository.byId('41')), created);
  });

  test('a cancelled request is a CancelledFailure, never shown', () async {
    final token = CancelToken()..cancel('test');
    expect(err(await repository.fetchPage(1, cancelToken: token)), isA<CancelledFailure>());
  });

  test('a server error becomes a ServerFailure', () async {
    mock.failNext(500);
    expect(err(await repository.fetchPage(1)), isA<ServerFailure>());
  });
}
