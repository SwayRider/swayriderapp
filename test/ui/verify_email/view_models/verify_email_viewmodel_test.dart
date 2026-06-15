import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/config/app_config.dart';
import 'package:swayriderapp/domain/models/user/user.dart';
import 'package:swayriderapp/ui/verify_email/view_models/verify_email_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  test('initial state is idle', () {
    final viewModel = VerifyEmailViewModel(
      authRepository: mockAuthRepository,
      email: 'a@b.com',
    );

    expect(viewModel.resendVerification.running, isFalse);
    expect(viewModel.resendVerification.completed, isFalse);
    expect(viewModel.resendVerification.error, isFalse);
    expect(viewModel.resendVerification.result, isNull);

    expect(viewModel.logout.running, isFalse);
    expect(viewModel.logout.completed, isFalse);
    expect(viewModel.logout.error, isFalse);
    expect(viewModel.logout.result, isNull);
  });

  test('with email provided, execute calls verifyEmail directly without calling me()', () async {
    when(() => mockAuthRepository.verifyEmail(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    final viewModel = VerifyEmailViewModel(
      authRepository: mockAuthRepository,
      email: 'a@b.com',
    );

    await viewModel.resendVerification.execute();

    verify(() => mockAuthRepository.verifyEmail(
          email: 'a@b.com',
          verificationUrl: AppConfig.verificationRedirectUrl,
        )).called(1);
    verifyNever(() => mockAuthRepository.me());
  });

  test('with no email provided, execute resolves the email via me() first', () async {
    when(() => mockAuthRepository.me()).thenAnswer(
      (_) async => const Result.ok(
        User(id: '1', email: 'fetched@b.com', isVerified: false),
      ),
    );
    when(() => mockAuthRepository.verifyEmail(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    final viewModel = VerifyEmailViewModel(authRepository: mockAuthRepository);

    await viewModel.resendVerification.execute();

    verify(() => mockAuthRepository.me()).called(1);
    verify(() => mockAuthRepository.verifyEmail(
          email: 'fetched@b.com',
          verificationUrl: AppConfig.verificationRedirectUrl,
        )).called(1);
  });

  test('if me() returns Error, resendVerification ends in error and verifyEmail is not called', () async {
    final exception = Exception('me failed');
    when(() => mockAuthRepository.me())
        .thenAnswer((_) async => Result.error(exception));

    final viewModel = VerifyEmailViewModel(authRepository: mockAuthRepository);

    await viewModel.resendVerification.execute();

    expect(viewModel.resendVerification.error, isTrue);
    expect((viewModel.resendVerification.result as Error).error, exception);
    verifyNever(() => mockAuthRepository.verifyEmail(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        ));
  });

  test('Ok(null) marks the command as completed', () async {
    when(() => mockAuthRepository.verifyEmail(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    final viewModel = VerifyEmailViewModel(
      authRepository: mockAuthRepository,
      email: 'a@b.com',
    );

    await viewModel.resendVerification.execute();

    expect(viewModel.resendVerification.completed, isTrue);
    expect(viewModel.resendVerification.error, isFalse);
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('resend failed');
    when(() => mockAuthRepository.verifyEmail(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => Result.error(exception));

    final viewModel = VerifyEmailViewModel(
      authRepository: mockAuthRepository,
      email: 'a@b.com',
    );

    await viewModel.resendVerification.execute();

    expect(viewModel.resendVerification.error, isTrue);
    expect((viewModel.resendVerification.result as Error).error, exception);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(() => mockAuthRepository.verifyEmail(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    final viewModel = VerifyEmailViewModel(
      authRepository: mockAuthRepository,
      email: 'a@b.com',
    );

    var notifications = 0;
    viewModel.resendVerification.addListener(() => notifications++);

    await viewModel.resendVerification.execute();

    expect(notifications, 2);
  });

  test('re-entrant execute calls only invoke the repository once', () async {
    final completer = Completer<Result<void>>();
    when(() => mockAuthRepository.verifyEmail(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) => completer.future);

    final viewModel = VerifyEmailViewModel(
      authRepository: mockAuthRepository,
      email: 'a@b.com',
    );

    final first = viewModel.resendVerification.execute();
    final second = viewModel.resendVerification.execute();

    completer.complete(const Result.ok(null));
    await first;
    await second;

    verify(() => mockAuthRepository.verifyEmail(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).called(1);
  });

  test('logout calls AuthRepository.logout', () async {
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => const Result.ok(null));

    final viewModel = VerifyEmailViewModel(
      authRepository: mockAuthRepository,
      email: 'a@b.com',
    );

    await viewModel.logout.execute();

    verify(() => mockAuthRepository.logout()).called(1);
    expect(viewModel.logout.completed, isTrue);
    expect(viewModel.logout.error, isFalse);
  });

  test('logout marks the command as error and preserves the error', () async {
    final exception = Exception('logout failed');
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => Result.error(exception));

    final viewModel = VerifyEmailViewModel(
      authRepository: mockAuthRepository,
      email: 'a@b.com',
    );

    await viewModel.logout.execute();

    expect(viewModel.logout.error, isTrue);
    expect((viewModel.logout.result as Error).error, exception);
  });
}
