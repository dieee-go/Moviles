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

  /// Guarda los intereses seleccionados para un usuario
  Future<void> saveUserInterests(
    String userId,
    List<String> selectedInterestIds,
  ) async {
    try {
      if (selectedInterestIds.isEmpty) return;

      final rows = selectedInterestIds
          .map((id) => {
                'user_id': userId,
                'interest_id': id,
              })
          .toList();

      await _supabase
          .from('user_interests')
          .upsert(rows, onConflict: 'user_id,interest_id');
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
