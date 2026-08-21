import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/domain/models/mfa/mfa_setup_info.dart';
import 'package:swayriderapp/ui/mfa_setup/view_models/mfa_setup_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MfaSetupViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = MfaSetupViewModel(authRepository: mockAuthRepository);
  });

  test('initial state is idle', () {
    expect(viewModel.setupInfo, isNull);
    expect(viewModel.backupCodes, isNull);
    expect(viewModel.invalidCode, isFalse);
    expect(viewModel.startSetup.running, isFalse);
    expect(viewModel.enable.running, isFalse);
  });

  group('startSetup', () {
    test('Ok result stores setupInfo', () async {
      when(() => mockAuthRepository.setupMfa()).thenAnswer(
        (_) async => const Result.ok(
          MfaSetupInfo(
            secret: 'ABCD EFGH',
            otpauthUrl: 'otpauth://totp/SwayRider:a@b.com?secret=ABC',
            qrPngBase64: 'aGVsbG8=',
          ),
        ),
      );

      await viewModel.startSetup.execute(null);

      expect(viewModel.startSetup.completed, isTrue);
      expect(viewModel.startSetup.error, isFalse);
      final info = viewModel.setupInfo;
      expect(info, isNotNull);
      expect(info!.secret, 'ABCD EFGH');
      expect(info.otpauthUrl, 'otpauth://totp/SwayRider:a@b.com?secret=ABC');
      expect(info.qrPngBase64, 'aGVsbG8=');
    });

    test('Error result passes through without storing setupInfo', () async {
      final exception = Exception('setup failed');
      when(
        () => mockAuthRepository.setupMfa(),
      ).thenAnswer((_) async => Result.error(exception));

      await viewModel.startSetup.execute(null);

      expect(viewModel.startSetup.error, isTrue);
      expect((viewModel.startSetup.result as Error).error, exception);
      expect(viewModel.setupInfo, isNull);
    });
  });

  group('enable', () {
    test('Ok result stores backupCodes', () async {
      when(
        () => mockAuthRepository.enableMfa(code: any(named: 'code')),
      ).thenAnswer((_) async => const Result.ok(['ABCD-EFGH', 'JKLM-NOPQ']));

      await viewModel.enable.execute('123456');

      expect(viewModel.enable.completed, isTrue);
      expect(viewModel.invalidCode, isFalse);
      expect(viewModel.backupCodes, ['ABCD-EFGH', 'JKLM-NOPQ']);
      verify(() => mockAuthRepository.enableMfa(code: '123456')).called(1);
    });

    test('Error result marks invalidCode and stores no backup codes', () async {
      final exception = Exception('invalid code');
      when(
        () => mockAuthRepository.enableMfa(code: any(named: 'code')),
      ).thenAnswer((_) async => Result.error(exception));

      await viewModel.enable.execute('000000');

      expect(viewModel.invalidCode, isTrue);
      expect((viewModel.enable.result as Error).error, exception);
      expect(viewModel.backupCodes, isNull);
    });
  });
}
