import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tank_speak/core/api_exception.dart';
import 'package:tank_speak/screens/auth/login_screen.dart';
import 'package:tank_speak/widgets/state_views.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('login screen shows the backend rejection', (tester) async {
    installFakeBackend((_) async => fixtureResponse('login_failure.json'));

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('Welcome to TankSpeak'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'user');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect username or password.'), findsOneWidget);
  });

  testWidgets('login screen shows a session notice', (tester) async {
    installFakeBackend((_) async => jsonResponse({}));
    await tester.pumpWidget(const MaterialApp(
        home: LoginScreen(notice: 'Your session has expired.')));
    expect(find.text('Your session has expired.'), findsOneWidget);
  });

  testWidgets('403 shows access denied without a retry button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ErrorView(
          error: ApiException.fromResponse(403, {'detail': 'Forbidden'}),
          onRetry: () {},
        ),
      ),
    ));
    expect(find.text('Access denied'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('network errors offer a retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ErrorView(
          error: ApiException(
              kind: ApiErrorKind.network, message: 'Cannot reach the server'),
          onRetry: () => retried = true,
        ),
      ),
    ));
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });
}
