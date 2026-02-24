import 'package:build4front/features/auth/data/repository/auth_repository_impl.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/features/auth/data/services/session_role_store.dart';
import 'package:build4front/features/auth/domain/usecases/send_verification_code.dart';
import 'package:build4front/features/auth/presentation/register/bloc/register_bloc.dart';
import 'package:build4front/features/auth/presentation/register/screens/user_register_screen.dart';
import 'package:build4front/features/forgotpassword/domain/repositories/forgot_password_repository.dart';
import 'package:build4front/features/forgotpassword/domain/usecases/send_reset_code.dart';
import 'package:build4front/features/forgotpassword/domain/usecases/update_password.dart';
import 'package:build4front/features/forgotpassword/domain/usecases/verify_reset_code.dart';
import 'package:build4front/features/forgotpassword/presentation/bloc/forgot_password_bloc.dart';
import 'package:build4front/features/forgotpassword/presentation/screens/forgot_password_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../../../common/widgets/primary_button.dart';
import '../../../../../common/widgets/app_text_field.dart';
import '../../../../../common/widgets/app_toast.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/theme_cubit.dart';
import '../../../../../core/exceptions/exception_mapper.dart';
import '../../../../../core/config/env.dart';

import '../../../../shell/presentation/screens/main_shell.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

import 'package:build4front/features/auth/domain/facade/dual_login_orchestrator.dart';

enum LoginMethod { email, phone }

class UserLoginScreen extends StatefulWidget {
  final AppConfig appConfig;

  const UserLoginScreen({super.key, required this.appConfig});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final _roleStore = SessionRoleStore();

  LoginMethod _method = LoginMethod.email;
  String? _fullPhone;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final identifier = _method == LoginMethod.email
        ? _emailCtrl.text.trim()
        : (_fullPhone ?? '').trim();

