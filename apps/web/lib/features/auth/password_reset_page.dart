import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';

class PasswordResetRequestPage extends StatefulWidget {
  const PasswordResetRequestPage({super.key});
  @override
  State<PasswordResetRequestPage> createState() => _PasswordResetRequestPageState();
}

class _PasswordResetRequestPageState extends State<PasswordResetRequestPage> {
  final _email = TextEditingController();
  bool _submitting = false;
  String? _error;
  @override
  void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });
    try {
      final result = await apiClient.forgotPassword(_email.text.trim());
      final challengeId = result['challengeId'] as String?;
      if (mounted && challengeId != null) context.go('/reset-password?challengeId=$challengeId');
      if (mounted && challengeId == null) setState(() => _error = result['message'] as String);
    } on ApiException catch (error) { setState(() => _error = error.message); }
    finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) => _AuthCard(
        title: 'Forgot your password?',
        description: 'Enter your account email and we’ll send you a verification code.',
        children: [
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email address')),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _submitting ? null : _submit, child: Text(_submitting ? 'Sending…' : 'Send reset code')),
          TextButton(onPressed: () => context.go('/sign-in'), child: const Text('Back to sign in')),
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
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;
  @override
  void dispose() { _code.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_code.text.length != 6 || _password.text.length < 8) { setState(() => _error = 'Enter the six-digit code and a password of at least eight characters.'); return; }
    setState(() { _submitting = true; _error = null; });
    try {
      await apiClient.resetPassword(widget.challengeId, _code.text, _password.text);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. You can now sign in.'))); context.go('/sign-in'); }
    } on ApiException catch (error) { setState(() => _error = error.message); }
    finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) => _AuthCard(
        title: 'Reset password', description: 'Enter the code from your email and choose a new password.',
        children: [
          TextField(controller: _code, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)], decoration: const InputDecoration(labelText: 'Verification code')),
          const SizedBox(height: 18),
          TextField(controller: _password, obscureText: true, autofillHints: const [AutofillHints.newPassword], decoration: const InputDecoration(labelText: 'New password')),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _submitting ? null : _submit, child: Text(_submitting ? 'Updating…' : 'Update password')),
        ],
      );
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.title, required this.description, required this.children});
  final String title, description;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Container(
    constraints: const BoxConstraints(maxWidth: 480), padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 30)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 10), Text(description), const SizedBox(height: 28), ...children]),
  ))));
}
