import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterestsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Carga todos los intereses de la tabla interests
  Future<List<Map<String, dynamic>>> loadInterests() async {
    try {
        if (kDebugMode) {
          debugPrint('Iniciando carga de intereses...');
        }

        final data = await _supabase
            .from('interests')
            .select('id, name')
            .order('name', ascending: true);
      
        if (kDebugMode) {
          debugPrint('Intereses cargados: ${data.length} registros');
          if (data.isNotEmpty) {
            debugPrint('Primer interés: ${data[0]}');
          }
        }

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
        if (kDebugMode) {
          debugPrint('Error Postgrest al cargar intereses: ${e.message}');
          debugPrint('Código: ${e.code}');
        }
      throw Exception('Error cargando intereses: ${e.message}');
    } catch (e) {
        if (kDebugMode) {
          debugPrint('Error general al cargar intereses: $e');
        }
      throw Exception('Error inesperado cargando intereses: $e');
    }
  }

  /// Experimental: try to perform upsert + selective delete using PostgREST 'in' filter.
  /// This mirrors the previous approach but may be fragile due to PostgREST quoting
  /// rules for UUIDs; kept for testing. Prefer `saveUserInterests` (delete+insert).
  Future<void> saveUserInterestsUsingIn(
    String userId,
    List<String> selectedInterestIds,
  ) async {
    try {
      if (selectedInterestIds.isEmpty) {
        await _supabase.from('user_interests').delete().eq('user_id', userId);
        return;
      }

      final rows = selectedInterestIds
          .map((id) => {
                'user_id': userId,
                'interest_id': id,
              })
          .toList();

      // Upsert selected
      await _supabase
          .from('user_interests')
          .upsert(rows, onConflict: 'user_id,interest_id');

      // Build an 'in' list using double quotes around UUIDs: ("uuid1","uuid2")
      final inList = '(${selectedInterestIds.map((s) => '"${s.replaceAll('"', '\\"')}"').join(',')})';

      // Delete any interests not in the selected set (for this user)
      await _supabase
          .from('user_interests')
          .delete()
          .eq('user_id', userId)
          .not('interest_id', 'in', inList);
    } on PostgrestException catch (e) {
      throw Exception('Error guardando intereses (using in): ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado guardando intereses (using in): $e');
    }
  }

  /// Guarda los intereses seleccionados para un usuario
  Future<void> saveUserInterests(
    String userId,
    List<String> selectedInterestIds,
  ) async {
    try {
      // If nothing selected, remove all interests for the user
      if (selectedInterestIds.isEmpty) {
        await _supabase.from('user_interests').delete().eq('user_id', userId);
        return;
      }

      final rows = selectedInterestIds
          .map((id) => {
                'user_id': userId,
                'interest_id': id,
              })
          .toList();

      // Simpler, robust approach: delete all current interests for the user
      // and insert the selected ones. This avoids complex 'not in' filtering
      // that can lead to malformed input when passing UUID values through
      // PostgREST filters.
      await _supabase.from('user_interests').delete().eq('user_id', userId);

      // Insert selected interests (if any)
      if (rows.isNotEmpty) {
        await _supabase.from('user_interests').insert(rows);
      }
    } on PostgrestException catch (e) {
      throw Exception('Error guardando intereses: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado guardando intereses: $e');
    }
  }

  /// Obtiene los intereses de un usuario
  Future<List<String>> getUserInterests(String userId) async {
    try {
      final data = await _supabase
          .from('user_interests')
          .select('interest_id')
          .eq('user_id', userId);

      return List<String>.from(
        data.map((item) => item['interest_id'].toString()),
      );
    } on PostgrestException catch (e) {
      throw Exception('Error cargando intereses del usuario: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado cargando intereses del usuario: $e');
    }
  }

  /// Extrae el nombre mostrable del interés
  String getDisplayName(Map<String, dynamic> interest) {
    const fields = ['name', 'nombre', 'title', 'descripcion', 'label'];
    for (final field in fields) {
      final value = interest[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return 'Interés';
  }

  /// Extrae el ID del interés de diferentes formatos posibles
  String getInterestId(Map<String, dynamic> interest) {
    return (interest['id'] ??
            interest['uuid'] ??
            interest['interest_id'] ??
            interest['_id'])
        .toString();
  }
}
