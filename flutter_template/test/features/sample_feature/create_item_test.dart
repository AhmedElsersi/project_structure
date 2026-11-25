// Tests for CreateItemUseCase (trim + title rule) and CreateItemCubit
// (submitting → created / field errors / general failure).
//
// Source: new (bloc_test + a mocktail fake of the ItemsRepository interface).
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/result/result.dart';
import 'package:app_template/features/sample_feature/domain/entities/create_item_input.dart';
import 'package:app_template/features/sample_feature/domain/entities/item.dart';
import 'package:app_template/features/sample_feature/domain/repositories/items_repository.dart';
import 'package:app_template/features/sample_feature/domain/use_cases/create_item_use_case.dart';
import 'package:app_template/features/sample_feature/presentation/managers/create_item_cubit.dart';
import 'package:app_template/features/sample_feature/presentation/managers/create_item_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'support/fake_items_repository.dart' show sampleItem;

class _MockItemsRepository extends Mock implements ItemsRepository {}

const _taken = ValidationFailure(
  fieldErrors: {
    'title': ['This title is already used'],
  },
);

void main() {
  late _MockItemsRepository repository;
  late CreateItemUseCase useCase;

  setUpAll(() => registerFallbackValue(const CreateItemInput(title: '')));

  setUp(() {
    repository = _MockItemsRepository();
    useCase = CreateItemUseCase(repository);
  });

  group('CreateItemUseCase', () {
    test('trims the input before sending it', () async {
      when(() => repository.create(any())).thenAnswer((_) async => Ok(sampleItem(1)));
      await useCase(const CreateItemInput(title: '  New item  ', description: ' text\n', status: ItemStatus.active));
      verify(
        () =>
            repository.create(const CreateItemInput(title: 'New item', description: 'text', status: ItemStatus.active)),
      ).called(1);
    });

    test('a title shorter than 3 characters is a title field error, and nothing is sent', () async {
      final result = await useCase(const CreateItemInput(title: '  ab  '));
      final failure = result.failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldError('title'), isNotEmpty);
      expect(failure.code, 'title_too_short');
      verifyNever(() => repository.create(any()));
    });

    test('counts characters, not bytes: three Arabic letters are enough', () async {
      when(() => repository.create(any())).thenAnswer((_) async => Ok(sampleItem(1)));
      expect((await useCase(const CreateItemInput(title: 'قلم'))).isOk, isTrue);
    });

    test('passes repository failures through', () async {
      when(() => repository.create(any())).thenAnswer((_) async => const Err(_taken));
      expect((await useCase(const CreateItemInput(title: 'taken'))).failureOrNull, _taken);
    });
  });

  group('CreateItemCubit', () {
    blocTest<CreateItemCubit, CreateItemState>(
      'success: submitting → created item',
      setUp: () => when(() => repository.create(any())).thenAnswer((_) async => Ok(sampleItem(41))),
      build: () => CreateItemCubit(useCase),
      act: (cubit) => cubit.submit(const CreateItemInput(title: 'Brand new')),
      expect: () => [const CreateItemState(isSubmitting: true), CreateItemState(created: sampleItem(41))],
    );

    blocTest<CreateItemCubit, CreateItemState>(
      '422: the field error is exposed per field, no general failure',
      setUp: () => when(() => repository.create(any())).thenAnswer((_) async => const Err(_taken)),
      build: () => CreateItemCubit(useCase),
      act: (cubit) => cubit.submit(const CreateItemInput(title: 'taken')),
      expect: () => [const CreateItemState(isSubmitting: true), const CreateItemState(failure: _taken)],
      verify: (cubit) {
        expect(cubit.state.fieldError('title'), 'This title is already used');
        expect(cubit.state.fieldError('description'), isNull);
        expect(cubit.state.generalFailure, isNull);
      },
    );

    blocTest<CreateItemCubit, CreateItemState>(
      'the domain rule fails without a request',
      build: () => CreateItemCubit(useCase),
      act: (cubit) => cubit.submit(const CreateItemInput(title: 'x')),
      skip: 1,
      expect: () => [isA<CreateItemState>().having((s) => s.fieldError('title'), 'title error', isNotNull)],
      verify: (_) => verifyNever(() => repository.create(any())),
    );

    blocTest<CreateItemCubit, CreateItemState>(
      'network failure is a general failure (snackbar), and the next submit clears it',
      setUp: () {
        var calls = 0;
        when(
          () => repository.create(any()),
        ).thenAnswer((_) async => calls++ == 0 ? const Err(NetworkFailure()) : Ok(sampleItem(41)));
      },
      build: () => CreateItemCubit(useCase),
      act: (cubit) async {
        await cubit.submit(const CreateItemInput(title: 'Brand new'));
        expect(cubit.state.generalFailure, const NetworkFailure());
        await cubit.submit(const CreateItemInput(title: 'Brand new'));
      },
      expect: () => [
        const CreateItemState(isSubmitting: true),
        const CreateItemState(failure: NetworkFailure()),
        const CreateItemState(isSubmitting: true),
        CreateItemState(created: sampleItem(41)),
      ],
    );
  });
}
