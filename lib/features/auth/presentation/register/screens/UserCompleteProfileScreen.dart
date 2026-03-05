import 'package:build4front/common/widgets/app_text_field.dart';
import 'package:build4front/common/widgets/primary_button.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/app_image_picker_avatar.dart';

import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/theme/theme_cubit.dart';

import 'package:build4front/features/auth/data/repository/auth_repository_impl.dart';
import 'package:build4front/features/auth/domain/usecases/CompleteUserProfile.dart';

import 'package:build4front/features/auth/presentation/login/screens/user_login_screen.dart';
import 'package:build4front/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';



class UserCompleteProfileScreen extends StatefulWidget {
  final int pendingId;
  final int ownerProjectLinkId;
  final AppConfig appConfig;

  const UserCompleteProfileScreen({
    super.key,
    required this.pendingId,
    required this.ownerProjectLinkId,
    required this.appConfig,
  });

  @override
  State<UserCompleteProfileScreen> createState() =>
      _UserCompleteProfileScreenState();
}

class _UserCompleteProfileScreenState extends State<UserCompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Step fields
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  // ✅ Focus nodes to jump to problem fields
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _usernameFocus = FocusNode();

  bool _isPublicProfile = true;
  bool _isLoading = false;
  bool _submitting = false;

  int _currentStep = 0; // 0 = names, 1 = username, 2 = photo
  String? _profileImagePath;

  late final CompleteUserProfile _completeUserProfileUsecase;

  @override
  void initState() {
    super.initState();
    final repo = context.read<AuthRepositoryImpl>();
    _completeUserProfileUsecase = CompleteUserProfile(repo);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _usernameFocus.dispose();

    super.dispose();
  }

  void _jumpToStep({
    required int step,
    String? toastMessage,
    FocusNode? focus,
  }) {
    if (!mounted) return;

    setState(() {
      _currentStep = step;
    });

    if (toastMessage != null && toastMessage.trim().isNotEmpty) {
      AppToast.error(context, toastMessage.trim());
    }

    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus.requestFocus();
      });
    }
  }

  bool _validateCurrentStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_currentStep == 0) {
      final f = _firstNameCtrl.text.trim();
      final l = _lastNameCtrl.text.trim();

      if (f.isEmpty) {
        _jumpToStep(
          step: 0,
          toastMessage: l10n.fieldRequired,
          focus: _firstNameFocus,
        );
        return false;
      }
      if (l.isEmpty) {
        _jumpToStep(
          step: 0,
          toastMessage: l10n.fieldRequired,
          focus: _lastNameFocus,
        );
        return false;
      }
      return true;
    }

    if (_currentStep == 1) {
      final u = _usernameCtrl.text.trim();

      if (u.isEmpty) {
        _jumpToStep(
          step: 1,
          toastMessage: l10n.fieldRequired,
          focus: _usernameFocus,
        );
        return false;
      }
      if (u.length < 3) {
        _jumpToStep(
          step: 1,
          toastMessage: l10n.usernameTooShort,
          focus: _usernameFocus,
        );
        return false;
      }

      // optional but useful:
      final reg = RegExp(r'^[a-zA-Z0-9_.]+$');
      if (!reg.hasMatch(u)) {
        _jumpToStep(
          step: 1,
          toastMessage: 'Username: فقط حروف/أرقام/underscore/dot',
          focus: _usernameFocus,
        );
        return false;
      }

      return true;
    }

    return true; // step 2 (photo) optional
  }

  Future<void> _onNextOrFinishPressed(BuildContext context) async {
    if (_isLoading) return;

    if (_currentStep < 2) {
      if (_validateCurrentStep(context)) {
        setState(() => _currentStep += 1);
      }
      return;
    }

    // Last step → submit
    if (!_validateCurrentStep(context)) return;
    await _submitProfile(context);
  }

  void _routeCompleteProfileError(String message) {
    final msg = message.trim();
    final m = msg.toLowerCase();

    // ✅ Username issues → step 1
    if (m.contains('username') &&
        (m.contains('already') ||
            m.contains('in use') ||
            m.contains('taken') ||
            m.contains('exists'))) {
      _jumpToStep(step: 1, toastMessage: msg, focus: _usernameFocus);
      return;
    }

    // ✅ First/Last name issues → step 0
    if (m.contains('first') && m.contains('name')) {
      _jumpToStep(step: 0, toastMessage: msg, focus: _firstNameFocus);
      return;
    }
    if (m.contains('last') && m.contains('name')) {
      _jumpToStep(step: 0, toastMessage: msg, focus: _lastNameFocus);
      return;
    }

    // ✅ Photo/File issues → step 2
    if (m.contains('photo') ||
        m.contains('image') ||
        m.contains('avatar') ||
        m.contains('file')) {
      _jumpToStep(step: 2, toastMessage: msg);
      return;
    }

    // Fallback: show error and keep current step
    AppToast.error(context, msg.isEmpty ? 'Something went wrong' : msg,
        );
  }

  Future<void> _submitProfile(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (_submitting) return;
    _submitting = true;

    setState(() => _isLoading = true);

    try {
      final result = await _completeUserProfileUsecase(
        pendingId: widget.pendingId,
        username: _usernameCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        isPublicProfile: _isPublicProfile,
        ownerProjectLinkId: widget.ownerProjectLinkId,
        profileImagePath: _profileImagePath,
      );

      if (!mounted) return;

      if (result == null) {
        AppToast.error(context, 'Failed to complete profile');
        return;
      }

      AppToast.error(
        context,
        l10n.profileCompletedSuccessMessage,
       
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => UserLoginScreen(appConfig: widget.appConfig),
        ),
        (route) => false,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      final msg = (e.message ?? e.toString()).trim();
      _routeCompleteProfileError(msg);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, l10n.authErrorGeneric);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _submitting = false;
    }
  }

  String _stepTitle(AppLocalizations l10n) {
    switch (_currentStep) {
      case 0:
        return l10n.completeProfileNamesTitle;
      case 1:
        return l10n.completeProfileUsernameTitle;
      case 2:
      default:
        return l10n.completeProfilePhotoTitle;
    }
  }

  String _stepSubtitle(AppLocalizations l10n) {
    switch (_currentStep) {
      case 0:
        return l10n.completeProfileNamesSubtitle;
      case 1:
        return l10n.completeProfileUsernameSubtitle;
      case 2:
      default:
        return l10n.completeProfilePhotoSubtitle;
    }
  }

  String _primaryButtonLabel(AppLocalizations l10n) {
    if (_currentStep < 2) return l10n.nextStepButton;
    return l10n.saveProfileButton;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;
    final card = themeState.tokens.card;
    final t = Theme.of(context).textTheme;

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
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.background.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colors.border.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          '${_currentStep + 1} / 3',
                          style: t.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _stepTitle(l10n),
                        style: t.headlineSmall?.copyWith(
                          color: colors.label,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _stepSubtitle(l10n),
                        style: t.bodyMedium?.copyWith(color: colors.body),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_currentStep == 0) ...[
                      AppTextField(
                        label: l10n.firstNameLabel,
                        controller: _firstNameCtrl,
                        focusNode: _firstNameFocus,
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: l10n.lastNameLabel,
                        controller: _lastNameCtrl,
                        focusNode: _lastNameFocus,
                        validator: (_) => null,
                      ),
                    ] else if (_currentStep == 1) ...[
                      AppTextField(
                        label: l10n.usernameLabel,
                        controller: _usernameCtrl,
                        focusNode: _usernameFocus,
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Switch(
                            value: _isPublicProfile,
                            activeColor: colors.primary,
                            onChanged: (v) {
                              setState(() => _isPublicProfile = v);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.publicProfileLabel,
                                  style: t.bodyMedium?.copyWith(
                                    color: colors.label,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.publicProfileDescription,
                                  style: t.bodySmall?.copyWith(
                                    color: colors.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      AppImagePickerAvatar(
                        initialImagePath: _profileImagePath,
                        size: 96,
                        shape: AppImageShape.circle,
                        enableCamera: true,
                        enableGallery: true,
                        onImageChanged: (path) {
                          setState(() {
                            _profileImagePath = path;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.changePhotoHint,
                        style: t.bodySmall?.copyWith(color: colors.body),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_currentStep > 0) {
                                        setState(() => _currentStep -= 1);
                                      }
                                    },
                              child: Text(
                                l10n.previousStepButton,
                                style: t.bodyMedium?.copyWith(
                                  color: colors.body,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 8),
                        Expanded(
                          child: PrimaryButton(
                            label: _primaryButtonLabel(l10n),
                            isLoading: _isLoading,
                            onPressed: _isLoading
                                ? null
                                : () => _onNextOrFinishPressed(context),
                          ),
                        ),
                      ],
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
