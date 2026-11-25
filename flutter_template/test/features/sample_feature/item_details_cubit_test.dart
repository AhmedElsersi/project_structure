// Tests for ItemDetailsCubit (DataCubit by id).
//
// Source: new (bloc_test + a mocktail fake of the ItemsRepository interface).
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/presentation/data_state.dart';
import 'package:app_template/core/result/result.dart';
import 'package:app_template/features/sample_feature/domain/entities/item.dart';
import 'package:app_template/features/sample_feature/domain/repositories/items_repository.dart';
import 'package:app_template/features/sample_feature/presentation/managers/item_details_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'support/fake_items_repository.dart' show sampleItem;

class _MockItemsRepository extends Mock implements ItemsRepository {}

void main() {
  late _MockItemsRepository repository;

  setUp(() => repository = _MockItemsRepository());

  blocTest<ItemDetailsCubit, DataState<Item>>(
    'loads the item of its id with the cubit cancel token',
    setUp: () => when(
      () => repository.byId('3', cancelToken: any(named: 'cancelToken')),
    ).thenAnswer((_) async => Ok(sampleItem(3))),
    build: () => ItemDetailsCubit(repository, id: '3'),
    act: (cubit) => cubit.load(),
    expect: () => [
      const DataState<Item>(status: DataStatus.loading),
      DataState<Item>(status: DataStatus.success, data: sampleItem(3)),
    ],
    verify: (_) => verify(
      () => repository.byId(
        '3',
        cancelToken: any(named: 'cancelToken', that: isA<CancelToken>()),
      ),
    ).called(1),
  );

  blocTest<ItemDetailsCubit, DataState<Item>>(
    'a missing item is a failure state',
    setUp: () => when(
      () => repository.byId('404', cancelToken: any(named: 'cancelToken')),
    ).thenAnswer((_) async => const Err(NotFoundFailure())),
    build: () => ItemDetailsCubit(repository, id: '404'),
    act: (cubit) => cubit.load(),
    expect: () => [
      const DataState<Item>(status: DataStatus.loading),
      const DataState<Item>(status: DataStatus.failure, failure: NotFoundFailure()),
    ],
  );
}
