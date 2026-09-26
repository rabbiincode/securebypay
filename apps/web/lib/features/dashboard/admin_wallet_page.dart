import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/currency.dart';
import '../../core/theme.dart';

class AdminWalletPage extends StatefulWidget {
  const AdminWalletPage({super.key});

  @override
  State<AdminWalletPage> createState() => _AdminWalletPageState();
}

class _AdminWalletPageState extends State<AdminWalletPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  late String _idempotencyKey = _newKey();
  bool _submitting = false;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _recipient;
  Timer? _lookupTimer;
  bool _lookingUp = false;
  String? _lookupMessage;

  String _newKey() =>
      'admin-top-up-${DateTime.now().microsecondsSinceEpoch}-securebypay';

  @override
  void dispose() {
    _email.dispose();
    _amount.dispose();
    _description.dispose();
    _lookupTimer?.cancel();
    super.dispose();
  }

  void _scheduleLookup(String value) {
    _lookupTimer?.cancel();
    setState(() {
      _recipient = null;
      _lookupMessage = null;
    });
    final email = value.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return;
    _lookupTimer = Timer(const Duration(milliseconds: 450), () {
      _lookupRecipient(email);
    });
  }

  Future<void> _lookupRecipient(String email) async {
    setState(() => _lookingUp = true);
    try {
      final recipient = await apiClient.findAdminWalletUser(email);
      if (!mounted || _email.text.trim().toLowerCase() != email.toLowerCase()) {
        return;
      }
      setState(() {
        _recipient = recipient;
        _lookupMessage = null;
        _lookingUp = false;
      });
    } on ApiException catch (error) {
      if (!mounted || _email.text.trim().toLowerCase() != email.toLowerCase()) {
        return;
      }
      setState(() {
        _recipient = null;
        _lookupMessage = error.statusCode == 404
            ? 'No registered user has this email address.'
            : error.message;
        _lookingUp = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipient == null) {
      await _lookupRecipient(_email.text.trim());
      if (_recipient == null) return;
    }
    setState(() => _submitting = true);
    try {
      final result = await apiClient.simulateWalletTopUp(
        recipientEmail: _email.text.trim(),
        amount: double.parse(_amount.text.trim()),
        idempotencyKey: _idempotencyKey,
        description: _description.text,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _idempotencyKey = _newKey();
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulated wallet credit completed.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Admin wallet'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Issue a simulated wallet credit',
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text(
                        'For assessment testing only. Every credit is recorded in the transaction ledger and audit log.',
                        style: TextStyle(color: Color(0xFF777777), height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      _Field(
                        label: 'Recipient email',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _scheduleLookup,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(email)
                              ? null
                              : 'Enter a valid email address';
                        },
                      ),
                      if (_lookingUp) ...[
                        const SizedBox(height: 9),
                        const Text('Finding registered user…',
                            style: TextStyle(color: Color(0xFF777777))),
                      ] else if (_recipient != null) ...[
                        const SizedBox(height: 9),
                        Row(children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: Color(0xFF1A8F13)),
                          const SizedBox(width: 7),
                          Text(
                            '${_recipient!['firstName']} ${_recipient!['lastName']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A8F13)),
                          ),
                        ]),
                      ] else if (_lookupMessage != null) ...[
                        const SizedBox(height: 9),
                        Text(_lookupMessage!,
                            style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 20),
                      _Field(
                        label: 'Amount (NGN)',
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          final amount = double.tryParse(value?.trim() ?? '');
                          if (amount == null) return 'Enter a valid amount';
                          if (amount < 100 || amount > 1000000) {
                            return 'Amount must be between ₦100 and ₦1,000,000';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _Field(
                        label: 'Description (optional)',
                        controller: _description,
                        validator: (value) => (value?.length ?? 0) > 140
                            ? 'Description cannot exceed 140 characters'
                            : null,
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                              _submitting ? 'Processing…' : 'Simulate top-up'),
                        ),
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFFBEA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Credited ${formatNaira(_result!['amount'])} · New balance ${formatNaira(_result!['balanceAfter'])}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: const InputDecoration(fillColor: Colors.white),
          ),
        ],
      );
}
