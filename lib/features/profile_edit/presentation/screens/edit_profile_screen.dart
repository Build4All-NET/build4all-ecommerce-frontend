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

/// ✅ Custom interceptor type so we can avoid adding duplicates
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

  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    // ignore: avoid_print
    print("xxx STATUS: ${e.response?.statusCode}");
    // ignore: avoid_print
    print("xxx BODY: ${e.response?.data}");
    h.next(e);
  }
}

class EditProfileScreen extends StatefulWidget {
  final int userId;
  final String token;
  final int ownerProjectLinkId;

  // ✅ parent passes logout handler (clear token + go login)
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

  bool _public = true;

  String? _pickedImagePath;
  bool _removeImage = false;
  bool _filledOnce = false;

  bool _poppedAfterSave = false;

  // ✅ guard so we don’t logout twice
  bool _loggedOutAfterDelete = false;

  // ✅ validation errors (inline under fields)
  String? _firstError;
  String? _lastError;
  String? _userError;

  late final EditProfileBloc _bloc;

  @override
  void initState() {
    super.initState();

    // clear inline validation errors while typing
    _firstCtrl.addListener(_clearFieldErrorsIfNeeded);
    _lastCtrl.addListener(_clearFieldErrorsIfNeeded);
    _userCtrl.addListener(_clearFieldErrorsIfNeeded);

    final dio = g.appDio ?? Dio();

    final has =
        dio.interceptors.any((i) => i is _EditProfileAuthDebugInterceptor);
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
    );

    _bloc.add(
      LoadEditProfile(
        token: widget.token,
        userId: widget.userId,
        ownerProjectLinkId: widget.ownerProjectLinkId,
      ),
    );
  }

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  bool _validateInputs(AppLocalizations loc) {
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final username = _userCtrl.text.trim();

    String? firstError;
    String? lastError;
    String? userError;

    if (username.isEmpty) userError = loc.fieldRequired;
    if (first.isEmpty) firstError = loc.fieldRequired;
    if (last.isEmpty) lastError = loc.fieldRequired;

    setState(() {
      _userError = userError;
      _firstError = firstError;
      _lastError = lastError;
    });

    return userError == null && firstError == null && lastError == null;
  }

  void _clearFieldErrorsIfNeeded() {
    bool changed = false;

    if (_userError != null && _userCtrl.text.trim().isNotEmpty) {
      _userError = null;
      changed = true;
    }
    if (_firstError != null && _firstCtrl.text.trim().isNotEmpty) {
      _firstError = null;
      changed = true;
    }
    if (_lastError != null && _lastCtrl.text.trim().isNotEmpty) {
      _lastError = null;
      changed = true;
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _bloc.close();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = context.watch<ThemeCubit>().state.tokens;
    final colors = theme.colors;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<EditProfileBloc, EditProfileState>(
        listener: (context, state) {
          if (state.error != null) {
            AppToast.show(context, state.error!, isError: true);
          }

          // ✅ DELETE SUCCESS: logout immediately
          if (state.didDelete && !_loggedOutAfterDelete) {
            _loggedOutAfterDelete = true;

            if (state.success != null) {
              AppToast.show(context, state.success!);
            }

            Future.microtask(() {
              if (mounted) widget.onLogoutAfterDelete();
            });
            return;
          }

          // ✅ SAVE SUCCESS: normal behavior (pop with updated user)
          if (state.success != null && !state.didDelete) {
            AppToast.show(context, state.success!);

            if (!_poppedAfterSave && state.user != null) {
              _poppedAfterSave = true;
              Future.microtask(() {
                if (mounted) Navigator.pop(context, state.user);
              });
            }
          }

          final u = state.user;
          if (u != null && !_filledOnce) {
            _filledOnce = true;
            _firstCtrl.text = u.firstName;
            _lastCtrl.text = u.lastName;
            _userCtrl.text = u.username ?? '';
            _public = u.publicProfile;

            // clear stale inline errors after initial fill
            _firstError = null;
            _lastError = null;
            _userError = null;

            if (mounted) setState(() {});
          }
        },
        builder: (context, state) {
          final u = state.user;
          final resolvedImageUrl =
              u == null ? '' : _resolveImageUrl(u.profileImageUrl);

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
                            imageUrl: resolvedImageUrl,
                            pickedPath: _pickedImagePath,
                            removeImage: _removeImage,
                            onPick: _pickImage,
                            onRemove: () => setState(() {
                              _pickedImagePath = null;
                              _removeImage = true;
                            }),
                          ),
                          const SizedBox(height: 16),

                          // Username (required)
                          AppTextField(controller: _userCtrl, label: loc.username),
                          if (_userError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _userError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // First name (required)
                          AppTextField(
                              controller: _firstCtrl, label: loc.firstName),
                          if (_firstError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _firstError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Last name (required)
                          AppTextField(controller: _lastCtrl, label: loc.lastName),
                          if (_lastError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _lastError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 12),

                          SwitchListTile(
                            value: _public,
                            onChanged: (v) => setState(() => _public = v),
                            title: Text(
                              loc.publicProfile,
                              style: TextStyle(color: colors.label),
                            ),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: state.saving
                                ? null
                                : () {
                                    // ✅ local validation before calling API
                                    final valid = _validateInputs(loc);
                                    if (!valid) {
                                      AppToast.show(
                                        context,
                                        loc.fieldRequired,
                                        isError: true,
                                      );
                                      return;
                                    }

                                    context.read<EditProfileBloc>().add(
                                          SaveEditProfile(
                                            token: widget.token,
                                            userId: widget.userId,
                                            ownerProjectLinkId:
                                                widget.ownerProjectLinkId,
                                            firstName: _firstCtrl.text.trim(),
                                            lastName: _lastCtrl.text.trim(),
                                            // ✅ required now (no null fallback)
                                            username: _userCtrl.text.trim(),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(loc.save),
                          ),

                          const SizedBox(height: 24),
                          Divider(color: colors.border),
                          const SizedBox(height: 12),

                          _DeleteSection(
                            deleting: state.deleting,
                            onDelete: (password) {
                              context.read<EditProfileBloc>().add(
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
  final String? imageUrl;
  final String? pickedPath;
  final bool removeImage;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ProfileHeader({
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
          child: provider == null
              ? Icon(Icons.person, color: colors.label, size: 40)
              : null,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo),
              label: const Text("Change"),
            ),
            OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              label: const Text("Remove"),
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

  const _DeleteSection({
    required this.onDelete,
    required this.deleting,
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
    final loc = AppLocalizations.of(context)!;

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
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.deleteAccount),
        ),
      ],
    );
  }
}