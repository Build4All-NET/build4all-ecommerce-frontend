// lib/features/notifications/presentation/bloc/notifications_bloc.dart

import 'package:bloc/bloc.dart';

import '../../../../core/exceptions/exception_mapper.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/delete_notification.dart';
import '../../domain/usecases/get_unread_count.dart';
import '../../domain/usecases/get_user_notifications.dart';
import '../../domain/usecases/mark_notification_read.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetUserNotifications getNotifications;
  final GetUnreadCount getUnreadCount;
  final MarkNotificationRead markRead;
  final DeleteNotification deleteNotif;

  NotificationsBloc({
    required this.getNotifications,
    required this.getUnreadCount,
    required this.markRead,
    required this.deleteNotif,
  }) : super(NotificationsState.initial()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsRefreshRequested>(_onRefresh);
    on<NotificationReadRequested>(_onRead);
    on<NotificationDeleteRequested>(_onDelete);
  }

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    await _load(emit, showLoader: !state.hasLoaded);
  }

  Future<void> _onRefresh(
    NotificationsRefreshRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _load(emit, showLoader: false);
  }

  Future<void> _load(
    Emitter<NotificationsState> emit, {
    required bool showLoader,
  }) async {
    try {
      if (showLoader) {
        emit(
          state.copyWith(
            isLoading: true,
            clearError: true,
            clearLastAction: true,
          ),
        );
      } else {
        emit(state.copyWith(clearError: true, clearLastAction: true));
      }

      final items = await getNotifications();
      final unread = await getUnreadCount();

      emit(
        state.copyWith(
          isLoading: false,
          hasLoaded: true,
          items: items,
          unreadCount: unread,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          hasLoaded: true,
          error: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }

  Future<void> _onRead(
    NotificationReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final List<AppNotification> before = state.items;
    final idx = before.indexWhere((n) => n.id == event.id);
    if (idx == -1) return;

    final target = before[idx];
    if (target.isRead) return;

    final updated = [...before];
    updated[idx] = target.copyWith(isRead: true);

    final nextUnread = (state.unreadCount - 1).clamp(0, 999999);

    emit(
      state.copyWith(
        items: updated,
        unreadCount: nextUnread,
      ),
    );

    try {
      await markRead(event.id);
    } catch (e) {
      emit(
        state.copyWith(
          items: before,
          unreadCount: state.unreadCount,
          lastActionMessage: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }

  Future<void> _onDelete(
    NotificationDeleteRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final List<AppNotification> before = state.items;
    final idx = before.indexWhere((n) => n.id == event.id);
    if (idx == -1) return;

    final wasUnread = !before[idx].isRead;
    final updated = before.where((n) => n.id != event.id).toList();

    emit(
      state.copyWith(
        items: updated,
        unreadCount: wasUnread
            ? (state.unreadCount - 1).clamp(0, 999999)
            : state.unreadCount,
      ),
    );

    try {
      await deleteNotif(event.id);
    } catch (e) {
      emit(
        state.copyWith(
          items: before,
          unreadCount: state.unreadCount,
          lastActionMessage: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }
}