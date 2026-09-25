import 'package:flutter_test/flutter_test.dart';
import 'package:securebypay_web/main.dart';
import 'package:securebypay_web/features/auth/verification_page.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('shows the sign-in experience', (tester) async {
    await tester.pumpWidget(const SecureByPayApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('shows the email verification challenge', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VerificationPage(
      challengeId: 'challenge-1',
      destination: 'p***@example.com',
      purpose: 'login',
    )));

    expect(find.text('Confirm it’s you'), findsOneWidget);
    expect(find.textContaining('p***@example.com'), findsOneWidget);
    expect(find.text('Verify and continue'), findsOneWidget);
  });
}
