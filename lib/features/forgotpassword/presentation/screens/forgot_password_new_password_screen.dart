import 'package:build4front/common/widgets/app_text_field.dart';
import 'package:build4front/common/widgets/primary_button.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/forgot_password_bloc.dart';
import '../bloc/forgot_password_event.dart';
import '../bloc/forgot_password_state.dart';
import '../widgets/auth_card_shell.dart';

class ForgotPasswordNewPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const ForgotPasswordNewPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ForgotPasswordNewPasswordScreen> createState() =>
      _ForgotPasswordNewPasswordScreenState();
}

class _ForgotPasswordNewPasswordScreenState
    extends State<ForgotPasswordNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    context.read<ForgotPasswordBloc>().add(
      ForgotUpdatePasswordPressed(
        email: widget.email,
        code: widget.code,
        newPassword: _passCtrl.text,
        ownerProjectLinkId: int.tryParse(Env.ownerProjectLinkId) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthCardShell(
      title: l10n.forgotNewPassTitle,
      subtitle: l10n.forgotNewPassSubtitle,
      icon: Icons.password_outlined,
      child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (ctx, state) {
          if (state.error != null) {
            AppToast.error(
              ctx,
              ExceptionMapper.toMessage(state.error!),
              
            );
          }
          if (state.successMessage != null) {
            AppToast.error(ctx, state.successMessage!);
            // ✅ back to login
            Navigator.of(ctx).popUntil((r) => r.isFirst);
            ctx.read<ForgotPasswordBloc>().add(const ForgotClearMessage());
          }
        },
        builder: (ctx, state) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: l10n.newPasswordLabel,
                  controller: _passCtrl,
                  obscureText: true,
                  validator: (v) {
                    final val = v ?? '';
                    if (val.isEmpty) return l10n.fieldRequired;
                    if (val.length < 6) return l10n.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: l10n.confirmPasswordLabel,
                  controller: _confirmCtrl,
                  obscureText: true,
                  validator: (v) {
                    if ((v ?? '').isEmpty) return l10n.fieldRequired;
                    if (v != _passCtrl.text) return l10n.passwordsDontMatch;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: l10n.savePasswordButton,
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
