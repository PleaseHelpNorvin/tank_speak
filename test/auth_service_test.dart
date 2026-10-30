import 'package:flutter_test/flutter_test.dart';
import 'package:tank_speak/core/api_exception.dart';
import 'package:tank_speak/services/auth_service.dart';

import 'helpers/fakes.dart';

void main() {
  test('login stores the token and loads the profile', () async {
    final tokens = installFakeBackend((request) async {
      if (request.url.path == '/api/login') {
        return fixtureResponse('login_success.json');
      }
      expect(request.headers['Authorization'], 'Bearer test-token');
      return fixtureResponse('me_owner.json');
    });

    final me = await AuthService.instance.login(' user ', 'secret');
    expect(me.id, 3);
    expect(tokens.token, 'test-token');
    expect(AuthService.instance.isSignedIn, isTrue);
    expect(sentRequests.first.body, '{"username":"user","password":"secret"}');
  });

  test('bad credentials (200 + success:false) are rejected', () async {
    final tokens =
        installFakeBackend((_) async => fixtureResponse('login_failure.json'));
    await expectLater(
      AuthService.instance.login('user', 'wrong'),
      throwsA(isA<ApiException>().having(
          (e) => e.message, 'message', 'Incorrect username or password.')),
    );
    expect(tokens.token, isNull);
    expect(AuthService.instance.isSignedIn, isFalse);
  });

  test('administrator accounts are refused and their token revoked', () async {
    final tokens = installFakeBackend((request) async {
      switch (request.url.path) {
        case '/api/login':
          return jsonResponse({'success': true, 'token': 'adm', 'type': 'Bearer'});
        case '/api/me':
          return jsonResponse({
            'id': 1,
            'username': 'superadmin',
            'is_super_admin': true,
            'owner': [],
            'manager': [],
          });
        case '/api/logout':
          return jsonResponse({'message': 'Logged out successfully'});
      }
      return jsonResponse({}, 404);
    });

    await expectLater(
      AuthService.instance.login('superadmin', 'x'),
      throwsA(isA<ApiException>().having(
          (e) => e.message, 'message', AuthService.adminBlockedMessage)),
    );
    expect(tokens.token, isNull);
    expect(AuthService.instance.isSignedIn, isFalse);
    final logout = sentRequests.firstWhere((r) => r.url.path == '/api/logout');
    expect(logout.url.queryParameters['current_token'], 'adm');
  });

  test('restore with a valid token signs in', () async {
    installFakeBackend((_) async => fixtureResponse('me_member.json'),
        token: 'stored');
    expect(await AuthService.instance.restore(), SessionRestore.signedIn);
    expect(AuthService.instance.me!.username, 'user2');
  });

  test('restore without a token is signed out', () async {
    installFakeBackend((_) async => fixtureResponse('me_member.json'));
    expect(await AuthService.instance.restore(), SessionRestore.signedOut);
    expect(sentRequests, isEmpty);
  });

  test('restore with an expired token clears it', () async {
    final tokens = installFakeBackend(
        (_) async => jsonResponse({'detail': 'Token expired'}, 401),
        token: 'old');
    expect(await AuthService.instance.restore(), SessionRestore.signedOut);
    expect(tokens.token, isNull);
  });

  test('restore while offline keeps the token', () async {
    final tokens = installFakeBackend(
        (_) async => jsonResponse({'detail': 'oops'}, 503),
        token: 'keep');
    await expectLater(AuthService.instance.restore(), throwsA(isA<ApiException>()));
    expect(tokens.token, 'keep');
  });

  test('logout revokes on the server and clears locally', () async {
    final tokens = installFakeBackend((request) async {
      if (request.url.path == '/api/me') return fixtureResponse('me_member.json');
      return jsonResponse({'message': 'Logged out successfully'});
    }, token: 'tok');
    await AuthService.instance.restore();
    await AuthService.instance.logout();
    expect(tokens.token, isNull);
    expect(AuthService.instance.isSignedIn, isFalse);
    final r = sentRequests.last;
    expect(r.url.path, '/api/logout');
    expect(r.url.queryParameters['current_token'], 'tok');
    expect(r.headers.containsKey('Authorization'), isFalse);
  });

  test('logout still clears locally when the server is unreachable', () async {
    final tokens = installFakeBackend((request) async {
      if (request.url.path == '/api/me') return fixtureResponse('me_member.json');
      throw Exception('offline');
    }, token: 'tok');
    await AuthService.instance.restore();
    await AuthService.instance.logout();
    expect(tokens.token, isNull);
  });

  test('a 401 during use signs the user out with a message', () async {
    var meCalls = 0;
    installFakeBackend((request) async {
      if (request.url.path == '/api/me' && meCalls++ == 0) {
        return fixtureResponse('me_member.json');
      }
      return jsonResponse({'detail': 'Token expired'}, 401);
    }, token: 'tok');
    await AuthService.instance.restore();
    expect(AuthService.instance.isSignedIn, isTrue);

    await expectLater(AuthService.instance.fetchMe(), throwsA(isA<ApiException>()));
    await Future<void>.delayed(Duration.zero);

    expect(AuthService.instance.isSignedIn, isFalse);
    expect(AuthService.instance.takeSessionEndedMessage(),
        'Your session has expired. Please sign in again.');
  });
}
