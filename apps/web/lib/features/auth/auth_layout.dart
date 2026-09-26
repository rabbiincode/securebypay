import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme.dart';

const authLinkStyle = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 14,
  height: 22 / 14,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.028,
  color: AppColors.primary,
  decoration: TextDecoration.underline,
  decorationColor: AppColors.primary,
);

ButtonStyle authTextButtonStyle() => TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: AppColors.primary,
    );

class AuthShell extends StatelessWidget {
  const AuthShell({required this.child, this.signupHero = false, super.key});

  final Widget child;
  final bool signupHero;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(builder: (context, constraints) {
          final showHero = constraints.maxWidth >= 900;
          return Row(children: [
            Expanded(
              flex: 700,
              child: ColoredBox(
                color: const Color(0xFFFAFAFA),
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth < 600 ? 24 : 48,
                      vertical: 40,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 536),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
            if (showHero)
              Expanded(
                flex: 740,
                child: _AuthHero(isSignUp: signupHero),
              ),
          ]);
        }),
      );
}

class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? textStyle;
  final bool enableSuggestions;
  final bool autocorrect;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: AppColors.text)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enableSuggestions: enableSuggestions,
            autocorrect: autocorrect,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            textAlign: textAlign,
            style: textStyle,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon,
              counterText: '',
            ),
            onFieldSubmitted: onSubmitted,
          ),
        ],
      );
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.isSignUp});

  final bool isSignUp;

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF5A65AB),
        child: Stack(fit: StackFit.expand, children: [
          Align(
            alignment: Alignment.topCenter,
            child: AspectRatio(
              aspectRatio: 740 / 879,
              child: SvgPicture.asset(
                'assets/world-map-dots.svg',
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(69, 48, 54, 158),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 579),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 411,
                      child: Text(
                        isSignUp
                            ? 'Seamlessly Delivering to Over 300\nCountries from Nigeria!'
                            : 'Effortlessly Track Your Shipments\nfrom Nigeria!',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          color: Colors.white,
                          fontSize: 24,
                          height: 35 / 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSignUp
                          ? 'Access global markets with our quick shipping from Nigeria! Fast delivery and easy customs to 300+ countries.'
                          : 'Monitor your shipments from Nigeria! Enjoy swift delivery and seamless customs processing',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        color: Color(0xFFEBFFE2),
                        fontSize: 18,
                        height: 30 / 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      );
}
