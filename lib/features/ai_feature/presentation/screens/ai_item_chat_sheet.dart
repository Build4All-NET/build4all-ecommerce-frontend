import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/ai_chat_bloc.dart';
import '../bloc/ai_chat_event.dart';
import '../bloc/ai_chat_state.dart';
import '../../domain/entities/ai_message.dart';

import 'package:flutter_markdown/flutter_markdown.dart';



class AiItemChatSheet extends StatefulWidget {
  final int itemId;
  final String title;
  final String? imageUrl;

  const AiItemChatSheet({
    super.key,
    required this.itemId,
    required this.title,
    this.imageUrl,
  });

  @override
  State<AiItemChatSheet> createState() => _AiItemChatSheetState();
}

class _AiItemChatSheetState extends State<AiItemChatSheet> {
  final TextEditingController _c = TextEditingController();

  @override
  void initState() {
    super.initState();

    // ✅ Open chat context (NO auto-send)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AiChatBloc>().add(
            AiChatOpened(
              itemId: widget.itemId,
              title: widget.title,
              imageUrl: widget.imageUrl,
            ),
          );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _sendText(String text) {
    final txt = text.trim();
    if (txt.isEmpty) return;

    _c.clear();

    try {
      context.read<AiChatBloc>().add(AiChatSendPressed(txt));
    } catch (_) {
      final l10n = AppLocalizations.of(context)!;
      AppToast.error(
        context,
        l10n.ai_chat_error_send_failed,
        
      );
    }
  }

  void _sendFromInput() {
    _sendText(_c.text);
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.border.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              _Header(title: widget.title, imageUrl: widget.imageUrl),
              Divider(height: 1, color: colors.border.withOpacity(0.2)),

              /// ✅ Chat list
              Expanded(
                child: BlocBuilder<AiChatBloc, AiChatState>(
                  builder: (context, state) {
                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(14),
                      itemCount:
                          state.messages.length + (state.isSending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (state.isSending && i == state.messages.length) {
                          return _TypingBubble();
                        }
                        final m = state.messages[i];
                        return _Bubble(msg: m);
                      },
                    );
                  },
                ),
              ),

              /// ✅ Suggestions ABOVE input (always visible)
              BlocBuilder<AiChatBloc, AiChatState>(
                builder: (context, state) {
                  // ✅ show suggestions until the user sends anything
                  final hasUserMessage = state.messages.any((m) => m.isUser);
                  final showSuggestions = !hasUserMessage;

                  if (!showSuggestions) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: _SuggestedPrompts(
                      onSelect: _sendText,
                    ),
                  );
                },
              ),

              /// ✅ Input bar
              _InputBar(
                controller: _c,
                onSend: _sendFromInput,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? imageUrl;

  const _Header({required this.title, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if ((imageUrl ?? '').trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: colors.border.withOpacity(0.12),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.border.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome, color: colors.primary),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colors.body.withOpacity(0.75)),
          )
        ],
      ),
    );
  }
}

class _SuggestedPrompts extends StatelessWidget {
  final void Function(String) onSelect;

  const _SuggestedPrompts({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = context.watch<ThemeCubit>().state;
    final colors = theme.tokens.colors;

    // ✅ suggestions from l10n
    final suggestions = <String>[
      l10n.ai_prompt_summary,
      l10n.ai_prompt_features,
      l10n.ai_prompt_best_use,
    ].where((s) => s.trim().isNotEmpty).toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((s) {
        return ActionChip(
          label: Text(s),
          onPressed: () => onSelect(s),
          backgroundColor: colors.primary.withOpacity(0.12),
          labelStyle: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: colors.primary.withOpacity(0.30)),
          ),
        );
      }).toList(),
    );
  }
}

class _Bubble extends StatelessWidget {
  final AiMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;
    final t = Theme.of(context).textTheme;

    final isUser = msg.isUser;
    final bg = isUser ? colors.primary : colors.border.withOpacity(0.10);
    final fg = isUser ? colors.onPrimary : colors.body;

    final border = isUser ? null : Border.all(color: colors.border.withOpacity(0.18));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: border,
        ),
        child: isUser
            ? Text(
                msg.text,
                style: t.bodyMedium?.copyWith(color: fg, height: 1.25),
              )
            : MarkdownBody(
                data: msg.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: t.bodyMedium?.copyWith(color: fg, height: 1.35),
                  h1: t.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w900),
                  h2: t.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w900),
                  h3: t.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w900),
                  strong: t.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w900),
                  em: t.bodyMedium?.copyWith(color: fg, fontStyle: FontStyle.italic),
                  listBullet: t.bodyMedium?.copyWith(color: fg),
                  blockquote: t.bodyMedium?.copyWith(color: fg.withOpacity(0.85)),
                  code: TextStyle(
                    color: fg,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    backgroundColor: colors.background.withOpacity(0.35),
                  ),
                ),
                onTapLink: (text, href, title) async {
                  if (href == null) return;
                  final uri = Uri.tryParse(href);
                  if (uri == null) return;
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.border.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withOpacity(0.18)),
        ),
        child: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        top: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: l10n.ai_chat_hint,
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: colors.border.withOpacity(0.25)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: colors.border.withOpacity(0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.primary, width: 1.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: onSend,
              icon: Icon(Icons.send, color: colors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
