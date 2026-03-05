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
import 'forgot_password_new_password_screen.dart';

class ForgotPasswordVerifyScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordVerifyScreen({super.key, required this.email});

  @override
  State<ForgotPasswordVerifyScreen> createState() =>
      _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState
    extends State<ForgotPasswordVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    context.read<ForgotPasswordBloc>().add(
      ForgotVerifyCodePressed(
        email: widget.email,
        code: _codeCtrl.text.trim(),
        ownerProjectLinkId: int.tryParse(Env.ownerProjectLinkId) ?? 0,
      ),
    );
  }

  void _resend() {
    context.read<ForgotPasswordBloc>().add(
      ForgotSendCodePressed(
        email: widget.email,
        ownerProjectLinkId: int.tryParse(Env.ownerProjectLinkId) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthCardShell(
      title: l10n.forgotVerifyTitle,
      subtitle: l10n.forgotVerifySubtitle(widget.email),
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
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: ctx.read<ForgotPasswordBloc>(), // ✅ same bloc again
                  child: ForgotPasswordNewPasswordScreen(
                    email: widget.email,
                    code: _codeCtrl.text.trim(),
                  ),
                ),
              ),
            );

            ctx.read<ForgotPasswordBloc>().add(const ForgotClearMessage());
          }
        },
        builder: (ctx, state) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: l10n.codeLabel,
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return l10n.fieldRequired;
                    if (val.length < 4) return l10n.codeTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: l10n.verifyButton,
                  isLoading: state.isLoading,
                  onPressed: _verify,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: state.isLoading ? null : _resend,
                  child: Text(l10n.resendCode),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
