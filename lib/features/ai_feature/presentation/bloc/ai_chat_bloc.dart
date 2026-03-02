// lib/features/ai_feature/presentation/bloc/ai_chat_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4front/core/network/globals.dart' as g;

import '../../domain/entities/ai_message.dart';
import '../../domain/usecases/chat_item_usecase.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final ChatItemUseCase useCase;

  int? _itemId;

  AiChatBloc({required this.useCase}) : super(AiChatState.initial()) {
    on<AiChatOpened>(_onOpened);
    on<AiChatSendPressed>(_onSend);
    on<AiChatClear>((e, emit) => emit(AiChatState.initial()));
  }

  void _onOpened(AiChatOpened e, Emitter<AiChatState> emit) {
    _itemId = e.itemId;

    final hello = AiMessage(
      role: AiMessageRole.assistant,
      text: "Ask me anything about “${e.title}”. 👀",
      at: DateTime.now(),
    );
    emit(state.copyWith(messages: [hello]));
  }

  Future<void> _onSend(AiChatSendPressed e, Emitter<AiChatState> emit) async {
    final msg = e.text.trim();
    if (msg.isEmpty || _itemId == null) return;

    final token = (g.authToken ?? '').toString().trim(); // ✅ replace with your real token getter
    if (token.isEmpty) {
      emit(state.copyWith(isSending: false));
      throw Exception('Not authenticated');
    }

    final now = DateTime.now();
    final userMessage = AiMessage(role: AiMessageRole.user, text: msg, at: now);

    emit(state.copyWith(
      isSending: true,
      messages: [...state.messages, userMessage],
    ));

    try {
      final answer = await useCase(
        token: token,
        itemId: _itemId!,
        message: msg,
      );

      final botMessage = AiMessage(
        role: AiMessageRole.assistant,
        text: answer.isEmpty ? "I got nothing… try rephrasing 😅" : answer,
        at: DateTime.now(),
      );

      emit(state.copyWith(
        isSending: false,
        messages: [...state.messages, botMessage],
      ));
    } catch (err) {
      emit(state.copyWith(isSending: false));
      rethrow;
    }
  }
}