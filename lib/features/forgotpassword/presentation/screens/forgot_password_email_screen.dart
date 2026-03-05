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
import 'forgot_password_verify_screen.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      AppToast.error(context, l10n.fieldRequired);
      return;
    }

    context.read<ForgotPasswordBloc>().add(
      ForgotSendCodePressed(
        email: email,
        ownerProjectLinkId: int.tryParse(Env.ownerProjectLinkId) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthCardShell(
      title: l10n.forgotTitle,
      subtitle: l10n.forgotSubtitle,
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
            // go to verify screen
           Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: ctx.read<ForgotPasswordBloc>(), // ✅ carry same bloc
                  child: ForgotPasswordVerifyScreen(
                    email: _emailCtrl.text.trim(),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: l10n.emailLabel,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return l10n.fieldRequired;
                    if (!val.contains('@')) return l10n.invalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: l10n.forgotSendCode,
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.forgotTip,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
