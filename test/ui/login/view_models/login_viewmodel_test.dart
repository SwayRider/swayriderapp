import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/ui/login/view_models/login_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = LoginViewModel(authRepository: mockAuthRepository);
  });

  test('initial state is idle', () {
    expect(viewModel.login.running, isFalse);
    expect(viewModel.login.completed, isFalse);
    expect(viewModel.login.error, isFalse);
    expect(viewModel.login.result, isNull);
  });

  test('execute calls AuthRepository.login with email and password', () async {
    when(() => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.login.execute(('a@b.com', 'pw'));

    verify(() => mockAuthRepository.login(email: 'a@b.com', password: 'pw'))
        .called(1);
  });

  test('Ok(null) marks the command as completed', () async {
    when(() => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.login.execute(('a@b.com', 'pw'));

    expect(viewModel.login.completed, isTrue);
    expect(viewModel.login.error, isFalse);
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('login failed');
    when(() => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => Result.error(exception));

    await viewModel.login.execute(('a@b.com', 'pw'));

    expect(viewModel.login.error, isTrue);
    expect((viewModel.login.result as Error).error, exception);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(() => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Result.ok(null));

    var notifications = 0;
    viewModel.login.addListener(() => notifications++);

    await viewModel.login.execute(('a@b.com', 'pw'));

    expect(notifications, 2);
  });

  test('re-entrant execute calls only invoke the repository once', () async {
    final completer = Completer<Result<void>>();
    when(() => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) => completer.future);

    final first = viewModel.login.execute(('a@b.com', 'pw'));
    final second = viewModel.login.execute(('a@b.com', 'pw'));

    completer.complete(const Result.ok(null));
    await first;
    await second;

    verify(() => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).called(1);
  });
}
