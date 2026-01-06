// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lista paginada de historial de notificaciones

@ProviderFor(NotificationHistoryList)
final notificationHistoryListProvider = NotificationHistoryListProvider._();

/// Lista paginada de historial de notificaciones
final class NotificationHistoryListProvider
    extends
        $AsyncNotifierProvider<
          NotificationHistoryList,
          List<NotificationHistoryItem>
        > {
  /// Lista paginada de historial de notificaciones
  NotificationHistoryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationHistoryListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationHistoryListHash();

  @$internal
  @override
  NotificationHistoryList create() => NotificationHistoryList();
}

String _$notificationHistoryListHash() =>
    r'4250c1fcc5eda1c4e788903418d57f353c628cc8';

/// Lista paginada de historial de notificaciones

abstract class _$NotificationHistoryList
    extends $AsyncNotifier<List<NotificationHistoryItem>> {
  FutureOr<List<NotificationHistoryItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<NotificationHistoryItem>>,
              List<NotificationHistoryItem>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<NotificationHistoryItem>>,
                List<NotificationHistoryItem>
              >,
              AsyncValue<List<NotificationHistoryItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider para marcar notificación como leída

@ProviderFor(NotificationHistoryActions)
final notificationHistoryActionsProvider =
    NotificationHistoryActionsProvider._();

/// Provider para marcar notificación como leída
final class NotificationHistoryActionsProvider
    extends $AsyncNotifierProvider<NotificationHistoryActions, void> {
  /// Provider para marcar notificación como leída
  NotificationHistoryActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationHistoryActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationHistoryActionsHash();

  @$internal
  @override
  NotificationHistoryActions create() => NotificationHistoryActions();
}

String _$notificationHistoryActionsHash() =>
    r'4b954451c2568ca833a62c445ddd0363388b6e19';

/// Provider para marcar notificación como leída

abstract class _$NotificationHistoryActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
