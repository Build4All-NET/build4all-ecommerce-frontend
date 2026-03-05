import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/core/config/env.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../common/widgets/app_toast.dart';
import '../../../../common/widgets/app_text_field.dart';

import '../../data/services/user_profile_api_service.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/usecases/get_user_by_id.dart';
import '../../domain/usecases/update_user_profile.dart';
import '../../domain/usecases/delete_user.dart';
import '../../domain/usecases/verify_email_change.dart';
import '../../domain/usecases/resend_email_change.dart';

import '../bloc/edit_profile_bloc.dart';
import '../bloc/edit_profile_event.dart';
import '../bloc/edit_profile_state.dart';

String _apiRoot() {
  final raw = (g.appServerRoot ?? '').trim().isNotEmpty
      ? (g.appServerRoot ?? '').trim()
      : Env.apiBaseUrl.trim();

  final noTrail = raw.replaceFirst(RegExp(r'/+$'), '');
  final noApi = noTrail.replaceFirst(RegExp(r'/api$'), '');
  return '$noApi/api';
}

String _serverRootNoApi() => _apiRoot().replaceFirst(RegExp(r'/api$'), '');

String _resolveImageUrl(String? url) {
  final u = (url ?? '').trim();
  if (u.isEmpty) return '';
  if (u.startsWith('http://') || u.startsWith('https://')) return u;

  final root = _serverRootNoApi();
  final path = u.startsWith('/') ? u : '/$u';
  return '$root$path';
}

/// ✅ debug interceptor (optional)
class _EditProfileAuthDebugInterceptor extends Interceptor {
  final String Function() tokenGetter;
  _EditProfileAuthDebugInterceptor({required this.tokenGetter});

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    final t = tokenGetter().trim();
    if (t.isNotEmpty) {
      o.headers['Authorization'] = o.headers['Authorization'] ?? 'Bearer $t';
    }
    // ignore: avoid_print
    print(">>> URL: ${o.uri}");
    // ignore: avoid_print
    print(">>> AUTH: ${o.headers['Authorization']}");
    // ignore: avoid_print
    print(">>> CT: ${o.headers['Content-Type']}");
    h.next(o);
  }
}

class EditProfileScreen extends StatefulWidget {
  final int userId;
  final String token;
  final int ownerProjectLinkId;

  final VoidCallback onLogoutAfterDelete;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.token,
    required this.ownerProjectLinkId,
    required this.onLogoutAfterDelete,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _userCtrl = TextEditingController();

  // ✅ email field
  final _emailCtrl = TextEditingController();
  String _originalEmail = '';

  bool _public = true;

  String? _pickedImagePath;
  bool _removeImage = false;

  bool _filledOnce = false;
  bool _loggedOutAfterDelete = false;

  // ✅ save + OTP flow guards (prevent dialog re-open loop)
  bool _saveRequested = false;
  bool _emailFlowActive = false;
  bool _emailDialogOpen = false;
  bool _awaitingVerifyReload = false;

  // inline errors
  String? _firstError;
  String? _lastError;
  String? _userError;
  String? _emailError;

  late final EditProfileBloc _bloc;

  // ✅ RULES: all fields min 3 chars (first/last/username/email)
  static const int _minLen = 3;
  static const int _maxName = 40;
  static const int _maxUsername = 20;

  static final RegExp _usernameAllowed = RegExp(r'^[A-Za-z0-9_]+$');

  @override
  void initState() {
    super.initState();

    _firstCtrl.addListener(_clearFieldErrorsIfNeeded);
    _lastCtrl.addListener(_clearFieldErrorsIfNeeded);
    _userCtrl.addListener(_clearFieldErrorsIfNeeded);
    _emailCtrl.addListener(_clearFieldErrorsIfNeeded);

    final dio = g.appDio ?? Dio();
    final has = dio.interceptors.any((i) => i is _EditProfileAuthDebugInterceptor);
    if (!has) {
      dio.interceptors.add(
        _EditProfileAuthDebugInterceptor(
          tokenGetter: () => _cleanToken(widget.token),
        ),
      );
    }

    final api = UserProfileApiService(dio: dio, baseUrl: _apiRoot());
    final repo = UserProfileRepositoryImpl(api);

    _bloc = EditProfileBloc(
      getUserById: GetUserById(repo),
      updateUserProfile: UpdateUserProfile(repo),
      deleteUser: DeleteUser(repo),
      verifyEmailChange: VerifyEmailChange(repo),
      resendEmailChange: ResendEmailChange(repo),
    );

    _bloc.add(
      LoadEditProfile(
        token: widget.token,
        userId: widget.userId,
      ),
    );
  }

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  // ✅ Name validation (min 3 + basic allowed chars)
  bool _isNameValid(String s) {
    if (s.length < _minLen || s.length > _maxName) return false;
    // letters + spaces + hyphen + apostrophe (supports most names)
    return RegExp(r"^[A-Za-zÀ-ÿ' -]+$").hasMatch(s);
  }

