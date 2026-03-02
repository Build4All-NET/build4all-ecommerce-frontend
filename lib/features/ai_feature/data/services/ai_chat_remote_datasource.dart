// lib/features/ai_feature/data/services/ai_chat_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;

import '../models/ai_item_chat_request_model.dart';
import '../models/ai_chat_response_model.dart';

class AiChatRemoteDataSource {
  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  Future<AiChatResponseModel> chatItem({
    required String token,
    required AiItemChatRequestModel body,
  }) async {
    final Dio dio = g.dio();

    final res = await dio.post(
      '/api/ai/item-chat',
      data: body.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer ${_cleanToken(token)}'},
      ),
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return AiChatResponseModel.fromJson(data);
    }
    return AiChatResponseModel(answer: data?.toString() ?? '');
  }
}