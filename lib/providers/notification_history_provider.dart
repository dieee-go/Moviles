import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/notification_history_model.dart';
import 'auth_providers.dart';

part 'notification_history_provider.g.dart';

/// Lista paginada de historial de notificaciones
@riverpod
class NotificationHistoryList extends _$NotificationHistoryList {
  static const int _pageSize = 20;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<NotificationHistoryItem>> build() async {
    _hasMore = true;
    _loadingMore = false;
    return _fetchPage(0);
  }

  Future<List<NotificationHistoryItem>> _fetchPage(int offset) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final response = await supabase
        .from('user_notification_history')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .range(offset, offset + _pageSize - 1);

    final list = (response as List)
        .map((item) => NotificationHistoryItem.fromMap(item as Map<String, dynamic>))
        .toList();

    if (list.length < _pageSize) {
      _hasMore = false;
    }
    return list;
  }

  Future<void> refresh() async {
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => _fetchPage(0));
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;

    final current = state.value ?? [];
    final next = await AsyncValue.guard(() async => _fetchPage(current.length));

    next.whenData((items) {
      state = AsyncValue.data([...current, ...items]);
    });

    _loadingMore = false;
  }

  bool get hasMore => _hasMore;
}

/// Provider para marcar notificación como leída
@riverpod
class NotificationHistoryActions extends _$NotificationHistoryActions {
  @override
  FutureOr<void> build() {}

  Future<bool> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('user_notification_history')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);

      // Refrescar el historial
        ref.invalidate(notificationHistoryListProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    try {
      await supabase
          .from('user_notification_history')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id)
          .filter('read_at', 'is', null);

      // Refrescar el historial
        ref.invalidate(notificationHistoryListProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await supabase
          .from('user_notification_history')
          .delete()
          .eq('id', notificationId);

      // Refrescar el historial
        ref.invalidate(notificationHistoryListProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}
