import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mitv/src/email_auth.dart';
import 'package:mitv/src/library_store.dart';
import 'package:mitv/src/quick_unlock.dart';
import 'package:mitv/src/quick_unlock_ui.dart';

class Vault implements QuickUnlockVault {
  String? value;
  bool unavailable = false;
  @override
  Future<String?> read() async {
    if (unavailable) throw StateError('locked');
    return value;
  }

  @override
  Future<void> write(String input) async => value = input;
  @override
  Future<void> clear() async => value = null;
}

const owner = '11111111-1111-4111-8111-111111111111';
Future<SupabaseClient> authentication({bool signedIn = true}) async {
  final user = {
    'id': owner,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'fixture@example.test',
    'created_at': '2026-01-01T00:00:00Z',
    'email_confirmed_at': '2026-01-01T00:00:00Z',
    'app_metadata': {
      'provider': 'email',
      'providers': ['email'],
    },
    'user_metadata': {'display_name': 'مشاهد اختبار'},
    'is_anonymous': false,
  };
  final client = SupabaseClient(
    'https://fixture.supabase.co',
    'fixture',
    httpClient: MockClient(
      (_) async => http.Response(
        jsonEncode(user),
        200,
        headers: {'content-type': 'application/json'},
      ),
    ),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  if (signedIn) {
    final expiry =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000;
    final claims = base64Url
        .encode(utf8.encode(jsonEncode({'sub': owner, 'exp': expiry})))
        .replaceAll('=', '');
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'header.$claims.signature',
        'refresh_token': 'fixture',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': expiry,
        'user': user,
      }),
    );
  }
  return client;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'PIN hides the owned navigator and deep links until correct unlock',
    (tester) async {
      final client = (await tester.runAsync(() => authentication()))!;
      final vault = Vault();
      final service = QuickUnlockService(
        vault: vault,
        derive: (input) async =>
            sha256.convert(utf8.encode(jsonEncode(input))).toString(),
      );
      // Cryptographic vector coverage lives in quick_unlock_test; here test route gating.
      await service.enroll(owner, '7391');
      await tester.pumpWidget(
        MaterialApp(
          home: DeviceUnlockGate(
            storeFuture: LocalLibraryStore.create(),
            unlockService: service,
            authenticationForTesting: (_) async => NajdEmailAuth(client, null),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('private deep link')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('private deep link'), findsNothing);
      expect(find.text('رمز الدخول السريع'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '0000');
      await tester.tap(find.text('فتح نجد'));

      await tester.pumpAndSettle();
      expect(find.text('private deep link'), findsNothing);
      expect(find.text('الرمز غير صحيح.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '7391');
      await tester.tap(find.text('فتح نجد'));

      await tester.pumpAndSettle();
      expect(find.text('private deep link'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => client.dispose());
    },
  );
  testWidgets('guest does not depend on secure storage or an account', (
    tester,
  ) async {
    final client = (await tester.runAsync(
      () => authentication(signedIn: false),
    ))!;
    final vault = Vault()..unavailable = true;
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceUnlockGate(
          storeFuture: LocalLibraryStore.create(),
          unlockService: QuickUnlockService(vault: vault),
          authenticationForTesting: (_) async => NajdEmailAuth(client, null),
          child: const Text('local library'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('local library'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => client.dispose());
  });
  testWidgets('unreadable vault fails closed and offers password recovery', (
    tester,
  ) async {
    final client = (await tester.runAsync(() => authentication()))!;
    final vault = Vault()..unavailable = true;
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceUnlockGate(
          storeFuture: LocalLibraryStore.create(),
          unlockService: QuickUnlockService(vault: vault),
          authenticationForTesting: (_) async => NajdEmailAuth(client, null),
          child: const Text('private library'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('private library'), findsNothing);
    await tester.tap(find.text('الدخول بالبريد وكلمة المرور'));
    await tester.pumpAndSettle();
    expect(find.byType(NajdEmailAuthPanel), findsOneWidget);
    expect(find.text('private library'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => client.dispose());
  });
}
