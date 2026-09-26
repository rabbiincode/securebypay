import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import 'auth_layout.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage(
      {required this.challengeId,
      required this.destination,
      required this.purpose,
      super.key});
  final String challengeId, destination, purpose;
  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _code = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || widget.challengeId.isEmpty) {
      setState(() => _error = 'Enter the six-digit code from your email.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (widget.purpose == 'email') {
        await apiClient.verifyEmail(widget.challengeId, _code.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Email verified. Sign in to continue.'),
          ));
          context.go('/sign-in');
        }
      } else {
        await apiClient.verifyLogin(widget.challengeId, _code.text);
        if (mounted) context.go('/dashboard');
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.purpose == 'email'
                  ? 'Verify your email'
                  : 'Confirm it’s you',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'We sent a six-digit verification code to ${widget.destination}. The code expires in five minutes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 36),
            AuthLabeledField(
              label: 'Verification code',
              controller: _code,
              hint: 'Enter verification code',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              maxLength: 6,
              textStyle: const TextStyle(
                fontSize: 16,
                letterSpacing: 6,
                fontWeight: FontWeight.w600,
              ),
              onSubmitted: (_) => _verify(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _submitting ? null : _verify,
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify and continue'),
              ),
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
        ),
      );
}