    if (identifier.isEmpty) {
      AppToast.show(context, l10n.loginMissingIdentifier, isError: true);
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final repo = context.read<AuthRepositoryImpl>();
      final authApi = repo.api;

      final orchestrator = DualLoginOrchestrator(
        authApi: authApi,
        adminStore: AdminTokenStore(),
      );

      final result = await orchestrator.login(
        identifier: identifier,
        password: _passwordCtrl.text,
        usePhoneForUser: _method == LoginMethod.phone,
        ownerProjectLinkId: int.tryParse(Env.ownerProjectLinkId) ?? 0,
      );

      if (mounted) Navigator.of(context).pop();

      if (result.none) {
        AppToast.show(
          context,
          result.error ?? l10n.authErrorGeneric,
          isError: true,
        );
        return;
      }

      Future<void> _hydrateUserAuth(bool wasInactiveFlag) async {
        final user = result.userEntity;
        if (user == null) return;

        final token = await authApi.getSavedToken();
        if (!mounted) return;
        if (token == null || token.isEmpty) return;

        context.read<AuthBloc>().add(
              AuthLoginHydrated(
                user: user,
                token: token,
                wasInactive: wasInactiveFlag,
              ),
            );
      }

     Future<void> _enterUserFlow(bool wasInactiveUser) async {
  final user = result.userEntity;
  if (user == null) return;

  // ✅ NEW: deleted restore flow first
  if (result.wasDeletedUser == true) {
    final confirm = await _showRestoreDeletedSheet(context);
    if (confirm != true) {
    
      await authApi.clearAuth();
      return;
    }

    try {
      await authApi.reactivateUser(
        userId: user.id,
        ownerProjectLinkId: int.tryParse(Env.ownerProjectLinkId) ?? 0,
      );

      if (!mounted) return;

      AppToast.show(context, 'Account restored successfully'); // l10n later
      await _hydrateUserAuth(false);
      await _roleStore.saveRole('user');
      _goToUserHome(context);
    } catch (e) {
      if (!mounted) return;
      final msg = ExceptionMapper.toMessage(e);
      AppToast.show(context, msg, isError: true);
    }

    return;
  }

  // existing inactive flow
  if (wasInactiveUser) {
    final confirm = await _showReactivateSheet(context);
    if (confirm != true) {
      await authApi.clearAuth();
      return;
    }

    try {
      await authApi.reactivateUser(
        userId: user.id,
        ownerProjectLinkId: int.tryParse(Env.ownerProjectLinkId) ?? 0,
      );

      if (!mounted) return;

      AppToast.show(context, l10n.loginInactiveSuccess);

      await _hydrateUserAuth(true);
      await _roleStore.saveRole('user');
      _goToUserHome(context);
    } catch (e) {
      if (!mounted) return;
      final msg = ExceptionMapper.toMessage(e);
      AppToast.show(context, msg, isError: true);
    }
  } else {
    await _hydrateUserAuth(false);
    await _roleStore.saveRole('user');
    _goToUserHome(context);
  }
}

      // BOTH
      if (result.both) {
        final choice = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) {
            final t = Theme.of(ctx).textTheme;
            final themeState = ctx.watch<ThemeCubit>().state;
            final colors = themeState.tokens.colors;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 36,
                    decoration: BoxDecoration(
                      color: colors.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.loginChooseRoleTitle,
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.label,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Icon(
                      Icons.verified_user_outlined,
                      color: colors.primary,
                    ),
                    title: Text(
                      l10n.loginEnterAsOwner,
                      style: t.bodyLarge?.copyWith(color: colors.label),
                    ),
                    subtitle: Text(
                      '${l10n.loginRoleLabel}: ${result.adminRole}',
                      style: t.bodySmall?.copyWith(color: colors.body),
                    ),
                    onTap: () => Navigator.pop(ctx, 'admin'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.person_outline, color: colors.label),
                    title: Text(
                      l10n.loginEnterAsUser,
                      style: t.bodyLarge?.copyWith(color: colors.label),
                    ),
                    subtitle: Text(
                      result.userEntity?.email ??
                          result.userEntity?.username ??
                          'User',
                      style: t.bodySmall?.copyWith(color: colors.body),
                    ),
                    onTap: () => Navigator.pop(ctx, 'user'),
                  ),
                ],
              ),
            );
          },
        );

        if (choice == 'admin') {
          await _roleStore.saveRole('admin');
          _goToAdmin(
            context,
            role: result.adminRole!,
            admin: result.adminData!,
          );
        } else if (choice == 'user') {
          await _enterUserFlow(result.wasInactiveUser);
        }
        return;
      }

      // ONLY ADMIN
      if (result.adminOk && !result.userOk) {
        await _roleStore.saveRole('admin');
        _goToAdmin(context, role: result.adminRole!, admin: result.adminData!);
        return;
      }

      // ONLY USER
      if (result.userOk && !result.adminOk) {
        await _enterUserFlow(result.wasInactiveUser);
        return;
      }

      AppToast.show(context, l10n.authErrorGeneric, isError: true);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      final msg = ExceptionMapper.toMessage(e);
      AppToast.show(context, msg, isError: true);
    }
  }

  void _goToUserHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(appConfig: widget.appConfig)),
    );
  }


