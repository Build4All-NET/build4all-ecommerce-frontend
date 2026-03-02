import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/list_home_banners_admin.dart';
import '../../domain/usecases/create_home_banner.dart';
import '../../domain/usecases/update_home_banner.dart';
import '../../domain/usecases/delete_home_banner.dart';
import 'home_banners_event.dart';
import 'home_banners_state.dart';

class HomeBannersBloc extends Bloc<HomeBannersEvent, HomeBannersState> {
  final ListHomeBannersAdmin listAdmin;
  final CreateHomeBanner create;
  final UpdateHomeBanner update;
  final DeleteHomeBanner delete;

  HomeBannersBloc({
    required this.listAdmin,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(const HomeBannersState()) {
    on<LoadAdminBanners>(_onLoad);
    on<CreateBannerEvent>(_onCreate);
    on<UpdateBannerEvent>(_onUpdate);
    on<DeleteBannerEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadAdminBanners e,
    Emitter<HomeBannersState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final list = await listAdmin(token: e.token);
      emit(state.copyWith(loading: false, banners: list));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onCreate(
    CreateBannerEvent e,
    Emitter<HomeBannersState> emit,
  ) async {
    try {
      await create(body: e.body, token: e.token, imagePath: e.imagePath);
      add(LoadAdminBanners(token: e.token));
    } catch (err) {
      emit(state.copyWith(error: err.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateBannerEvent e,
    Emitter<HomeBannersState> emit,
  ) async {
    try {
      await update(
        id: e.id,
        body: e.body,
        token: e.token,
        imagePath: e.imagePath,
      );
      add(LoadAdminBanners(token: e.token));
    } catch (err) {
      emit(state.copyWith(error: err.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteBannerEvent e,
    Emitter<HomeBannersState> emit,
  ) async {
    try {
      await delete(id: e.id, token: e.token);
      add(LoadAdminBanners(token: e.token));
    } catch (err) {
      emit(state.copyWith(error: err.toString()));
    }
  }
}