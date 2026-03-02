// lib/features/ai_feature/domain/usecases/chat_item_usecase.dart
import '../repositories/ai_chat_repository.dart';

class ChatItemUseCase {
  final AiChatRepository repo;
  ChatItemUseCase(this.repo);

  Future<String> call({
    required String token,
    required int itemId,
    required String message,
  }) {
    return repo.chatItem(
      token: token,
      itemId: itemId,
      message: message,
    );
  }
}