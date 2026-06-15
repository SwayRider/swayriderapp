import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/ui/new_password/view_models/new_password_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late NewPasswordViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = NewPasswordViewModel(authRepository: mockAuthRepository);
  });

  test('initial state is idle', () {
    expect(viewModel.resetPassword.running, isFalse);
    expect(viewModel.resetPassword.completed, isFalse);
    expect(viewModel.resetPassword.error, isFalse);
    expect(viewModel.resetPassword.result, isNull);
  });

  test('execute calls AuthRepository.resetPassword with userId, token and newPassword', () async {
    when(() => mockAuthRepository.resetPassword(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.resetPassword.execute(('user-1', 'token-1', 'new-pw'));

    verify(() => mockAuthRepository.resetPassword(
          userId: 'user-1',
          token: 'token-1',
          newPassword: 'new-pw',
        )).called(1);
  });

  test('Ok(null) marks the command as completed', () async {
    when(() => mockAuthRepository.resetPassword(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.resetPassword.execute(('user-1', 'token-1', 'new-pw'));

    expect(viewModel.resetPassword.completed, isTrue);
    expect(viewModel.resetPassword.error, isFalse);
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('reset failed');
    when(() => mockAuthRepository.resetPassword(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => Result.error(exception));

    await viewModel.resetPassword.execute(('user-1', 'token-1', 'new-pw'));

    expect(viewModel.resetPassword.error, isTrue);
    expect((viewModel.resetPassword.result as Error).error, exception);
  });

  test('checkPasswordStrength delegates to AuthRepository.checkPasswordStrength', () async {
    when(() => mockAuthRepository.checkPasswordStrength(password: any(named: 'password')))
        .thenAnswer((_) async => const Result.ok(true));

    final result = await viewModel.checkPasswordStrength('pw');

    expect((result as Ok<bool>).value, isTrue);
    verify(() => mockAuthRepository.checkPasswordStrength(password: 'pw')).called(1);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(() => mockAuthRepository.resetPassword(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Result.ok(null));

    var notifications = 0;
    viewModel.resetPassword.addListener(() => notifications++);

    await viewModel.resetPassword.execute(('user-1', 'token-1', 'new-pw'));

    expect(notifications, 2);
  });

  test('re-entrant execute calls only invoke the repository once', () async {
    final completer = Completer<Result<void>>();
    when(() => mockAuthRepository.resetPassword(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) => completer.future);

    final first = viewModel.resetPassword.execute(('user-1', 'token-1', 'new-pw'));
    final second = viewModel.resetPassword.execute(('user-1', 'token-1', 'new-pw'));

    completer.complete(const Result.ok(null));
    await first;
    await second;

    verify(() => mockAuthRepository.resetPassword(
          userId: any(named: 'userId'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        )).called(1);
  });
}
