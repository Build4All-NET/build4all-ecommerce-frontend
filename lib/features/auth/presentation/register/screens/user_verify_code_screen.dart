import 'package:build4front/common/widgets/primary_button.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/auth/data/repository/auth_repository_impl.dart';
import 'package:build4front/features/auth/domain/usecases/verify_email_code.dart';
import 'package:build4front/features/auth/domain/usecases/verify_phone_code.dart';
import 'package:build4front/features/auth/presentation/register/bloc/register_event.dart';
import 'package:build4front/features/auth/presentation/register/screens/UserCompleteProfileScreen.dart';

import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserVerifyCodeScreen extends StatefulWidget {
  final String contact; // email OR phone
  final RegisterMethod method;
  final AppConfig appConfig;

  const UserVerifyCodeScreen({
    super.key,
    required this.contact,
    required this.method,
    required this.appConfig,
  });

  @override
  State<UserVerifyCodeScreen> createState() => _UserVerifyCodeScreenState();
}

class _UserVerifyCodeScreenState extends State<UserVerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();

  final int _codeLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getCode() {
    final buffer = StringBuffer();
    for (final c in _controllers) {
      buffer.write(c.text);
    }
    return buffer.toString();
  }

  void _onBoxChanged(String value, int index) {
    if (value.length == 1 && index < _codeLength - 1) {
      // go to next
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // if backspace, go back
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _onVerifyPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final code = _getCode().trim();

    if (code.length < 4) {
      AppToast.error(context, l10n.invalidVerificationCode);
      return;
    }

    setState(() => _isLoading = true);

    final repo = context.read<AuthRepositoryImpl>();
    final ownerId = int.tryParse(Env.ownerProjectLinkId) ?? 0;

    try {
      int pendingId;
      if (widget.method == RegisterMethod.email) {
        final usecase = VerifyEmailCode(repo);
        final result = await usecase(email: widget.contact, code: code);
        pendingId = result.fold((failure) {
          AppToast.error(context, failure.message);
          throw failure;
        }, (id) => id);
      } else {
        final usecase = VerifyPhoneCode(repo);
        final result = await usecase(phoneNumber: widget.contact, code: code);
        pendingId = result.fold((failure) {
          AppToast.error(context, failure.message);
          throw failure;
        }, (id) => id);
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserCompleteProfileScreen(
            pendingId: pendingId,
            ownerProjectLinkId: ownerId,
            appConfig: widget.appConfig,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;
    final card = themeState.tokens.card;
    final t = Theme.of(context).textTheme;

    final isPhone = widget.method == RegisterMethod.phone;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(card.padding),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(card.radius),
                border: card.showBorder
                    ? Border.all(color: colors.border.withOpacity(0.15))
                    : null,
                boxShadow: card.showShadow
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: card.elevation * 2,
                          offset: Offset(0, card.elevation * 0.6),
                        ),
                      ]
                    : null,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App avatar / branding
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.lock_outline,
                        color: colors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.verifyCodeTitle,
                      style: t.headlineSmall?.copyWith(
                        color: colors.label,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPhone
                          ? l10n.verifyCodeSubtitlePhone
                          : l10n.verifyCodeSubtitleEmail,
                      style: t.bodyMedium?.copyWith(color: colors.body),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.contact,
                      style: t.bodyMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // OTP boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_codeLength, (index) {
                        return _OtpBox(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          onChanged: (value) => _onBoxChanged(value, index),
                          colors: colors,
                          textTheme: t,
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: l10n.verifyButtonLabel,
                      isLoading: _isLoading,
                      onPressed: () => _onVerifyPressed(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final dynamic colors;
  final TextTheme textTheme;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        style: textTheme.headlineSmall?.copyWith(
          color: colors.label,
          fontWeight: FontWeight.bold,
        ),
        keyboardType: TextInputType.number,
        obscureText: false,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: colors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border.withOpacity(0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border.withOpacity(0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary, width: 1.6),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
