import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/ui/mfa_verify/view_models/mfa_verify_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MfaVerifyViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = MfaVerifyViewModel(
      authRepository: mockAuthRepository,
      mfaToken: 'challenge-token-1',
    );
  });

  test('initial state is idle', () {
    expect(viewModel.verify.running, isFalse);
    expect(viewModel.verify.completed, isFalse);
    expect(viewModel.invalidCode, isFalse);
  });

  test('verify passes the token and code to the repository', () async {
    when(
      () => mockAuthRepository.verifyMfa(
        mfaToken: any(named: 'mfaToken'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => const Result.ok(null));

    await viewModel.verify.execute('123456');

    verify(
      () => mockAuthRepository.verifyMfa(
        mfaToken: 'challenge-token-1',
        code: '123456',
      ),
    ).called(1);
    expect(viewModel.verify.completed, isTrue);
    expect(viewModel.invalidCode, isFalse);
  });

  test('Error result marks invalidCode', () async {
    final exception = Exception('invalid code');
    when(
      () => mockAuthRepository.verifyMfa(
        mfaToken: any(named: 'mfaToken'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => Result.error(exception));

    await viewModel.verify.execute('000000');

    expect(viewModel.invalidCode, isTrue);
    expect((viewModel.verify.result as Error).error, exception);
  });
}