  // ✅ Username validation (min 3, max 20, allowed A-Z a-z 0-9 _, no __, no leading/trailing _)
  bool _isUsernameValid(String s) {
    if (s.length < _minLen || s.length > _maxUsername) return false;
    if (!_usernameAllowed.hasMatch(s)) return false;
    if (s.startsWith('_') || s.endsWith('_')) return false;
    if (s.contains('__')) return false;
    return true;
  }

  bool _isEmailValid(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  bool _validateInputs(AppLocalizations loc) {
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final username = _userCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    String? firstError;
    String? lastError;
    String? userError;
    String? emailError;

    // Username
    if (username.isEmpty) {
      userError = loc.fieldRequired;
    } else if (username.length < _minLen) {
      userError = 'Minimum $_minLen characters';
    } else if (!_isUsernameValid(username)) {
      userError = loc.editProfile_usernameInvalid;
    }

    // First name
    if (first.isEmpty) {
      firstError = loc.fieldRequired;
    } else if (first.length < _minLen) {
      firstError = 'Minimum $_minLen characters';
    } else if (!_isNameValid(first)) {
      firstError = 'Invalid name';
    }

    // Last name
    if (last.isEmpty) {
      lastError = loc.fieldRequired;
    } else if (last.length < _minLen) {
      lastError = 'Minimum $_minLen characters';
    } else if (!_isNameValid(last)) {
      lastError = 'Invalid name';
    }

    // ✅ Email REQUIRED (since you said ALL fields)
    if (email.isEmpty) {
      emailError = loc.fieldRequired;
    } else if (email.length < _minLen) {
      emailError = 'Minimum $_minLen characters';
    } else if (!_isEmailValid(email)) {
      emailError = loc.editProfile_invalidEmail;
    }

    setState(() {
      _userError = userError;
      _firstError = firstError;
      _lastError = lastError;
      _emailError = emailError;
    });

    return userError == null &&
        firstError == null &&
        lastError == null &&
        emailError == null;
  }

  void _clearFieldErrorsIfNeeded() {
    bool changed = false;

    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final username = _userCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (_userError != null && username.length >= _minLen && _isUsernameValid(username)) {
      _userError = null;
      changed = true;
    }

    if (_firstError != null && first.length >= _minLen && _isNameValid(first)) {
      _firstError = null;
      changed = true;
    }

    if (_lastError != null && last.length >= _minLen && _isNameValid(last)) {
      _lastError = null;
      changed = true;
    }

    if (_emailError != null) {
      if (email.isNotEmpty && email.length >= _minLen && _isEmailValid(email)) {
        _emailError = null;
        changed = true;
      }
    }

    if (changed && mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      maxHeight: 1400,
    );
    if (x == null) return;

    setState(() {
      _pickedImagePath = x.path;
      _removeImage = false;
    });
  }

  Future<bool> _showEmailOtpDialog({
    required AppLocalizations loc,
    required String pendingEmail,
  }) async {
    if (_emailDialogOpen) return false;
    _emailDialogOpen = true;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _EmailOtpDialog(
          loc: loc,
          pendingEmail: pendingEmail,
          onVerify: (code) => _bloc.verifyEmailChangeDirect(
            token: widget.token,
            userId: widget.userId,
            code: code,
          ),
          onResend: () => _bloc.resendEmailChangeDirect(
            token: widget.token,
            userId: widget.userId,
          ),
        );
      },
    );

