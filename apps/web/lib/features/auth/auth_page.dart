import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import 'auth_layout.dart';
import 'auth_validators.dart';

enum AuthMode { signIn, signUp }

class AuthPage extends StatefulWidget {
  const AuthPage({required this.mode, super.key});
  final AuthMode mode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = apiClient;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String _countryDialCode = '+234';
  String? _error;

  bool get _isSignUp => widget.mode == AuthMode.signUp;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _password
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      late final Map<String, dynamic> result;
      if (_isSignUp) {
        final localPhone = _phone.text.trim().replaceFirst(RegExp(r'^0+'), '');
        result = await _api.signUp({
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'email': _email.text.trim(),
          'phoneNumber': '$_countryDialCode$localPhone',
          'password': _password.text,
        });
      } else {
        result = await _api.signIn(_email.text.trim(), _password.text);
      }
      if (mounted) {
        final query = Uri(queryParameters: {
          'challengeId': result['challengeId'] as String,
          'destination': result['destination'] as String,
          'purpose': _isSignUp ? 'email' : 'login',
        }).query;
        context.go('/verify?$query');
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Unable to connect. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      AuthShell(signupHero: _isSignUp, child: _buildForm());

  Widget _buildForm() {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _isSignUp ? 536 : 453),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _isSignUp
                          ? 'Create an account'
                          : 'Sign in to your account',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: _isSignUp
                              ? 'Sign up for Myafrimall and gain unlimited access to shipping to over 300 countries from Nigeria. Do you already have an account? '
                              : 'Log in to Myafrimall to enjoy seamless shipping to over 300\ncountries right from Nigeria. Don’t have an account yet? '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: InkWell(
                          onTap: () =>
                              context.go(_isSignUp ? '/sign-in' : '/sign-up'),
                          child: Text(_isSignUp ? 'Login' : 'Sign Up',
                              style: authLinkStyle),
                        ),
                      ),
                    ]),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          if (_isSignUp) ...[
            LayoutBuilder(builder: (context, constraints) {
              final stackNames = constraints.maxWidth < 430;
              final firstName = _Field(
                  label: 'First name',
                  controller: _firstName,
                  hint: 'John',
                  maxLength: 20,
                  validator: (value) =>
                      validateRequiredName(value, 'First name'),
                  autofillHints: const [AutofillHints.givenName]);
              final lastName = _Field(
                  label: 'Last name',
                  controller: _lastName,
                  hint: 'Doe',
                  maxLength: 20,
                  validator: (value) =>
                      validateRequiredName(value, 'Last name'),
                  autofillHints: const [AutofillHints.familyName]);
              if (stackNames) {
                return Column(children: [
                  firstName,
                  const SizedBox(height: 24),
                  lastName,
                ]);
              }
              return Row(children: [
                Expanded(child: firstName),
                const SizedBox(width: 24),
                Expanded(child: lastName),
              ]);
            }),
            const SizedBox(height: 24),
          ],
          _Field(
            label: 'Email',
            controller: _email,
            hint: 'user@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: validateEmail,
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 24),
            _PhoneField(
                label: 'Phone Number',
                controller: _phone,
                hint: '8012345678',
                dialCode: _countryDialCode,
                onDialCodeChanged: (value) {
                  if (value != null) {
                    setState(() => _countryDialCode = value);
                  }
                }),
          ],
          const SizedBox(height: 24),
          _Field(
            label: 'Password',
            controller: _password,
            hint: 'Enter Password',
            keyboardType: TextInputType.visiblePassword,
            obscureText: _obscurePassword,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            validator: (value) => validatePassword(
              value,
              firstName: _isSignUp ? _firstName.text : null,
              lastName: _isSignUp ? _lastName.text : null,
              phoneNumber: _isSignUp ? _phone.text : null,
            ),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFFA3A3A3)),
            ),
          ),
          if (!_isSignUp) ...[
            const SizedBox(height: 12),
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    style: authTextButtonStyle(),
                    child:
                        const Text('Forgot Password?', style: authLinkStyle))),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Semantics(
                liveRegion: true,
                child:
                    Text(_error!, style: const TextStyle(color: Colors.red))),
          ],
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isSignUp ? 'Create account' : 'Login'),
            ),
          ),
          const SizedBox(height: 26),
          const Wrap(children: [
            Text('By clicking on create account you agree to our '),
            _PolicyLink('privacy policy'),
            Text(' and '),
            _PolicyLink('terms of use'),
          ]),
        ]),
      ),
    );
  }
}

class _CountryDialCode {
  const _CountryDialCode(this.country, this.code);

  final String country;
  final String code;
}

const _countryDialCodes = [
  _CountryDialCode('Nigeria', '+234'),
  _CountryDialCode('Ghana', '+233'),
  _CountryDialCode('Kenya', '+254'),
  _CountryDialCode('South Africa', '+27'),
  _CountryDialCode('Egypt', '+20'),
  _CountryDialCode('Rwanda', '+250'),
  _CountryDialCode('Uganda', '+256'),
  _CountryDialCode('Tanzania', '+255'),
  _CountryDialCode('United Kingdom', '+44'),
  _CountryDialCode('United States / Canada', '+1'),
  _CountryDialCode('France', '+33'),
  _CountryDialCode('Germany', '+49'),
  _CountryDialCode('India', '+91'),
  _CountryDialCode('United Arab Emirates', '+971'),
];

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.dialCode,
    required this.onDialCodeChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String dialCode;
  final ValueChanged<String?> onDialCodeChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: AppColors.text)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            validator: validatePhoneDigits,
            decoration: InputDecoration(
              hintText: hint,
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: dialCode,
                    borderRadius: BorderRadius.circular(8),
                    dropdownColor: Colors.white,
                    menuWidth: 280,
                    menuMaxHeight: 360,
                    itemHeight: 48,
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Color(0xFFA3A3A3),
                    ),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFFA3A3A3),
                    ),
                    selectedItemBuilder: (context) => _countryDialCodes
                        .map((country) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(country.code),
                            ))
                        .toList(),
                    items: _countryDialCodes
                        .map((country) => DropdownMenuItem(
                              value: country.code,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: SizedBox(
                                  width: 224,
                                  child: Text(
                                    '${country.country} (${country.code})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 16,
                                      height: 1.5,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: onDialCodeChanged,
                  ),
                ),
              ),
            ),
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
        ],
      );
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.label,
      required this.controller,
      required this.hint,
      this.keyboardType,
      this.obscureText = false,
      this.suffixIcon,
      this.autofillHints,
      this.maxLength,
      this.enableSuggestions = true,
      this.autocorrect = true,
      this.textInputAction,
      this.validator});
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final bool enableSuggestions;
  final bool autocorrect;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 16, color: AppColors.text)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: true,
          readOnly: false,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enableSuggestions: enableSuggestions,
          autocorrect: autocorrect,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          maxLength: maxLength,
          validator: validator ??
              (value) => value == null || value.trim().isEmpty
                  ? '$label is required'
                  : null,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            counterText: '',
          ),
          onFieldSubmitted: (_) {
            if (textInputAction != TextInputAction.done) {
              FocusScope.of(context).nextFocus();
            }
          },
        ),
      ]);
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: authLinkStyle);
}
