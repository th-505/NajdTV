import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitv/src/cloud_library.dart';
import 'package:mitv/src/email_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> user({bool anonymous = false}) => {
  'id': '11111111-1111-4111-8111-111111111111',
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': anonymous ? '' : 'qa@example.com',
  'created_at': '2026-01-01T00:00:00Z',
  'app_metadata': {
    'provider': 'email',
    'providers': ['email'],
  },
  'user_metadata': {},
  'is_anonymous': anonymous,
  'email_confirmed_at': anonymous ? null : '2026-01-01T00:00:00Z',
};
Map<String, dynamic> session({bool anonymous = false}) {
  final exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  final claims = base64Url
      .encode(utf8.encode(jsonEncode({'sub': user()['id'], 'exp': exp})))
      .replaceAll('=', '');
  return {
    'access_token': 'header.$claims.signature',
    'refresh_token': 'fixture-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': exp,
    'user': user(anonymous: anonymous),
  };
}

SupabaseClient sdk(Future<http.Response> Function(http.Request) handler) =>
    SupabaseClient(
      'https://fixture.supabase.co',
      'sb_publishable_fixture',
      httpClient: MockClient(handler),
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
http.Response jsonReply(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

class RejectingAuth implements NajdAccountAuthentication {
  int requests = 0;
  @override
  Future<bool> checkConfirmation() async => false;
  @override
  Future<bool> submit(
    String email,
    String password, {
    required bool create,
  }) async {
    requests++;
    throw const AuthException('PRIVATE_INTERNAL_DETAIL', statusCode: '400');
  }

  @override
  Future<bool> verify(String email, String token) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'starting without a session never creates an anonymous account',
    () async {
      var calls = 0;
      final client = sdk((request) async {
        calls++;
        return jsonReply({}, 500);
      });
      final adapter = AnonymousLibraryTransport(
        client,
        await SharedPreferences.getInstance(),
      );
      await expectLater(adapter.prepare(), throwsA(isA<StateError>()));
      expect(calls, 0);
      expect(client.auth.currentUser, isNull);
      await client.dispose();
    },
  );
  test('real email/password login uses Auth and logout never fabricates a new identity', () async {
    final paths = <String>[];
    final client = sdk((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('/token')) {
        expect(request.url.queryParameters['grant_type'], 'password');
        final body = jsonDecode(request.body) as Map;
        expect(body['email'], 'qa@example.com');
        expect(body['password'], 'correct horse battery staple');
        return jsonReply(session());
      }
      if (request.url.path.endsWith('/logout')) return http.Response('', 204);
      throw StateError('Unexpected endpoint');
    });
    final auth = NajdEmailAuth(client, null);
    expect(
      await auth.submit(
        ' qa@example.com ',
        'correct horse battery staple',
        create: false,
      ),
      isTrue,
    );
    await auth.signOut();
    expect(client.auth.currentUser, isNull);
    expect(paths, ['/auth/v1/token', '/auth/v1/logout']);
    await client.dispose();
  });
  test(
    'signup pending confirmation is never presented as a signed-in account',
    () async {
      final client = sdk((request) async {
        expect(request.url.path, '/auth/v1/signup');
        expect(
          request.url.queryParameters['redirect_to'],
          NajdEmailAuth.confirmationReturn,
        );
        return jsonReply(user());
      });
      final auth = NajdEmailAuth(client, null);
      expect(
        await auth.submit(
          'qa@example.com',
          'long enough secret phrase',
          create: true,
        ),
        isFalse,
      );
      expect(auth.signedIn, isFalse);
      expect(client.auth.currentSession, isNull);
      await client.dispose();
    },
  );
  test('legacy anonymous accounts upgrade the same UUID rather than losing their library', () async {
    final paths = <String>[];
    final client = sdk((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('/user')) {
        expect(
          request.url.queryParameters['redirect_to'],
          NajdEmailAuth.confirmationReturn,
        );
        return jsonReply(user(anonymous: true));
      }
      if (request.url.path.endsWith('/verify')) return jsonReply(session());
      throw StateError('Unexpected endpoint');
    });
    await client.auth.recoverSession(jsonEncode(session(anonymous: true)));
    final before = client.auth.currentUser!.id;
    final auth = NajdEmailAuth(client, null);
    expect(
      await auth.submit(
        'qa@example.com',
        'long enough secret phrase',
        create: true,
      ),
      isFalse,
    );
    expect(auth.verificationType, OtpType.emailChange);
    expect(await auth.verify('qa@example.com', '123456'), isTrue);
    expect(client.auth.currentUser!.id, before);
    expect(paths, ['/auth/v1/user', '/auth/v1/verify']);
    await client.dispose();
  });
  testWidgets(
    'registration validates confirmation locally and hides raw Auth errors',
    (tester) async {
      final auth = RejectingAuth();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NajdEmailAuthPanel(auth: auth, onSignedIn: () {}),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ليس لدي حساب — إنشاء حساب'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'qa@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'long enough secret phrase',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'different secret phrase',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'إنشاء الحساب'));
      await tester.pumpAndSettle();
      expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
      expect(auth.requests, 0);
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'long enough secret phrase',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'إنشاء الحساب'));
      await tester.pumpAndSettle();
      expect(auth.requests, 1);
      expect(find.textContaining('PRIVATE_INTERNAL_DETAIL'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('returning from the confirmation link refreshes the same legacy owner without a numeric OTP', () async {
    final client = sdk((request) async {
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'refresh_token');
      return jsonReply(session());
    });
    await client.auth.recoverSession(jsonEncode(session(anonymous: true)));
    final owner = client.auth.currentUser!.id;
    final auth = NajdEmailAuth(client, null);
    expect(await auth.checkConfirmation(), true);
    expect(client.auth.currentUser!.id, owner);
    expect(auth.signedIn, true);
    await client.dispose();
  });
}
