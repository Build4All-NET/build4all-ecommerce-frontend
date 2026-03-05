// lib/features/ai_feature/presentation/bloc/ai_chat_bloc.dart
import 'dart:async';
import 'package:dio/dio.dart';
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

    emit(state.copyWith(messages: [hello], isSending: false));
  }

  Future<void> _onSend(AiChatSendPressed e, Emitter<AiChatState> emit) async {
    final msg = e.text.trim();
    if (msg.isEmpty || _itemId == null) return;

    final token = (g.authToken ?? '').toString().trim();
    if (token.isEmpty) {
      // ✅ don't throw -> don't crash UI
      emit(state.copyWith(
        isSending: false,
        messages: [
          ...state.messages,
          AiMessage(
            role: AiMessageRole.assistant,
            text: "You’re not logged in. Please login first 🙂",
            at: DateTime.now(),
          ),
        ],
      ));
      return;
    }

    final userMessage = AiMessage(
      role: AiMessageRole.user,
      text: msg,
      at: DateTime.now(),
    );

    // ✅ freeze the list for this request (avoid stale state issues)
    final baseMessages = [...state.messages, userMessage];

    emit(state.copyWith(isSending: true, messages: baseMessages));

    try {
      // ✅ Keep this below Dio receiveTimeout (60s) so we can handle it nicely
      final answer = await useCase(
        token: token,
        itemId: _itemId!,
        message: msg,
      ).timeout(const Duration(seconds: 55));

      final botMessage = AiMessage(
        role: AiMessageRole.assistant,
        text: answer.isEmpty ? "I got nothing… try rephrasing 😅" : answer,
        at: DateTime.now(),
      );

      emit(state.copyWith(
        isSending: false,
        messages: [...baseMessages, botMessage],
      ));
    } on TimeoutException {
      emit(state.copyWith(
        isSending: false,
        messages: [
          ...baseMessages,
          AiMessage(
            role: AiMessageRole.assistant,
            text: "This is taking too long ⏳. Try again in a sec.",
            at: DateTime.now(),
          ),
        ],
      ));
    } on DioException catch (ex) {
      final isTimeout = ex.type == DioExceptionType.receiveTimeout ||
          ex.type == DioExceptionType.connectionTimeout ||
          ex.type == DioExceptionType.sendTimeout;

      // Try to extract backend error msg if present
      String backendMsg = "Request failed 😵‍💫";
      final data = ex.response?.data;
      if (data is Map) {
        backendMsg = (data['error']?.toString() ??
                data['message']?.toString() ??
                backendMsg)
            .trim();
      }

      emit(state.copyWith(
        isSending: false,
        messages: [
          ...baseMessages,
          AiMessage(
            role: AiMessageRole.assistant,
            text: isTimeout
                ? "Server took too long ⏳. Please try again."
                : "Error: $backendMsg",
            at: DateTime.now(),
          ),
        ],
      ));
    } catch (_) {
      emit(state.copyWith(
        isSending: false,
        messages: [
          ...baseMessages,
          AiMessage(
            role: AiMessageRole.assistant,
            text: "Something broke. Try again 😅",
            at: DateTime.now(),
          ),
        ],
      ));
    }
  }
}