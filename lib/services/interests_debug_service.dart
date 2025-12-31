import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterestsDebugService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene información de depuración sobre la tabla interests
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      // 1. Verificar si la tabla existe y obtener datos
      final data = await _supabase.from('interests').select('*');
      
      if (kDebugMode) {
        debugPrint('=== INTERESES DEBUG INFO ===');
        debugPrint('Número de intereses: ${data.length}');
        debugPrint('Datos crudos: $data');
        
        if (data.isNotEmpty) {
          debugPrint('Primer registro: ${data[0]}');
          debugPrint('Campos disponibles: ${data[0].keys.toList()}');
        }
      }

      return {
        'success': true,
        'count': data.length,
        'data': data,
        'isEmpty': data.isEmpty,
        'fields': data.isNotEmpty ? data[0].keys.toList() : [],
      };
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('Error Postgrest: ${e.message}');
        debugPrint('Status: ${e.code}');
      }
      return {
        'success': false,
        'error': 'Error Postgrest: ${e.message}',
        'code': e.code,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error general: $e');
      }
      return {
        'success': false,
        'error': 'Error general: $e',
      };
    }
  }

  /// Verifica la conexión a Supabase
  Future<bool> checkConnection() async {
    try {
      // Solo verificamos que la consulta responda
      await _supabase.from('interests').select('id').limit(1);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error de conexión: $e');
      }
      return false;
    }
  }

  /// Obtiene información sobre la estructura de la tabla
  Future<Map<String, dynamic>> getTableInfo() async {
    try {
      final data = await _supabase.from('interests').select('*').limit(1);
      
      if (data.isNotEmpty) {
        final firstRecord = data.first;
        return {
          'fields': firstRecord.keys.toList(),
          'structure': firstRecord.entries.map((e) {
            return {
              'name': e.key,
              'value': e.value,
              'type': e.value?.runtimeType.toString() ?? 'null',
            };
          }).toList(),
        };
      }
      return {'error': 'Tabla vacía'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
