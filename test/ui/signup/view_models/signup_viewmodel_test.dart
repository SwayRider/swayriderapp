import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/config/app_config.dart';
import 'package:swayriderapp/data/services/api/auth_api_client.dart';
import 'package:swayriderapp/ui/signup/view_models/signup_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late SignupViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = SignupViewModel(authRepository: mockAuthRepository);
  });

  test('initial state is idle', () {
    expect(viewModel.signup.running, isFalse);
    expect(viewModel.signup.completed, isFalse);
    expect(viewModel.signup.error, isFalse);
    expect(viewModel.signup.result, isNull);
  });

  test('execute calls AuthRepository.register with email, password and verificationUrl', () async {
    when(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.signup.execute(('a@b.com', 'pw'));

    verify(() => mockAuthRepository.register(
          email: 'a@b.com',
          password: 'pw',
          verificationUrl: AppConfig.verificationRedirectUrl,
        )).called(1);
  });

  test('Ok(null) marks the command as completed', () async {
    when(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.signup.execute(('a@b.com', 'pw'));

    expect(viewModel.signup.completed, isTrue);
    expect(viewModel.signup.error, isFalse);
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('signup failed');
    when(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => Result.error(exception));

    await viewModel.signup.execute(('a@b.com', 'pw'));

    expect(viewModel.signup.error, isTrue);
    expect((viewModel.signup.result as Error).error, exception);
  });

  test('invitationRequired is true when register fails with InvitationRequiredException', () async {
    when(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.error(InvitationRequiredException()));

    await viewModel.signup.execute(('a@b.com', 'pw'));

    expect(viewModel.invitationRequired, isTrue);
  });

  test('invitationRequired is false for other errors', () async {
    when(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => Result.error(Exception('signup failed')));

    await viewModel.signup.execute(('a@b.com', 'pw'));

    expect(viewModel.invitationRequired, isFalse);
  });

  test('invitationRequired is false in the initial idle state', () {
    expect(viewModel.invitationRequired, isFalse);
  });

  test('passwordTooWeak is true when register fails with WeakPasswordException', () async {
    when(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.error(WeakPasswordException()));

    await viewModel.signup.execute(('a@b.com', 'pw'));

    expect(viewModel.passwordTooWeak, isTrue);
  });

  test('passwordTooWeak is false for other errors', () async {
    when(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => Result.error(Exception('signup failed')));

    await viewModel.signup.execute(('a@b.com', 'pw'));

    expect(viewModel.passwordTooWeak, isFalse);
  });

  test('passwordTooWeak is false in the initial idle state', () {
    expect(viewModel.passwordTooWeak, isFalse);
  });

  test('checkPasswordStrength delegates to AuthRepository.checkPasswordStrength', () async {
    when(() => mockAuthRepository.checkPasswordStrength(password: any(named: 'password')))
        .thenAnswer((_) async => const Result.ok(true));

    final result = await viewModel.checkPasswordStrength('pw');

    expect((result as Ok<bool>).value, isTrue);
    verify(() => mockAuthRepository.checkPasswordStrength(password: 'pw')).called(1);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    var notifications = 0;
    viewModel.signup.addListener(() => notifications++);

    await viewModel.signup.execute(('a@b.com', 'pw'));

    expect(notifications, 2);
  });

  test('re-entrant execute calls only invoke the repository once', () async {
    final completer = Completer<Result<void>>();
    when(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) => completer.future);

    final first = viewModel.signup.execute(('a@b.com', 'pw'));
    final second = viewModel.signup.execute(('a@b.com', 'pw'));

    completer.complete(const Result.ok(null));
    await first;
    await second;

    verify(() => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          verificationUrl: any(named: 'verificationUrl'),
        )).called(1);
  });
}
