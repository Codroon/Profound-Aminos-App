import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/app_notification.dart';
import '../repository/notification_repository.dart';

// ── States ───────────────────────────────────────────────────────────────────
abstract class NotificationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;

  /// Global unread count (notifications newer than the read watermark), not the
  /// length of the loaded page.
  final int unreadCount;

  final bool hasMore;
  final bool isLoadingMore;

  /// Active date-range filter, if any.
  final DateTime? dateFrom;
  final DateTime? dateTo;

  NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.dateFrom,
    this.dateTo,
  });

  bool get hasDateFilter => dateFrom != null || dateTo != null;

  NotificationsLoaded copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  @override
  List<Object?> get props =>
      [notifications, unreadCount, hasMore, isLoadingMore, dateFrom, dateTo];
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Events ───────────────────────────────────────────────────────────────────
abstract class NotificationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// (Re)load the first page, preserving any active date filter.
class LoadNotifications extends NotificationsEvent {}

/// Fetch the next page (infinite scroll).
class LoadMoreNotifications extends NotificationsEvent {}

/// Apply a date-range filter and reload from the first page.
/// [to] is treated as inclusive of the whole day by the caller.
class FilterNotificationsByDate extends NotificationsEvent {
  final DateTime? from;
  final DateTime? to;
  FilterNotificationsByDate({this.from, this.to});
  @override
  List<Object?> get props => [from, to];
}

/// Clear any date filter and reload.
class ClearNotificationDateFilter extends NotificationsEvent {}

/// Optimistically mark one notification read on this device (local only).
class MarkNotificationAsRead extends NotificationsEvent {
  final String id;
  MarkNotificationAsRead(this.id);
  @override
  List<Object?> get props => [id];
}

/// Advance the read watermark to now (single write, syncs across devices).
class MarkAllNotificationsAsRead extends NotificationsEvent {}

/// Delete a notification from the shared history.
class DeleteNotification extends NotificationsEvent {
  final String id;
  DeleteNotification(this.id);
  @override
  List<Object?> get props => [id];
}

// ── Bloc ─────────────────────────────────────────────────────────────────────
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _repository;

  // Pagination cursor + active filter.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  DateTime? _from;
  DateTime? _to;

  // Read state: chronological watermark + optimistic per-device reads.
  DateTime? _lastReadAt;
  final Set<String> _locallyRead = {};

  NotificationsBloc(this._repository) : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoad);
    on<LoadMoreNotifications>(_onLoadMore);
    on<FilterNotificationsByDate>(_onFilterByDate);
    on<ClearNotificationDateFilter>(_onClearFilter);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDelete);
  }

  Future<void> _onLoad(
      LoadNotifications event, Emitter<NotificationsState> emit) async {
    // Keep the current list visible during a silent refresh; only show the
    // full spinner on the very first load.
    if (state is! NotificationsLoaded) emit(NotificationsLoading());
    try {
      _lastDoc = null;
      _lastReadAt = await _repository.getLastReadAt();
      final page = await _repository.fetchPage(
        from: _from,
        to: _to,
        lastReadAt: _lastReadAt,
        locallyRead: _locallyRead,
      );
      _lastDoc = page.lastDoc;
      final unread = await _repository.unreadCount(_lastReadAt);
      emit(NotificationsLoaded(
        notifications: page.items,
        unreadCount: unread,
        hasMore: page.hasMore,
        dateFrom: _from,
        dateTo: _to,
      ));
    } catch (e) {
      emit(NotificationsError('Failed to load notifications: $e'));
    }
  }

  Future<void> _onLoadMore(
      LoadMoreNotifications event, Emitter<NotificationsState> emit) async {
    final current = state;
    if (current is! NotificationsLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.fetchPage(
        from: _from,
        to: _to,
        startAfter: _lastDoc,
        lastReadAt: _lastReadAt,
        locallyRead: _locallyRead,
      );
      _lastDoc = page.lastDoc;
      emit(current.copyWith(
        notifications: [...current.notifications, ...page.items],
        hasMore: page.hasMore,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onFilterByDate(
      FilterNotificationsByDate event, Emitter<NotificationsState> emit) async {
    _from = event.from;
    _to = event.to;
    add(LoadNotifications());
  }

  Future<void> _onClearFilter(
      ClearNotificationDateFilter event,
      Emitter<NotificationsState> emit) async {
    _from = null;
    _to = null;
    add(LoadNotifications());
  }

  Future<void> _onMarkAsRead(
      MarkNotificationAsRead event, Emitter<NotificationsState> emit) async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    if (_locallyRead.contains(event.id)) return;
    _locallyRead.add(event.id);
    final updated = current.notifications
        .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
        .toList();
    emit(current.copyWith(
      notifications: updated,
      unreadCount: (current.unreadCount - 1).clamp(0, 1 << 30),
    ));
  }

  Future<void> _onMarkAllAsRead(
      MarkAllNotificationsAsRead event,
      Emitter<NotificationsState> emit) async {
    final current = state;
    try {
      await _repository.markAllRead();
      _lastReadAt = DateTime.now();
      _locallyRead.clear();
      if (current is NotificationsLoaded) {
        emit(current.copyWith(
          notifications:
              current.notifications.map((n) => n.copyWith(isRead: true)).toList(),
          unreadCount: 0,
        ));
      }
    } catch (_) {
      // Leave state as-is on failure.
    }
  }

  Future<void> _onDelete(
      DeleteNotification event, Emitter<NotificationsState> emit) async {
    final current = state;
    try {
      await _repository.delete(event.id);
      if (current is NotificationsLoaded) {
        emit(current.copyWith(
          notifications: current.notifications
              .where((n) => n.id != event.id)
              .toList(),
        ));
      }
    } catch (_) {
      // Ignore delete failures (keeps UI responsive).
    }
  }
}
