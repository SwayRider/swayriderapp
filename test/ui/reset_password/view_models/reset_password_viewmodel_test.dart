import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/config/app_config.dart';
import 'package:swayriderapp/ui/reset_password/view_models/reset_password_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late ResetPasswordViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = ResetPasswordViewModel(authRepository: mockAuthRepository);
  });

  test('initial state is idle', () {
    expect(viewModel.requestReset.running, isFalse);
    expect(viewModel.requestReset.completed, isFalse);
    expect(viewModel.requestReset.error, isFalse);
    expect(viewModel.requestReset.result, isNull);
  });

  test('execute calls AuthRepository.requestPasswordReset with email and resetPasswordRedirectUrl', () async {
    when(() => mockAuthRepository.requestPasswordReset(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.requestReset.execute('a@b.com');

    verify(() => mockAuthRepository.requestPasswordReset(
          email: 'a@b.com',
          verificationUrl: AppConfig.resetPasswordRedirectUrl,
        )).called(1);
  });

  test('Ok(null) marks the command as completed', () async {
    when(() => mockAuthRepository.requestPasswordReset(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.requestReset.execute('a@b.com');

    expect(viewModel.requestReset.completed, isTrue);
    expect(viewModel.requestReset.error, isFalse);
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('reset failed');
    when(() => mockAuthRepository.requestPasswordReset(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => Result.error(exception));

    await viewModel.requestReset.execute('a@b.com');

    expect(viewModel.requestReset.error, isTrue);
    expect((viewModel.requestReset.result as Error).error, exception);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(() => mockAuthRepository.requestPasswordReset(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) async => const Result.ok(null));

    var notifications = 0;
    viewModel.requestReset.addListener(() => notifications++);

    await viewModel.requestReset.execute('a@b.com');

    expect(notifications, 2);
  });

  test('re-entrant execute calls only invoke the repository once', () async {
    final completer = Completer<Result<void>>();
    when(() => mockAuthRepository.requestPasswordReset(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).thenAnswer((_) => completer.future);

    final first = viewModel.requestReset.execute('a@b.com');
    final second = viewModel.requestReset.execute('a@b.com');

    completer.complete(const Result.ok(null));
    await first;
    await second;

    verify(() => mockAuthRepository.requestPasswordReset(
          email: any(named: 'email'),
          verificationUrl: any(named: 'verificationUrl'),
        )).called(1);
  });
}
