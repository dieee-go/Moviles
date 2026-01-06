// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider para el servicio de Firebase Messaging (singleton)

@ProviderFor(firebaseMessagingService)
final firebaseMessagingServiceProvider = FirebaseMessagingServiceProvider._();

/// Provider para el servicio de Firebase Messaging (singleton)

final class FirebaseMessagingServiceProvider
    extends
        $FunctionalProvider<
          FirebaseMessagingService,
          FirebaseMessagingService,
          FirebaseMessagingService
        >
    with $Provider<FirebaseMessagingService> {
  /// Provider para el servicio de Firebase Messaging (singleton)
  FirebaseMessagingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseMessagingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseMessagingServiceHash();

  @$internal
  @override
  $ProviderElement<FirebaseMessagingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseMessagingService create(Ref ref) {
    return firebaseMessagingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseMessagingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseMessagingService>(value),
    );
  }
}

String _$firebaseMessagingServiceHash() =>
    r'bbeb89798816882e110210be7bcf88c4005ed765';

/// Provider para el FCM token del usuario

@ProviderFor(fcmToken)
final fcmTokenProvider = FcmTokenProvider._();

/// Provider para el FCM token del usuario

final class FcmTokenProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provider para el FCM token del usuario
  FcmTokenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fcmTokenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fcmTokenHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return fcmToken(ref);
  }
}

String _$fcmTokenHash() => r'a5f2f0d70c99b6a8b4cbe284a025864d12a4e018';

/// Notifier para gestionar preferencias de notificaciones del usuario (DEPRECADO - usar notification_preferences_provider)

@ProviderFor(NotificationPreferencesLegacy)
final notificationPreferencesLegacyProvider =
    NotificationPreferencesLegacyProvider._();

/// Notifier para gestionar preferencias de notificaciones del usuario (DEPRECADO - usar notification_preferences_provider)
final class NotificationPreferencesLegacyProvider
    extends
        $NotifierProvider<
          NotificationPreferencesLegacy,
          NotificationPreference?
        > {
  /// Notifier para gestionar preferencias de notificaciones del usuario (DEPRECADO - usar notification_preferences_provider)
  NotificationPreferencesLegacyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPreferencesLegacyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPreferencesLegacyHash();

  @$internal
  @override
  NotificationPreferencesLegacy create() => NotificationPreferencesLegacy();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationPreference? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationPreference?>(value),
    );
  }
}

String _$notificationPreferencesLegacyHash() =>
    r'897c4bd5d712b88f66c1bc9f6427cdb7ba6cc065';

/// Notifier para gestionar preferencias de notificaciones del usuario (DEPRECADO - usar notification_preferences_provider)

abstract class _$NotificationPreferencesLegacy
    extends $Notifier<NotificationPreference?> {
  NotificationPreference? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<NotificationPreference?, NotificationPreference?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotificationPreference?, NotificationPreference?>,
              NotificationPreference?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Notifier para gestionar el historial de notificaciones

@ProviderFor(NotificationsHistory)
final notificationsHistoryProvider = NotificationsHistoryProvider._();

/// Notifier para gestionar el historial de notificaciones
final class NotificationsHistoryProvider
    extends $NotifierProvider<NotificationsHistory, List<PushNotification>> {
  /// Notifier para gestionar el historial de notificaciones
  NotificationsHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsHistoryHash();

  @$internal
  @override
  NotificationsHistory create() => NotificationsHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PushNotification> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PushNotification>>(value),
    );
  }
}

String _$notificationsHistoryHash() =>
    r'd27c586911e70cd7f4852ae97d485001ec97951f';

/// Notifier para gestionar el historial de notificaciones

abstract class _$NotificationsHistory
    extends $Notifier<List<PushNotification>> {
  List<PushNotification> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<PushNotification>, List<PushNotification>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PushNotification>, List<PushNotification>>,
              List<PushNotification>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider para obtener el conteo de notificaciones no leídas

@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = UnreadNotificationCountProvider._();

/// Provider para obtener el conteo de notificaciones no leídas

final class UnreadNotificationCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Provider para obtener el conteo de notificaciones no leídas
  UnreadNotificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unreadNotificationCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$unreadNotificationCountHash() =>
    r'b0c2bdd30101d071651da9421254d0e4401c1ef7';

/// Provider para obtener notificaciones por categoría

@ProviderFor(notificationsByCategory)
final notificationsByCategoryProvider = NotificationsByCategoryFamily._();

/// Provider para obtener notificaciones por categoría

final class NotificationsByCategoryProvider
    extends
        $FunctionalProvider<
          List<PushNotification>,
          List<PushNotification>,
          List<PushNotification>
        >
    with $Provider<List<PushNotification>> {
  /// Provider para obtener notificaciones por categoría
  NotificationsByCategoryProvider._({
    required NotificationsByCategoryFamily super.from,
    required NotificationCategory super.argument,
  }) : super(
         retry: null,
         name: r'notificationsByCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notificationsByCategoryHash();

  @override
  String toString() {
    return r'notificationsByCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<PushNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<PushNotification> create(Ref ref) {
    final argument = this.argument as NotificationCategory;
    return notificationsByCategory(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PushNotification> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PushNotification>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationsByCategoryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notificationsByCategoryHash() =>
    r'd304d24462ead3a5fdc6085ba733fb6b0013d9aa';

/// Provider para obtener notificaciones por categoría

final class NotificationsByCategoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          List<PushNotification>,
          NotificationCategory
        > {
  NotificationsByCategoryFamily._()
    : super(
        retry: null,
        name: r'notificationsByCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider para obtener notificaciones por categoría

  NotificationsByCategoryProvider call(NotificationCategory category) =>
      NotificationsByCategoryProvider._(argument: category, from: this);

  @override
  String toString() => r'notificationsByCategoryProvider';
}

/// Provider para obtener notificaciones no leídas

@ProviderFor(unreadNotifications)
final unreadNotificationsProvider = UnreadNotificationsProvider._();

/// Provider para obtener notificaciones no leídas

final class UnreadNotificationsProvider
    extends
        $FunctionalProvider<
          List<PushNotification>,
          List<PushNotification>,
          List<PushNotification>
        >
    with $Provider<List<PushNotification>> {
  /// Provider para obtener notificaciones no leídas
  UnreadNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationsHash();

  @$internal
  @override
  $ProviderElement<List<PushNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<PushNotification> create(Ref ref) {
    return unreadNotifications(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PushNotification> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PushNotification>>(value),
    );
  }
}

String _$unreadNotificationsHash() =>
    r'25cc875ed729f8b58bc8a03d0f1b7b11e1330f17';
