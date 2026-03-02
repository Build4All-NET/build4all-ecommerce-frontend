import 'package:build4front/core/network/globals.dart' as authState;

import 'package:build4front/features/catalog/data/models/item_type_model.dart';
import 'package:build4front/features/catalog/data/services/item_type_api_service.dart';
import 'package:build4front/features/catalog/domain/entities/item_type.dart';
import 'package:build4front/features/catalog/domain/repositories/item_type_repository.dart';

class ItemTypeRepositoryImpl implements ItemTypeRepository {
  final ItemTypeApiService api;

  ItemTypeRepositoryImpl({required this.api});

  String _requireToken() {
    final t = (authState.token ?? '').trim();
    if (t.isEmpty) {
      throw Exception('Missing auth token');
    }
    return t;
  }

  @override
  Future<List<ItemType>> getByProject(int projectId) async {
    final token = _requireToken();

    final list = await api.getItemTypesByProject(
      projectId,
      authToken: token,
    );

    return list.map((m) => ItemTypeModel.fromJson(m).toEntity()).toList();
  }

  @override
  Future<List<ItemType>> getByCategory(int categoryId) async {
    final token = _requireToken();

    final list = await api.getItemTypesByCategory(
      categoryId,
      authToken: token,
    );

    return list.map((m) => ItemTypeModel.fromJson(m).toEntity()).toList();
  }

  // Optional CRUD if you need it later:
  // create/update/delete also must pass authToken.
}