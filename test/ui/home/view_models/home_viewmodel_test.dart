import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/ui/home/view_models/home_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late HomeViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = HomeViewModel(authRepository: mockAuthRepository);
  });

  test('initial state is idle', () {
    expect(viewModel.logout.running, isFalse);
    expect(viewModel.logout.completed, isFalse);
    expect(viewModel.logout.error, isFalse);
    expect(viewModel.logout.result, isNull);
  });

  test('execute calls AuthRepository.logout with no arguments', () async {
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => const Result.ok(null));

    await viewModel.logout.execute();

    verify(() => mockAuthRepository.logout()).called(1);
  });

  test('Ok(null) marks the command as completed', () async {
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => const Result.ok(null));

    await viewModel.logout.execute();

    expect(viewModel.logout.completed, isTrue);
    expect(viewModel.logout.error, isFalse);
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('logout failed');
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => Result.error(exception));

    await viewModel.logout.execute();

    expect(viewModel.logout.error, isTrue);
    expect((viewModel.logout.result as Error).error, exception);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => const Result.ok(null));

    var notifications = 0;
    viewModel.logout.addListener(() => notifications++);

    await viewModel.logout.execute();

    expect(notifications, 2);
  });

  test('re-entrant execute calls only invoke the repository once', () async {
    final completer = Completer<Result<void>>();
    when(() => mockAuthRepository.logout()).thenAnswer((_) => completer.future);

    final first = viewModel.logout.execute();
    final second = viewModel.logout.execute();

    completer.complete(const Result.ok(null));
    await first;
    await second;

    verify(() => mockAuthRepository.logout()).called(1);
  });
}
