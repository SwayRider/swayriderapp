import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/ui/profile/view_models/mfa_profile_viewmodel.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MfaProfileViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = MfaProfileViewModel(authRepository: mockAuthRepository);
  });

  test('initial state is idle', () {
    expect(viewModel.enabled, isNull);
    expect(viewModel.loading, isFalse);
    expect(viewModel.error, isFalse);
  });

  group('load', () {
    test('Ok(true) sets enabled and clears loading/error', () async {
      when(
        () => mockAuthRepository.getMfaStatus(),
      ).thenAnswer((_) async => const Result.ok(true));

      await viewModel.load.execute();

      expect(viewModel.enabled, isTrue);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isFalse);
      expect(viewModel.load.completed, isTrue);
    });

    test('Ok(false) sets enabled to false', () async {
      when(
        () => mockAuthRepository.getMfaStatus(),
      ).thenAnswer((_) async => const Result.ok(false));

      await viewModel.load.execute();

      expect(viewModel.enabled, isFalse);
      expect(viewModel.error, isFalse);
    });

    test('Error result sets error and leaves enabled null', () async {
      final exception = Exception('status failed');
      when(
        () => mockAuthRepository.getMfaStatus(),
      ).thenAnswer((_) async => Result.error(exception));

      await viewModel.load.execute();

      expect(viewModel.error, isTrue);
      expect((viewModel.load.result as Error).error, exception);
      expect(viewModel.enabled, isNull);
    });
  });

  group('disable', () {
    test('Ok result passes the password through and completes', () async {
      when(
        () => mockAuthRepository.disableMfa(password: any(named: 'password')),
      ).thenAnswer((_) async => const Result.ok(null));

      await viewModel.disable.execute('pw');

      expect(viewModel.disable.completed, isTrue);
      expect(viewModel.disable.error, isFalse);
      verify(() => mockAuthRepository.disableMfa(password: 'pw')).called(1);
    });

    test('Error result passes through', () async {
      final exception = Exception('disable failed');
      when(
        () => mockAuthRepository.disableMfa(password: any(named: 'password')),
      ).thenAnswer((_) async => Result.error(exception));

      await viewModel.disable.execute('pw');

      expect(viewModel.disable.error, isTrue);
      expect((viewModel.disable.result as Error).error, exception);
    });
  });
}