    _emailDialogOpen = false;
    return ok == true;
  }

  @override
  void dispose() {
    _bloc.close();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _userCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = context.watch<ThemeCubit>().state.tokens;
    final colors = theme.colors;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<EditProfileBloc, EditProfileState>(
        listener: (context, state) {
          // ✅ Errors -> toast (keep it clean)
          if (state.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              AppToast.error(this.context, state.error!);
            });
          }

          // ✅ delete success -> logout
          if (state.didDelete && !_loggedOutAfterDelete) {
            _loggedOutAfterDelete = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              widget.onLogoutAfterDelete();
            });
            return;
          }

          final u = state.user;

          // ✅ initial fill (safe post-frame)
          if (u != null && !_filledOnce) {
            _filledOnce = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              _firstCtrl.text = u.firstName;
              _lastCtrl.text = u.lastName;
              _userCtrl.text = u.username ?? '';
              _public = u.publicProfile;

              _emailCtrl.text = u.email ?? '';
              _originalEmail = (u.email ?? '').trim();

              setState(() {});
            });
          }

          // ✅ after verify reload: close flow + update email + close screen
          if (_awaitingVerifyReload && u != null && !u.emailVerificationRequired) {
            _awaitingVerifyReload = false;
            _emailFlowActive = false;
            _saveRequested = false;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              // update local original email so next save won't resend again
              _emailCtrl.text = u.email ?? '';
              _originalEmail = (u.email ?? '').trim();

              // return updated user to previous screen
              Navigator.pop(this.context, u);
            });
            return;
          }

          // ✅ after SAVE request:
          // open OTP dialog ONLY ONCE, only if user asked save, and backend requires verification
          if (_saveRequested && !state.saving && u != null) {
            if (u.emailVerificationRequired) {
              if (_emailFlowActive) return; // prevent reopen loop
              _emailFlowActive = true;

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;

                // clean info message
                AppToast.error(this.context, loc.editProfile_codeSentToast);

                final pending = (u.pendingEmail ?? '').trim();
                final ok = await _showEmailOtpDialog(
                  loc: loc,
                  pendingEmail: pending.isNotEmpty ? pending : _emailCtrl.text.trim(),
                );

                if (!mounted) return;

                if (ok) {
                  // ✅ verified -> reload user then pop screen in the reload handler above
                  _awaitingVerifyReload = true;
                  _bloc.add(
                    LoadEditProfile(
                      token: widget.token,
                      userId: widget.userId,
                    ),
                  );
                } else {
                  // ✅ failed/canceled -> allow retry by pressing Save again
                  _emailFlowActive = false;
                  _saveRequested = false;
                }
              });

              return;
            } else {
              // ✅ normal save (no email verification) -> pop back with updated user
              if (state.error == null) {
                _saveRequested = false;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  Navigator.pop(this.context, u);
                });
              }
            }
          }
        },
        builder: (context, state) {
          final u = state.user;
          final imageUrl = u == null ? '' : _resolveImageUrl(u.profileImageUrl);

          return Scaffold(
            appBar: AppBar(
              title: Text(loc.editProfileTitle),
              backgroundColor: colors.background,
              foregroundColor: colors.label,
              elevation: 0,
            ),
            backgroundColor: colors.background,
            body: state.loading
                ? const Center(child: CircularProgressIndicator())
                : u == null
                    ? Center(
                        child: Text(
                          loc.profileLoadFailed,
                          style: TextStyle(color: colors.label),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _ProfileHeader(
                            changeLabel: loc.editProfile_change,
                            removeLabel: loc.editProfile_remove,
                            imageUrl: imageUrl,
                            pickedPath: _pickedImagePath,
                            removeImage: _removeImage,
                            onPick: _pickImage,
                            onRemove: () => setState(() {
                              _pickedImagePath = null;
                              _removeImage = true;
                            }),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          AppTextField(
                            controller: _emailCtrl,
                            label: loc.editProfile_emailLabel,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          if (_emailError != null) ...[
                            const SizedBox(height: 6),
                            Text(_emailError!, style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 12),

                          // Username
                          AppTextField(controller: _userCtrl, label: loc.username),
                          if (_userError != null) ...[
                            const SizedBox(height: 6),
                            Text(_userError!, style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 12),

                          // First
                          AppTextField(controller: _firstCtrl, label: loc.firstName),
                          if (_firstError != null) ...[
                            const SizedBox(height: 6),
                            Text(_firstError!, style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 12),

                          // Last
                          AppTextField(controller: _lastCtrl, label: loc.lastName),
                          if (_lastError != null) ...[
                            const SizedBox(height: 6),
                            Text(_lastError!, style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 12),

                          SwitchListTile(
                            value: _public,
                            onChanged: (v) => setState(() => _public = v),
                            title: Text(loc.publicProfile, style: TextStyle(color: colors.label)),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: state.saving
                                ? null
                                : () {
                                    final valid = _validateInputs(loc);
                                    if (!valid) {
                                      AppToast.error(
                                        context,
                                        _emailError ??
                                            _userError ??
                                            _firstError ??
                                            _lastError ??
                                            loc.fieldRequired,
                                        
                                      );
                                      return;
                                    }

                                    // ✅ user pressed save -> mark requested
                                    _saveRequested = true;
                                    _awaitingVerifyReload = false;

                                    final newEmailRaw = _emailCtrl.text.trim();
                                    final oldEmailRaw = _originalEmail.trim();

                                    final emailToSend = (newEmailRaw.toLowerCase() ==
                                            oldEmailRaw.toLowerCase())
                                        ? null
                                        : newEmailRaw;

                                    _bloc.add(
                                      SaveEditProfile(
                                        token: widget.token,
                                        userId: widget.userId,
                                        firstName: _firstCtrl.text.trim(),
                                        lastName: _lastCtrl.text.trim(),
                                        username: _userCtrl.text.trim(),
                                        email: emailToSend,
                                        isPublicProfile: _public,
                                        imageFilePath: _pickedImagePath,
                                        imageRemoved: _removeImage,
                                      ),
                                    );
                                  },
                            child: state.saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(loc.save),
                          ),

                          const SizedBox(height: 24),
                          Divider(color: colors.border),
                          const SizedBox(height: 12),

                          _DeleteSection(
                            deleting: state.deleting,
                            loc: loc,
                            onDelete: (password) {
                              _bloc.add(
                                DeleteAccount(
                                  token: widget.token,
                                  userId: widget.userId,
                                  password: password,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String changeLabel;
  final String removeLabel;

  final String? imageUrl;
  final String? pickedPath;
  final bool removeImage;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ProfileHeader({
    required this.changeLabel,
    required this.removeLabel,
    required this.imageUrl,
    required this.pickedPath,
    required this.removeImage,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeCubit>().state.tokens;
    final colors = theme.colors;

    ImageProvider? provider;
    if (pickedPath != null) {
      provider = FileImage(File(pickedPath!));
    } else if (!removeImage && imageUrl != null && imageUrl!.trim().isNotEmpty) {
      provider = NetworkImage(imageUrl!.trim());
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: colors.surface,
          backgroundImage: provider,
          child: provider == null ? Icon(Icons.person, color: colors.label, size: 40) : null,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo),
              label: Text(changeLabel),
            ),
            OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              label: Text(removeLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeleteSection extends StatefulWidget {
  final void Function(String password) onDelete;
  final bool deleting;
  final AppLocalizations loc;

  const _DeleteSection({
    required this.onDelete,
    required this.deleting,
    required this.loc,
  });

  @override
  State<_DeleteSection> createState() => _DeleteSectionState();
}

class _DeleteSectionState extends State<_DeleteSection> {
  final _passCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.dangerZone, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        AppTextField(
          controller: _passCtrl,
          label: loc.password,
          obscureText: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: widget.deleting
              ? null
              : () {
                  final pwd = _passCtrl.text.trim();
                  if (pwd.isEmpty) {
                    setState(() => _error = loc.fieldRequired);
                    return;
                  }
                  setState(() => _error = null);
                  widget.onDelete(pwd);
                },
          child: widget.deleting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(loc.deleteAccount),
        ),
      ],
    );
  }
}

/// ✅ OTP dialog: closes automatically on SUCCESS and on FAILURE with clean toast
class _EmailOtpDialog extends StatefulWidget {
  final AppLocalizations loc;
  final String pendingEmail;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;

  const _EmailOtpDialog({
    required this.loc,
    required this.pendingEmail,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<_EmailOtpDialog> createState() => _EmailOtpDialogState();
}

class _EmailOtpDialogState extends State<_EmailOtpDialog> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  String _cleanErr(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;

    return AlertDialog(
      title: Text(loc.editProfile_verifyNewEmailTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.editProfile_codeSentTo),
            const SizedBox(height: 6),
            Text(widget.pendingEmail, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: loc.editProfile_codeLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    await widget.onResend();
                    if (!mounted) return;
                    AppToast.error(context, loc.editProfile_resend);
                  } catch (e) {
                    if (!mounted) return;
                    AppToast.error(context, _cleanErr(e));
                    Navigator.of(context, rootNavigator: true).pop(false);
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: Text(loc.editProfile_resend),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  final code = _codeCtrl.text.trim();
                  if (code.isEmpty) {
                    AppToast.error(context, loc.editProfile_codeRequired);
                    Navigator.of(context, rootNavigator: true).pop(false);
                    return;
                  }

                  setState(() => _loading = true);
                  try {
                    await widget.onVerify(code);
                    if (!mounted) return;
                    AppToast.error(context, loc.editProfile_emailUpdatedToast);
                    Navigator.of(context, rootNavigator: true).pop(true);
                  } catch (e) {
                    if (!mounted) return;
                    AppToast.error(context, _cleanErr(e));
                    Navigator.of(context, rootNavigator: true).pop(false);
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(loc.editProfile_verify),
        ),
      ],
    );
  }
}