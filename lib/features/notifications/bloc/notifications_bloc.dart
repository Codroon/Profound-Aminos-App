import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/app_notification.dart';
import '../services/notification_storage_service.dart';

// States
abstract class NotificationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationsLoaded({required this.notifications})
      : unreadCount = notifications.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationsError extends NotificationsState {
  final String message;

  NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Events
abstract class NotificationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {}

class AddNotification extends NotificationsEvent {
  final AppNotification notification;
  AddNotification(this.notification);
  @override
  List<Object?> get props => [notification];
}

class MarkNotificationAsRead extends NotificationsEvent {
  final String id;
  MarkNotificationAsRead(this.id);
  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsAsRead extends NotificationsEvent {}

class DeleteNotification extends NotificationsEvent {
  final String id;
  DeleteNotification(this.id);
  @override
  List<Object?> get props => [id];
}

// Bloc
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationStorageService _storageService;

  NotificationsBloc(this._storageService) : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<AddNotification>(_onAddNotification);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
  }

  Future<void> _onLoadNotifications(
      LoadNotifications event, Emitter<NotificationsState> emit) async {
    emit(NotificationsLoading());
    try {
      final notifications = await _storageService.getNotifications();
      emit(NotificationsLoaded(notifications: notifications));
    } catch (e) {
      emit(NotificationsError('Failed to load notifications: $e'));
    }
  }

  Future<void> _onAddNotification(
      AddNotification event, Emitter<NotificationsState> emit) async {
    try {
      await _storageService.saveNotification(event.notification);
      final notifications = await _storageService.getNotifications();
      emit(NotificationsLoaded(notifications: notifications));
    } catch (e) {
      // Avoid emitting error on add to not disrupt UI
    }
  }

  Future<void> _onMarkNotificationAsRead(
      MarkNotificationAsRead event, Emitter<NotificationsState> emit) async {
    try {
      await _storageService.markAsRead(event.id);
      final notifications = await _storageService.getNotifications();
      emit(NotificationsLoaded(notifications: notifications));
    } catch (e) {
      // 
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
      MarkAllNotificationsAsRead event, Emitter<NotificationsState> emit) async {
    try {
      await _storageService.markAllAsRead();
      final notifications = await _storageService.getNotifications();
      emit(NotificationsLoaded(notifications: notifications));
    } catch (e) {
      //
    }
  }

  Future<void> _onDeleteNotification(
      DeleteNotification event, Emitter<NotificationsState> emit) async {
    try {
      await _storageService.deleteNotification(event.id);
      final notifications = await _storageService.getNotifications();
      emit(NotificationsLoaded(notifications: notifications));
    } catch (e) {
      //
    }
  }
}
