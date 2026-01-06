// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider para obtener las preferencias de notificación del usuario actual

@ProviderFor(notificationPreferences)
final notificationPreferencesProvider = NotificationPreferencesProvider._();

/// Provider para obtener las preferencias de notificación del usuario actual

final class NotificationPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationPreference?>,
          NotificationPreference?,
          FutureOr<NotificationPreference?>
        >
    with
        $FutureModifier<NotificationPreference?>,
        $FutureProvider<NotificationPreference?> {
  /// Provider para obtener las preferencias de notificación del usuario actual
  NotificationPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<NotificationPreference?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotificationPreference?> create(Ref ref) {
    return notificationPreferences(ref);
  }
}

String _$notificationPreferencesHash() =>
    r'a607244f56cf374eb06ceab59dcef99289cac325';

/// Notifier para actualizar preferencias de notificación

@ProviderFor(UserNotificationPreferences)
final userNotificationPreferencesProvider =
    UserNotificationPreferencesProvider._();

/// Notifier para actualizar preferencias de notificación
final class UserNotificationPreferencesProvider
    extends
        $AsyncNotifierProvider<
          UserNotificationPreferences,
          NotificationPreference?
        > {
  /// Notifier para actualizar preferencias de notificación
  UserNotificationPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userNotificationPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userNotificationPreferencesHash();

  @$internal
  @override
  UserNotificationPreferences create() => UserNotificationPreferences();
}

String _$userNotificationPreferencesHash() =>
    r'b21955d955e1c997deb5cfc047599c027d73cc7d';

/// Notifier para actualizar preferencias de notificación

abstract class _$UserNotificationPreferences
    extends $AsyncNotifier<NotificationPreference?> {
  FutureOr<NotificationPreference?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<NotificationPreference?>,
              NotificationPreference?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<NotificationPreference?>,
                NotificationPreference?
              >,
              AsyncValue<NotificationPreference?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
