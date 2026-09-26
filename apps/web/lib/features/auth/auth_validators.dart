final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _uppercasePattern = RegExp(r'[A-Z]');
final _lowercasePattern = RegExp(r'[a-z]');
final _digitPattern = RegExp(r'\d');
final _symbolPattern = RegExp(r'[^A-Za-z0-9\s]');

String? validateRequiredName(String? value, String label) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return '$label is required';
  if (name.length > 20) return '$label must not exceed 20 characters';
  return null;
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
  return null;
}

String? validatePhoneDigits(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) return 'Phone number is required';
  if (!RegExp(r'^\d+$').hasMatch(phone)) {
    return 'Phone number must contain digits only';
  }
  return null;
}

String? validatePassword(
  String? value, {
  String? firstName,
  String? lastName,
  String? phoneNumber,
}) {
  final password = value ?? '';
  if (password.length < 12) return 'Password must be at least 12 characters';
  if (!_uppercasePattern.hasMatch(password) ||
      !_lowercasePattern.hasMatch(password) ||
      !_digitPattern.hasMatch(password) ||
      !_symbolPattern.hasMatch(password)) {
    return 'Include an uppercase, lowercase, number, and symbol';
  }

  final normalizedPassword = password.toLowerCase();
  for (final name in [firstName, lastName]) {
    final normalizedName = name?.trim().toLowerCase() ?? '';
    if (normalizedName.isNotEmpty &&
        normalizedPassword.contains(normalizedName)) {
      return 'Password must not contain your name';
    }
  }

  final phoneDigits = (phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');
  if (phoneDigits.isNotEmpty && password.contains(phoneDigits)) {
    return 'Password must not contain your phone number';
  }
  return null;
}
