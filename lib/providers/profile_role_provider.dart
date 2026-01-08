import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_providers.dart';

final profileRoleProvider = FutureProvider<String?>((ref) async {
  var user = ref.watch(currentUserProvider);
  if (user == null) {
    final authState = await ref.watch(authSessionProvider.future);
    user = authState.session?.user;
    if (user == null) return null;
  }

  final data = await Supabase.instance.client
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();

  return data == null ? null : data['role'] as String?;
});
