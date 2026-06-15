import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:swayriderapp/data/repositories/auth/auth_repository.dart';
import 'package:swayriderapp/data/repositories/auth/auth_repository_remote.dart';
import 'package:swayriderapp/data/services/api/auth_api_client.dart';
import 'package:swayriderapp/data/services/api/auth_header_provider.dart';
import 'package:swayriderapp/routing/router.dart';
import 'package:swayriderapp/ui/core/localization/applocalization.dart';
import 'package:swayriderapp/ui/login/widgets/login_screen.dart';
import 'package:swayriderapp/utils/result.dart';

import '../helpers/mocks.dart';

void main() {
  late MockAuthApiClient mockApiClient;
  late MockSharedPreferencesService mockPrefs;
  late AuthRepositoryRemote authRepository;

  setUpAll(registerFallbacks);

  setUp(() {
    mockApiClient = MockAuthApiClient();
    mockPrefs = MockSharedPreferencesService();
    when(() => mockApiClient.authHeaderProvider = any<AuthHeaderProvider>())
        .thenReturn(() => null);
    when(() => mockPrefs.saveAccessToken(any()))
        .thenAnswer((_) async => const Result.ok(null));
    when(() => mockPrefs.saveRefreshToken(any()))
        .thenAnswer((_) async => const Result.ok(null));
    authRepository = AuthRepositoryRemote(
      authApiClient: mockApiClient,
      sharedPreferencesService: mockPrefs,
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthRepository>.value(
        value: authRepository,
        child: MaterialApp.router(
          localizationsDelegates: [AppLocalizationDelegate()],
          routerConfig: router(authRepository),
        ),
      ),
    );
  }

  testWidgets(
    'a stale access token with an invalid refresh token redirects to '
    '/login without crashing',
    (tester) async {
      // Mimic real SharedPreferences: saving null actually clears what's
      // returned by subsequent fetches.
      String? storedAccess = 'stale-access';
      String? storedRefresh = 'stale-refresh';
      when(() => mockPrefs.fetchAccessToken())
          .thenAnswer((_) async => Result.ok(storedAccess));
      when(() => mockPrefs.fetchRefreshToken())
          .thenAnswer((_) async => Result.ok(storedRefresh));
      when(() => mockPrefs.saveAccessToken(any())).thenAnswer((invocation) async {
        storedAccess = invocation.positionalArguments[0] as String?;
        return const Result.ok(null);
      });
      when(() => mockPrefs.saveRefreshToken(any())).thenAnswer((invocation) async {
        storedRefresh = invocation.positionalArguments[0] as String?;
        return const Result.ok(null);
      });
      when(() => mockApiClient.me()).thenAnswer(
          (_) async => const Result.error(UnauthorizedException()));
      when(() => mockApiClient.refresh(any())).thenAnswer(
          (_) async => const Result.error(HttpException('Refresh error')));

      await pumpApp(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
