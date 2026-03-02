// lib/features/ai_feature/data/repositories/ai_chat_repository_impl.dart
import '../../domain/repositories/ai_chat_repository.dart';
import '../models/ai_item_chat_request_model.dart';
import '../services/ai_chat_remote_datasource.dart';

class AiChatRepositoryImpl implements AiChatRepository {
  final AiChatRemoteDataSource remote;
  AiChatRepositoryImpl(this.remote);

  @override
  Future<String> chatItem({
    required String token,
    required int itemId,
    required String message,
  }) async {
    final res = await remote.chatItem(
      token: token,
      body: AiItemChatRequestModel(itemId: itemId, message: message),
    );
    return res.answer;
  }
}