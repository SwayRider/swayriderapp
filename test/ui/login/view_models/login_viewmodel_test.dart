import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/data/repositories/auth/auth_repository.dart';
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
    expect(viewModel.loginOutcome, isNull);
    expect(viewModel.mfaRequired, isFalse);
    expect(viewModel.mfaToken, isNull);
    expect(viewModel.verifyMfa.running, isFalse);
  });

  test('execute calls AuthRepository.login with email and password', () async {
    when(
      () => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Result.ok(LoginSuccess()));

    await viewModel.login.execute(('a@b.com', 'pw'));

    verify(
      () => mockAuthRepository.login(email: 'a@b.com', password: 'pw'),
    ).called(1);
  });

  test('Ok(LoginSuccess) marks the command as completed', () async {
    when(
      () => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Result.ok(LoginSuccess()));

    await viewModel.login.execute(('a@b.com', 'pw'));

    expect(viewModel.login.completed, isTrue);
    expect(viewModel.login.error, isFalse);
    expect(viewModel.loginOutcome, isA<LoginSuccess>());
    expect(viewModel.mfaRequired, isFalse);
    expect(viewModel.mfaToken, isNull);
  });

  test('Ok(LoginMfaRequired) exposes the token without marking an error',
      () async {
    when(
      () => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Result.ok(LoginMfaRequired('challenge-token-1')),
    );

    await viewModel.login.execute(('a@b.com', 'pw'));

    expect(viewModel.login.completed, isTrue);
    expect(viewModel.login.error, isFalse);
    expect(viewModel.loginOutcome, isA<LoginMfaRequired>());
    expect(viewModel.mfaRequired, isTrue);
    expect(viewModel.mfaToken, 'challenge-token-1');
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('login failed');
    when(
      () => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => Result.error(exception));

    await viewModel.login.execute(('a@b.com', 'pw'));

    expect(viewModel.login.error, isTrue);
    expect((viewModel.login.result as Error).error, exception);
    expect(viewModel.loginOutcome, isNull);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(
      () => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Result.ok(LoginSuccess()));

    var notifications = 0;
    viewModel.login.addListener(() => notifications++);

    await viewModel.login.execute(('a@b.com', 'pw'));

    expect(notifications, 2);
  });

  test('re-entrant execute calls only invoke the repository once', () async {
    final completer = Completer<Result<LoginOutcome>>();
    when(
      () => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => completer.future);

    final first = viewModel.login.execute(('a@b.com', 'pw'));
    final second = viewModel.login.execute(('a@b.com', 'pw'));

    completer.complete(const Result.ok(LoginSuccess()));
    await first;
    await second;

    verify(
      () => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1);
  });

  group('verifyMfa', () {
    test('execute calls AuthRepository.verifyMfa with the token and code',
        () async {
      when(
        () => mockAuthRepository.verifyMfa(
          mfaToken: any(named: 'mfaToken'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));

      await viewModel.verifyMfa.execute(('challenge-token-1', '123456'));

      verify(
        () => mockAuthRepository.verifyMfa(
          mfaToken: 'challenge-token-1',
          code: '123456',
        ),
      ).called(1);
    });

    test('Ok result marks the command as completed', () async {
      when(
        () => mockAuthRepository.verifyMfa(
          mfaToken: any(named: 'mfaToken'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));

      await viewModel.verifyMfa.execute(('challenge-token-1', '123456'));

      expect(viewModel.verifyMfa.completed, isTrue);
      expect(viewModel.verifyMfa.error, isFalse);
    });

    test('Error result marks the command as error', () async {
      final exception = Exception('verify failed');
      when(
        () => mockAuthRepository.verifyMfa(
          mfaToken: any(named: 'mfaToken'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => Result.error(exception));

      await viewModel.verifyMfa.execute(('challenge-token-1', '123456'));

      expect(viewModel.verifyMfa.error, isTrue);
      expect((viewModel.verifyMfa.result as Error).error, exception);
    });
  });
}
