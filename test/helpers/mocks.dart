import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/data/repositories/auth/auth_repository.dart';
import 'package:swayriderapp/data/repositories/search/search_repository.dart';
import 'package:swayriderapp/data/repositories/tiles/tiles_repository.dart';
import 'package:swayriderapp/data/services/api/auth_api_client.dart';
import 'package:swayriderapp/data/services/api/model/auth/auth.dart';
import 'package:swayriderapp/data/services/location_service.dart';
import 'package:swayriderapp/data/services/shared_preferences_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthApiClient extends Mock implements AuthApiClient {}

class MockSharedPreferencesService extends Mock
    implements SharedPreferencesService {}

class MockTilesRepository extends Mock implements TilesRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockSearchRepository extends Mock implements SearchRepository {}

/// Registers fallback values for freezed request types used as `any()`
/// matchers in `verify()`/`when()` calls against [MockAuthApiClient].
void registerFallbacks() {
  registerFallbackValue(const LoginRequest(email: '', password: ''));
  registerFallbackValue(
    const RegisterRequest(
      email: '',
      password: '',
      verificationUrl: '',
    ),
  );
  registerFallbackValue(RefreshRequest(refreshToken: ''));
  registerFallbackValue(const LogoutRequest());
  registerFallbackValue(
    const PasswordResetRequest(email: '', resetUrl: ''),
  );
  registerFallbackValue(
    const ResetPasswordRequest(userId: '', token: '', newPassword: ''),
  );
  registerFallbackValue(
    const VerifyEmailRequest(email: '', verificationUrl: ''),
  );
  registerFallbackValue(
    const ChangePasswordRequest(oldPassword: '', newPassword: ''),
  );
  registerFallbackValue(const CheckPasswordStrengthRequest(password: ''));
  registerFallbackValue(() => null as String?);
}
