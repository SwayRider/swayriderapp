import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/ui/change_password/view_models/change_password_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late ChangePasswordViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = ChangePasswordViewModel(authRepository: mockAuthRepository);
  });

  test('initial state is idle', () {
    expect(viewModel.changePassword.running, isFalse);
    expect(viewModel.changePassword.completed, isFalse);
    expect(viewModel.changePassword.error, isFalse);
    expect(viewModel.changePassword.result, isNull);
  });

  test('execute calls AuthRepository.changePassword with oldPassword and newPassword', () async {
    when(() => mockAuthRepository.changePassword(
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.changePassword.execute(('old-pw', 'new-pw'));

    verify(() => mockAuthRepository.changePassword(
          oldPassword: 'old-pw',
          newPassword: 'new-pw',
        )).called(1);
  });

  test('Ok(null) marks the command as completed', () async {
    when(() => mockAuthRepository.changePassword(
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Result.ok(null));

    await viewModel.changePassword.execute(('old-pw', 'new-pw'));

    expect(viewModel.changePassword.completed, isTrue);
    expect(viewModel.changePassword.error, isFalse);
  });

  test('Error(e) marks the command as error and preserves the error', () async {
    final exception = Exception('change password failed');
    when(() => mockAuthRepository.changePassword(
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => Result.error(exception));

    await viewModel.changePassword.execute(('old-pw', 'new-pw'));

    expect(viewModel.changePassword.error, isTrue);
    expect((viewModel.changePassword.result as Error).error, exception);
  });

  test('checkPasswordStrength delegates to AuthRepository.checkPasswordStrength', () async {
    when(() => mockAuthRepository.checkPasswordStrength(password: any(named: 'password')))
        .thenAnswer((_) async => const Result.ok(true));

    final result = await viewModel.checkPasswordStrength('pw');

    expect((result as Ok<bool>).value, isTrue);
    verify(() => mockAuthRepository.checkPasswordStrength(password: 'pw')).called(1);
  });

  test('notifies listeners exactly twice per execute cycle', () async {
    when(() => mockAuthRepository.changePassword(
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Result.ok(null));

    var notifications = 0;
    viewModel.changePassword.addListener(() => notifications++);

    await viewModel.changePassword.execute(('old-pw', 'new-pw'));

    expect(notifications, 2);
  });

  test('re-entrant execute calls only invoke the repository once', () async {
    final completer = Completer<Result<void>>();
    when(() => mockAuthRepository.changePassword(
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) => completer.future);

    final first = viewModel.changePassword.execute(('old-pw', 'new-pw'));
    final second = viewModel.changePassword.execute(('old-pw', 'new-pw'));

    completer.complete(const Result.ok(null));
    await first;
    await second;

    verify(() => mockAuthRepository.changePassword(
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        )).called(1);
  });
}
