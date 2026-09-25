import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({required this.challengeId, required this.destination, required this.purpose, super.key});
  final String challengeId, destination, purpose;
  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _code = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _verify() async {
    if (_code.text.length != 6 || widget.challengeId.isEmpty) { setState(() => _error = 'Enter the six-digit code from your email.'); return; }
    setState(() { _submitting = true; _error = null; });
    try {
      if (widget.purpose == 'email') {
        await apiClient.verifyEmail(widget.challengeId, _code.text);
      } else {
        await apiClient.verifyLogin(widget.challengeId, _code.text);
      }
      if (mounted) context.go('/dashboard');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 30)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.primary),
                const SizedBox(height: 22),
                Text(widget.purpose == 'email' ? 'Verify your email' : 'Confirm it’s you', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                Text('We sent a six-digit verification code to ${widget.destination}. The code expires in five minutes.', textAlign: TextAlign.center),
                const SizedBox(height: 30),
                TextField(
                  controller: _code,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(labelText: 'Verification code', counterText: ''),
                  maxLength: 6,
                  onSubmitted: (_) => _verify(),
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _submitting ? null : _verify, child: _submitting ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify and continue')),
                const SizedBox(height: 12),
                TextButton(onPressed: () => context.go('/sign-in'), child: const Text('Back to sign in')),
              ]),
            ),
          ),
        ),
      );
}