Future<bool?> _showRestoreDeletedSheet(BuildContext context) {
  final themeState = context.read<ThemeCubit>().state;
  final colors = themeState.tokens.colors;
  final t = Theme.of(context).textTheme;

  return showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final tt = Theme.of(ctx).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 36,
                decoration: BoxDecoration(
                  color: colors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Restore deleted account?',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.label,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This account was deleted, but it can still be restored. Do you want to reactivate it now?',
              style: tt.bodyMedium?.copyWith(color: colors.body),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.border.withOpacity(0.6)),
                    ),
                    child: Text(
                      'Cancel',
                      style: t.bodyMedium?.copyWith(color: colors.body),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    child: Text(
                      'Restore',
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
  void _goToAdmin(
    BuildContext context, {
    required String role,
    required Map<String, dynamic> admin,
  }) {
    Navigator.of(context).pushNamedAndRemoveUntil('/admin', (_) => false);
  }

  Future<bool?> _showReactivateSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = context.read<ThemeCubit>().state;
    final colors = themeState.tokens.colors;
    final t = Theme.of(context).textTheme;

    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final tt = Theme.of(ctx).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: colors.border.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.loginInactiveTitle,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.label,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginInactiveMessage(widget.appConfig.appName),
                style: tt.bodyMedium?.copyWith(color: colors.body),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.border.withOpacity(0.6)),
                      ),
                      child: Text(
                        l10n.loginInactiveCancel,
                        style: t.bodyMedium?.copyWith(color: colors.body),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      ),
                      child: Text(
                        l10n.loginInactiveReactivate,
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;
    final card = themeState.tokens.card;

    final t = Theme.of(context).textTheme;
    final isPhone = _method == LoginMethod.phone;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.error != null) {
                  final msg = ExceptionMapper.toMessage(state.error!);
                  AppToast.show(context, msg, isError: true);
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
                        Icons.person_outline,
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
                      l10n.loginSubtitle,
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
                              l10n.loginTitle,
                              style: t.headlineSmall?.copyWith(
                                color: colors.label,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LoginMethodToggle(
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
                                  if (!v.contains('@'))
                                    return l10n.invalidEmail;
                                  return null;
                                },
                              )
                            else
                              _PhoneFieldIntl(
                                colors: colors,
                                card: card,
                                textTheme: t,
                                l10n: l10n,
                                onChanged: (fullPhone) =>
                                    _fullPhone = fullPhone,
                              ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: l10n.passwordLabel,
                              controller: _passwordCtrl,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return l10n.fieldRequired;
                                if (value.length < 6)
                                  return l10n.passwordTooShort;
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: l10n.loginButton,
                              isLoading: state.isLoading,
                              onPressed: () => _onLoginPressed(context),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) {
                                        final repo = ctx
                                            .read<ForgotPasswordRepository>();

                                        return BlocProvider(
                                          create: (_) => ForgotPasswordBloc(
                                            sendResetCode: SendResetCode(repo),
                                            verifyResetCode: VerifyResetCode(
                                              repo,
                                            ),
                                            updatePassword: UpdatePassword(
                                              repo,
                                            ),
                                          ),
                                          child:
                                              const ForgotPasswordEmailScreen(),
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n.forgotPasswordLink,
                                  style: t.bodyMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.noAccountText,
                          style: t.bodyMedium?.copyWith(color: colors.body),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) {
                                  final repo = ctx.read<AuthRepositoryImpl>();
                                  return BlocProvider(
                                    create: (_) => RegisterBloc(
                                      sendVerificationCode:
                                          SendVerificationCode(repo),
                                    ),
                                    child: UserRegisterScreen(
                                      appConfig: widget.appConfig,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: Text(
                            l10n.signUpText,
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

// --- UI helpers (same as you had) ---
class _LoginMethodToggle extends StatelessWidget {
  final LoginMethod method;
  final ValueChanged<LoginMethod> onChanged;
  final dynamic colors;
  final TextTheme textTheme;
  final AppLocalizations l10n;

  const _LoginMethodToggle({
    required this.method,
    required this.onChanged,
    required this.colors,
    required this.textTheme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isEmail = method == LoginMethod.email;
    final isPhone = method == LoginMethod.phone;

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
            child: _Segment(
              label: l10n.loginWithEmail,
              selected: isEmail,
              onTap: () => onChanged(LoginMethod.email),
              colors: colors,
              textTheme: textTheme,
            ),
          ),
          Expanded(
            child: _Segment(
              label: l10n.loginWithPhone,
              selected: isPhone,
              onTap: () => onChanged(LoginMethod.phone),
              colors: colors,
              textTheme: textTheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final dynamic colors;
  final TextTheme textTheme;

  const _Segment({
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

class _PhoneFieldIntl extends StatelessWidget {
  final dynamic colors;
  final dynamic card;
  final TextTheme textTheme;
  final AppLocalizations l10n;
  final ValueChanged<String> onChanged;

  const _PhoneFieldIntl({
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
        if (phone == null || phone.number.trim().isEmpty)
          return l10n.fieldRequired;
        if (phone.number.trim().length < 6) return l10n.invalidPhone;
        return null;
      },
    );
  }
}
