import 'package:supabase_flutter/supabase_flutter.dart';

class FcmTokenService {
  FcmTokenService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Guarda o actualiza el token FCM del usuario en Supabase
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    if (token.isEmpty) return;

    final payload = {
      'user_id': userId,
      'token': token,
      'platform': platform,
      'device_id': deviceId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client
        .from('fcm_tokens')
        .upsert(payload, onConflict: 'user_id,token')
        .select();
  }
}
