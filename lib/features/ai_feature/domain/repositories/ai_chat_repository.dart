// lib/features/ai_feature/domain/repositories/ai_chat_repository.dart
abstract class AiChatRepository {
  Future<String> chatItem({
    required String token,
    required int itemId,
    required String message,
  });
}