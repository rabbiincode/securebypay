import 'package:flutter_test/flutter_test.dart';
import 'package:securebypay_web/main.dart';
import 'package:securebypay_web/features/auth/auth_page.dart';
import 'package:securebypay_web/features/auth/password_reset_page.dart';
import 'package:securebypay_web/features/auth/verification_page.dart';
import 'package:securebypay_web/features/dashboard/dashboard_page.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('shows the sign-in experience', (tester) async {
    await tester.pumpWidget(const SecureByPayApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('shows the email verification challenge', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: VerificationPage(
      challengeId: 'challenge-1',
      destination: 'p***@example.com',
      purpose: 'login',
    )));

    expect(find.text('Confirm it’s you'), findsOneWidget);
    expect(find.textContaining('p***@example.com'), findsOneWidget);
    expect(find.text('Verify and continue'), findsOneWidget);
  });

  testWidgets('shows the signup experience with shared auth styling',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AuthPage(mode: AuthMode.signUp),
    ));

    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('+234'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    final passwordField = find.byType(TextFormField).at(4);
    await tester.ensureVisible(passwordField);
    await tester.pumpAndSettle();
    await tester.tap(passwordField);
    await tester.enterText(passwordField, 'ValidPassword123!');
    await tester.pump();
    expect(
      tester.widget<TextFormField>(passwordField).controller!.text,
      'ValidPassword123!',
    );
    await tester.enterText(passwordField, 'UpdatedPassword456!');
    await tester.pump();
    expect(
      tester.widget<TextFormField>(passwordField).controller!.text,
      'UpdatedPassword456!',
    );

    final phoneField = find.byType(TextFormField).at(3);
    await tester.ensureVisible(phoneField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+234'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ghana (+233)'));
    await tester.pumpAndSettle();
    expect(find.text('+233'), findsOneWidget);
  });

  testWidgets('signup remains stable while resizing to a mobile viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: AuthPage(mode: AuthMode.signUp),
    ));
    await tester.pumpAndSettle();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
  });

  testWidgets('dashboard remains stable across desktop and mobile breakpoints',
      (tester) async {
    final dashboard = <String, dynamic>{
      'user': {
        'firstName': 'Test',
        'lastName': 'User',
        'role': 'USER',
      },
      'walletBalance': '3000000.28',
      'metrics': {
        'totalShipments': 34,
        'totalExports': 34,
        'totalImports': 34,
      },
      'monthlyGrowth': [
        280,
        320,
        300,
        360,
        330,
        440,
        320,
        490,
        380,
        630,
        120,
        980
      ],
      'recentShipments': <dynamic>[],
    };
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: DashboardPage(loadDashboard: () async => dashboard),
    ));
    await tester.pumpAndSettle();

    for (final size in const [
      Size(899, 800),
      Size(768, 700),
      Size(390, 844),
      Size(1200, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'failed at $size');
    }
  });

  testWidgets('shows the forgot-password experience', (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: PasswordResetRequestPage()));

    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send reset code'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
  });

  testWidgets('shows the reset-password experience', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PasswordResetPage(challengeId: 'challenge-1'),
    ));

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Verification code'), findsOneWidget);
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Update password'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
  });
}
