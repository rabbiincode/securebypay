import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import 'auth_layout.dart';
import 'auth_validators.dart';

class PasswordResetRequestPage extends StatefulWidget {
  const PasswordResetRequestPage({super.key});
  @override
  State<PasswordResetRequestPage> createState() =>
      _PasswordResetRequestPageState();
}

class _PasswordResetRequestPageState extends State<PasswordResetRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await apiClient.forgotPassword(_email.text.trim());
      final challengeId = result['challengeId'] as String?;
      if (mounted && challengeId != null) {
        context.go('/reset-password?challengeId=$challengeId');
      }
      if (mounted && challengeId == null) {
        setState(() => _error = result['message'] as String);
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthCard(
        formKey: _formKey,
        title: 'Forgot your password?',
        description:
            'Enter your account email and we’ll send you a verification code.',
        children: [
          AuthLabeledField(
            label: 'Email',
            controller: _email,
            hint: 'user@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: validateEmail,
          ),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child:
                    Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Sending…' : 'Send reset code')),
          ),
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/sign-in'),
              style: authTextButtonStyle(),
              child: const Text('Back to sign in', style: authLinkStyle),
            ),
          ),
        ],
      );
}

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({required this.challengeId, super.key});
  final String challengeId;
  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await apiClient.resetPassword(
          widget.challengeId, _code.text, _password.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password updated. You can now sign in.')));
        context.go('/sign-in');
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthCard(
        formKey: _formKey,
        title: 'Reset password',
        description:
            'Enter the code from your email and choose a new password.',
        children: [
          AuthLabeledField(
            label: 'Verification code',
            controller: _code,
            hint: 'Enter verification code',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            maxLength: 6,
            validator: (value) =>
                value != null && RegExp(r'^\d{6}$').hasMatch(value)
                    ? null
                    : 'Enter the six-digit code from your email',
          ),
          const SizedBox(height: 24),
          AuthLabeledField(
            label: 'New password',
            controller: _password,
            hint: 'Enter new password',
            keyboardType: TextInputType.visiblePassword,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            validator: validatePassword,
          ),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child:
                    Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Updating…' : 'Update password')),
          ),
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/sign-in'),
              style: authTextButtonStyle(),
              child: const Text('Back to sign in', style: authLinkStyle),
            ),
          ),
        ],
      );
}

class _AuthCard extends StatelessWidget {
  const _AuthCard(
      {required this.formKey,
      required this.title,
      required this.description,
      required this.children});
  final GlobalKey<FormState> formKey;
  final String title, description;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => AuthShell(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 10),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 36),
              ...children,
            ],
          ),
        ),
      );
}
