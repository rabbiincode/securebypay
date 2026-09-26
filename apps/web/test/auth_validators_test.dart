import 'package:flutter_test/flutter_test.dart';
import 'package:securebypay_web/features/auth/auth_validators.dart';

void main() {
  test('validates names, email, and phone number', () {
    expect(
        validateRequiredName('ABCDEFGHIJKLMNOPQRSTU', 'First name'), isNotNull);
    expect(validateRequiredName('Ada', 'First name'), isNull);
    expect(validateEmail('invalid'), isNotNull);
    expect(validateEmail('ada@example.com'), isNull);
    expect(validatePhoneDigits('080a'), isNotNull);
    expect(validatePhoneDigits('8012345678'), isNull);
  });

  test('requires strong passwords without personal data', () {
    expect(validatePassword('weak-password'), isNotNull);
    expect(validatePassword('Short1!a'),
        'Password must be at least 12 characters');
    expect(validatePassword('StrongPassword123!'), isNull);
    expect(
      validatePassword('AdaStrong123!', firstName: 'Ada'),
      'Password must not contain your name',
    );
    expect(
      validatePassword('Strong8012345678!', phoneNumber: '8012345678'),
      'Password must not contain your phone number',
    );
  });
}
