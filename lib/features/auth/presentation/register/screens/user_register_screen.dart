import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/theme/theme_cubit.dart';

import 'package:build4front/features/auth/presentation/register/bloc/register_bloc.dart';
import 'package:build4front/features/auth/presentation/register/bloc/register_event.dart';
import 'package:build4front/features/auth/presentation/register/bloc/register_state.dart';
import 'package:build4front/features/auth/presentation/register/screens/UserCompleteProfileScreen.dart';
import 'package:build4front/features/auth/presentation/register/screens/user_verify_code_screen.dart';

import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/common/widgets/app_text_field.dart';
import 'package:build4front/common/widgets/primary_button.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class UserRegisterScreen extends StatefulWidget {
  final AppConfig appConfig;

  const UserRegisterScreen({super.key, required this.appConfig});

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  RegisterMethod _method = RegisterMethod.email;
  String? _fullPhone; // e.g. +96170123456

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }


String? _passwordValidator(String? value, AppLocalizations l10n) {
  final v = (value ?? '').trim();

  if (v.isEmpty) return l10n.fieldRequired;

  // ✅ ONLY RULE: at least 6 characters
  if (v.length < 6) {
    return l10n.hintPasswordRuleOwner; // NEW KEY
  }

  return null;
}

  void _onContinuePressed(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    final email =
        _method == RegisterMethod.email ? _emailCtrl.text.trim() : null;
    final phone = _method == RegisterMethod.phone ? _fullPhone?.trim() : null;

    if (_method == RegisterMethod.email && (email == null || email.isEmpty)) {
      AppToast.show(context, l10n.loginMissingIdentifier, isError: true);
      return;
    }

    if (_method == RegisterMethod.phone && (phone == null || phone.isEmpty)) {
      AppToast.show(context, l10n.loginMissingIdentifier, isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    context.read<RegisterBloc>().add(
          RegisterSendCodeSubmitted(
            method: _method,
            email: email,
            phoneNumber: phone,
            password: _passwordCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;
    final card = themeState.tokens.card;

    final t = Theme.of(context).textTheme;
    final isPhone = _method == RegisterMethod.phone;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child:BlocConsumer<RegisterBloc, RegisterState>(
  // ✅ react on error / normal codeSent / resume flow
  listenWhen: (p, c) =>
      p.errorCode != c.errorCode ||
      p.codeSent != c.codeSent ||
      p.resumeCompleteProfile != c.resumeCompleteProfile ||
      p.resumePendingId != c.resumePendingId,
  listener: (context, state) {
    final l10n = AppLocalizations.of(context)!;

    // ✅ 1) SPECIAL CASE: pending already verified -> resume complete profile
    if (state.resumeCompleteProfile && state.resumePendingId != null) {
      final ownerId = int.tryParse(Env.ownerProjectLinkId) ?? 0;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserCompleteProfileScreen(
            pendingId: state.resumePendingId!,
            ownerProjectLinkId: ownerId,
            appConfig: widget.appConfig,
          ),
        ),
      );
      return;
    }

    // ✅ 2) show error toast
    if (state.errorCode != null) {
      AppToast.show(
        context,
        _l10nFromCode(l10n, state.errorCode!),
        isError: true,
      );
      return;
    }

    // ✅ 3) normal flow: code sent -> go verify code screen
    if (state.codeSent && state.contact != null && state.method != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserVerifyCodeScreen(
            contact: state.contact!,
            method: state.method!,
            appConfig: widget.appConfig,
          ),
        ),
      );
    }
  },
  builder: (context, state) {
    
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person_add_alt_outlined,
                        color: colors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.appConfig.appName,
                      style: t.titleMedium?.copyWith(
                        color: colors.label,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.registerSubtitle, // add in l10n
                      style: t.bodyMedium?.copyWith(color: colors.body),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.registerStep1Of3, // add in l10n
                              style: t.labelLarge?.copyWith(
                                color: colors.body,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.registerTitle, // add in l10n
                              style: t.headlineSmall?.copyWith(
                                color: colors.label,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _RegisterMethodToggle(
                              method: _method,
                              onChanged: (m) {
                                if (_method == m) return;
                                setState(() {
                                  _method = m;
                                  _emailCtrl.clear();
                                  _fullPhone = null;
                                });
                              },
                              colors: colors,
                              textTheme: t,
                              l10n: l10n,
                            ),

                            const SizedBox(height: 20),

                            if (!isPhone)
                              AppTextField(
                                label: l10n.emailLabel,
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return l10n.fieldRequired;
                                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                      .hasMatch(v);
                                  if (!ok) return l10n.invalidEmail;
                                  return null;
                                },
                              )
                            else
                              _PhoneFieldIntlRegister(
                                colors: colors,
                                card: card,
                                textTheme: t,
                                l10n: l10n,
                                onChanged: (fullPhone) {
                                  _fullPhone = fullPhone;
                                },
                              ),

                            const SizedBox(height: 16),

                            // Password (✅ 6-8 + special char)
                            AppTextField(
                              label: l10n.passwordLabel,
                              controller: _passwordCtrl,
                              obscureText: true,
                              validator: (value) =>
                                  _passwordValidator(value, l10n),
                            ),

                            const SizedBox(height: 6),
                            Text(
                              l10n.hintPasswordRuleOwner, // NEW KEY
                              style: t.bodySmall?.copyWith(color: colors.body),
                            ),

                            const SizedBox(height: 12),

                            // Confirm password
                            AppTextField(
                              label: l10n.confirmPasswordLabel, // add in l10n
                              controller: _confirmPasswordCtrl,
                              obscureText: true,
                              validator: (value) {
                                final v = (value ?? '').trim();
                                if (v.isEmpty) return l10n.fieldRequired;
                                if (v != _passwordCtrl.text.trim()) {
                                  return l10n.passwordsDoNotMatch; // add in l10n
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            PrimaryButton(
                              label: l10n.registerContinueButton, // add in l10n
                              isLoading: state.isLoading,
                              onPressed: state.isLoading
                                  ? null
                                  : () => _onContinuePressed(context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.alreadyHaveAccountText, // add in l10n
                          style: t.bodyMedium?.copyWith(color: colors.body),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            l10n.loginButton,
                            style: t.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterMethodToggle extends StatelessWidget {
  final RegisterMethod method;
  final ValueChanged<RegisterMethod> onChanged;
  final dynamic colors;
  final TextTheme textTheme;
  final AppLocalizations l10n;

  const _RegisterMethodToggle({
    required this.method,
    required this.onChanged,
    required this.colors,
    required this.textTheme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isEmail = method == RegisterMethod.email;
    final isPhone = method == RegisterMethod.phone;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RegisterSegment(
              label: l10n.registerWithEmail, // add in l10n
              selected: isEmail,
              onTap: () => onChanged(RegisterMethod.email),
              colors: colors,
              textTheme: textTheme,
            ),
          ),
          Expanded(
            child: _RegisterSegment(
              label: l10n.registerWithPhone, // add in l10n
              selected: isPhone,
              onTap: () => onChanged(RegisterMethod.phone),
              colors: colors,
              textTheme: textTheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final dynamic colors;
  final TextTheme textTheme;

  const _RegisterSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: selected ? colors.onPrimary : colors.body,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneFieldIntlRegister extends StatelessWidget {
  final dynamic colors;
  final dynamic card;
  final TextTheme textTheme;
  final AppLocalizations l10n;
  final ValueChanged<String> onChanged;

  const _PhoneFieldIntlRegister({
    required this.colors,
    required this.card,
    required this.textTheme,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      initialCountryCode: 'LB',
      decoration: InputDecoration(
        labelText: l10n.phoneLabel,
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(card.radius),
          borderSide: BorderSide(color: colors.border.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(card.radius),
          borderSide: BorderSide(color: colors.border.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(card.radius),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
      ),
      dropdownTextStyle: textTheme.bodyMedium?.copyWith(color: colors.label),
      style: textTheme.bodyMedium?.copyWith(color: colors.label),
      flagsButtonPadding: const EdgeInsets.only(left: 8),
      onChanged: (phone) => onChanged(phone.completeNumber),
      validator: (phone) {
        if (phone == null || phone.number.trim().isEmpty) {
          return l10n.fieldRequired;
        }
        if (phone.number.trim().length < 6) {
          return l10n.invalidPhone;
        }
        return null;
      },
    );
  }
}

String _l10nFromCode(AppLocalizations l10n, String code) {
  switch (code) {
    case 'EMAIL_ALREADY_EXISTS':
    case 'EMAIL_ALREADY_IN_USE':
    case 'EMAIL_EXISTS':
    case 'EMAIL_IN_USE':
      return l10n.authEmailAlreadyExists;

    case 'PHONE_ALREADY_EXISTS':
    case 'PHONE_ALREADY_IN_USE':
    case 'PHONE_EXISTS':
    case 'PHONE_IN_USE':
      return l10n.authPhoneAlreadyExists;

    case 'USERNAME_TAKEN':
      return l10n.authUsernameTaken;
      case 'PENDING_ALREADY_VERIFIED':
  return l10n.accountAlreadyVerified; // or add dedicated l10n key later

    case 'USER_NOT_FOUND':
      return l10n.authUserNotFound;
    case 'WRONG_PASSWORD':
      return l10n.authWrongPassword;
    case 'INVALID_CREDENTIALS':
      return l10n.authInvalidCredentials;
    case 'INACTIVE':
      return l10n.authAccountInactive;

    case 'INVALID_CODE':
      return l10n.invalidVerificationCode; // add if not exists

    case 'NO_INTERNET':
      return l10n.networkNoInternet;
    case 'TIMEOUT':
      return l10n.networkTimeout;
    case 'NETWORK_ERROR':
      return l10n.networkError;

    case 'VALIDATION_ERROR':
      return l10n.httpValidationError;
    case 'CONFLICT':
      return l10n.httpConflict;
    case 'UNAUTHORIZED':
      return l10n.httpUnauthorized;
    case 'FORBIDDEN':
      return l10n.httpForbidden;
    case 'NOT_FOUND':
      return l10n.httpNotFound;
    case 'SERVER_ERROR':
      return l10n.httpServerError;

    default:
      return l10n.authErrorGeneric;
  }
}
