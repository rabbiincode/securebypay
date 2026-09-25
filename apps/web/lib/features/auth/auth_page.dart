import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

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
  String? _error;

  bool get _isSignUp => widget.mode == AuthMode.signUp;

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _email, _phone, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });
    try {
      late final Map<String, dynamic> result;
      if (_isSignUp) {
        result = await _api.signUp({
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'email': _email.text.trim(),
          'phoneNumber': _phone.text.trim(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final showHero = constraints.maxWidth >= 900;
        return Row(children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth < 600 ? 24 : 48, vertical: 40),
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 536), child: _buildForm()),
              ),
            ),
          ),
          if (showHero) Expanded(child: _AuthHero(isSignUp: _isSignUp)),
        ]);
      }),
    );
  }

  Widget _buildForm() {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_isSignUp ? 'Create an account' : 'Sign in to your account', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 10),
          Wrap(children: [
            Text(_isSignUp
                ? 'Sign up for Myafrimall and gain unlimited access to shipping to over 300 countries from Nigeria. Do you already have an account? '
                : "Log in to Myafrimall to enjoy seamless shipping to over 300 countries right from Nigeria. Don’t have an account yet? "),
            InkWell(
              onTap: () => context.go(_isSignUp ? '/sign-in' : '/sign-up'),
              child: Text(_isSignUp ? 'Login' : 'Sign Up', style: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 36),
          if (_isSignUp) ...[
            Row(children: [
              Expanded(child: _Field(label: 'First name', controller: _firstName, hint: 'John', autofillHints: const [AutofillHints.givenName])),
              const SizedBox(width: 24),
              Expanded(child: _Field(label: 'Last name', controller: _lastName, hint: 'Doe', autofillHints: const [AutofillHints.familyName])),
            ]),
            const SizedBox(height: 24),
          ],
          _Field(
            label: 'Email', controller: _email, hint: 'user@example.com', keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value) => value == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value) ? 'Enter a valid email address' : null,
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 24),
            _Field(label: 'Phone Number', controller: _phone, hint: '+234  8012345678', keyboardType: TextInputType.phone, autofillHints: const [AutofillHints.telephoneNumber]),
          ],
          const SizedBox(height: 24),
          _Field(
            label: 'Password', controller: _password, hint: 'Enter Password', obscureText: _obscurePassword,
            autofillHints: [_isSignUp ? AutofillHints.newPassword : AutofillHints.password],
            validator: (value) => value == null || value.length < 8 ? 'Password must be at least 8 characters' : null,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFA3A3A3)),
            ),
          ),
          if (!_isSignUp) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => context.go('/forgot-password'), style: TextButton.styleFrom(padding: EdgeInsets.zero), child: const Text('Forgot Password?', style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w700)))),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Semantics(liveRegion: true, child: Text(_error!, style: const TextStyle(color: Colors.red))),
          ],
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isSignUp ? 'Create account' : 'Login'),
            ),
          ),
          const SizedBox(height: 26),
          const Wrap(children: [
            Text('By clicking on create account you agree to our '),
            _PolicyLink('privacy policy'), Text(' and '), _PolicyLink('terms of use'),
          ]),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, required this.hint, this.keyboardType, this.obscureText = false, this.suffixIcon, this.autofillHints, this.validator});
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 16, color: AppColors.text)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller, keyboardType: keyboardType, obscureText: obscureText, autofillHints: autofillHints,
          validator: validator ?? (value) => value == null || value.trim().isEmpty ? '$label is required' : null,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
      ]);
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline, fontWeight: FontWeight.w700));
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.isSignUp});
  final bool isSignUp;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.primary,
        padding: const EdgeInsets.fromLTRB(68, 48, 54, 150),
        child: Stack(fit: StackFit.expand, children: [
          const Opacity(opacity: .17, child: _DotMap()),
          Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  isSignUp ? 'Seamlessly Delivering to Over 300\nCountries from Nigeria!' : 'Effortlessly Track Your Shipments\nfrom Nigeria!',
                  style: const TextStyle(color: Colors.white, fontSize: 25, height: 1.38, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Text(
                  isSignUp ? 'Access global markets with our quick shipping from Nigeria! Fast delivery and easy customs to 300+ countries.' : 'Monitor your shipments from Nigeria! Enjoy swift delivery and seamless customs processing',
                  style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.6),
                ),
              ]),
            ),
          ),
        ]),
      );
}

class _DotMap extends StatelessWidget {
  const _DotMap();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DotMapPainter());
}

class _DotMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const step = 15.0;
    for (double y = 8; y < size.height * .7; y += step) {
      for (double x = 8; x < size.width; x += step) {
        final nx = x / size.width;
        final ny = y / size.height;
        final wave = (nx * 17 + ny * 23).round() % 7;
        if (wave < 4 && !(nx > .43 && nx < .56 && ny < .25)) canvas.drawCircle(Offset(x, y), 4, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
