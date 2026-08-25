import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/ui/mfa_reset_request/view_models/mfa_reset_request_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MfaResetRequestViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = MfaResetRequestViewModel(authRepository: mockAuthRepository);
  });

  test('initial state is idle', () {
    expect(viewModel.requestReset.running, isFalse);
    expect(viewModel.requestReset.completed, isFalse);
  });

  test(
    'requestReset passes email, password, and backup code to the repository',
    () async {
      when(
        () => mockAuthRepository.requestMfaReset(
          email: any(named: 'email'),
          password: any(named: 'password'),
          backupCode: any(named: 'backupCode'),
          mfaResetUrl: any(named: 'mfaResetUrl'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));

      await viewModel.requestReset.execute((
        'user@example.com',
        'S3cret!',
        'ABCD1234',
      ));

      verify(
        () => mockAuthRepository.requestMfaReset(
          email: 'user@example.com',
          password: 'S3cret!',
          backupCode: 'ABCD1234',
          mfaResetUrl: any(named: 'mfaResetUrl'),
        ),
      ).called(1);
      expect(viewModel.requestReset.completed, isTrue);
    },
  );

  test('Error result marks the command as error', () async {
    final exception = Exception('invalid backup code');
    when(
      () => mockAuthRepository.requestMfaReset(
        email: any(named: 'email'),
        password: any(named: 'password'),
        backupCode: any(named: 'backupCode'),
        mfaResetUrl: any(named: 'mfaResetUrl'),
      ),
    ).thenAnswer((_) async => Result.error(exception));

    await viewModel.requestReset.execute((
      'user@example.com',
      'S3cret!',
      'WRONG123',
    ));

    expect(viewModel.requestReset.error, isTrue);
    expect((viewModel.requestReset.result as Error).error, exception);
  });
}
