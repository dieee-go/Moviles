import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/firebase/firebase_messaging_service.dart';

part 'auth_providers.g.dart';

/// Provider para obtener la sesión actual del usuario
@riverpod
Stream<AuthState> authSession(Ref ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}

/// Provider para obtener el usuario autenticado actual
@riverpod
User? currentUser(Ref ref) {
  final authState = ref.watch(authSessionProvider);
  return authState.whenData((state) => state.session?.user).value;
}

/// Provider para obtener el ID del usuario autenticado
@riverpod
String? currentUserId(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
}

/// Notifier para manejar la autenticación
@riverpod
class Auth extends _$Auth {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.auth
          .signUp(email: email, password: password);
      
      // Sincronizar token FCM después del registro
      await FirebaseMessagingService().syncToken();
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      
      // Sincronizar token FCM después del login
      await FirebaseMessagingService().syncToken();
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // Eliminar token FCM de Supabase y Firebase
      await FirebaseMessagingService().deleteToken();
      
      // Luego hacer logout de Supabase
      await Supabase.instance.client.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}


