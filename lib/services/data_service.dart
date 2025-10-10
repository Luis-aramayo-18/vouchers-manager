import 'package:intl/intl.dart';
// 1. Alias para la librería principal de Supabase
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;
// 2. Alias para la librería PostgREST (contiene CountMethod)
import 'package:postgrest/postgrest.dart' as postgrest;

// -----------------------------------------------------------------------------
// CLIENTE GLOBAL
// -----------------------------------------------------------------------------
final supabase = supabase_lib.Supabase.instance.client;
const String _tableName = 'vouchers';
const String _amountColumn = 'amount';
const String _dateColumn = 'created_at';
const int _pageSize = 10;

// -----------------------------------------------------------------------------
// CONFIGURACIÓN DE UTILIDADES
// -----------------------------------------------------------------------------

DateFormat getDateFormat(String pattern) {
  return DateFormat(pattern, 'es');
}

NumberFormat getNumberFormat(String pattern) {
  return NumberFormat(pattern, 'es');
}

DateTime _getStartOfMonth(DateTime date) {
  return DateTime(date.year, date.month, 1);
}

DateTime _getEndOfMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
}

// ====================================================================
// FUNCIÓN CENTRAL: Ejecuta la consulta a Supabase
// ====================================================================
Future<List<dynamic>> _executeSupabaseQuery({
  required int from,
  required int to,
  DateTime? dateFilter,
}) async {
  try {
    var query = supabase.from(_tableName).select();

    if (dateFilter != null) {
      final DateTime startOfDay = DateTime(dateFilter.year, dateFilter.month, dateFilter.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      query = query
          .gte(_dateColumn, startOfDay.toIso8601String())
          .lt(_dateColumn, endOfDay.toIso8601String());
    }

    final data = await query.order(_dateColumn, ascending: false).range(from, to);

    return data as List<dynamic>;
  } on postgrest.PostgrestException catch (e) {
    // Usamos el alias 'postgrest'
    print('--- ERROR SUPABASE POSTGREST ---');
    print('Mensaje: ${e.message}');
    print('Detalles: ${e.details}');
    print('---------------------------------');
    throw Exception('Error PostgREST: ${e.message}');
  } catch (e) {
    print('Error inesperado al ejecutar consulta: $e');
    throw Exception('Error inesperado: $e');
  }
}

/// Función principal utilizada para cargar datos con paginación y filtro opcional.
Future<List<dynamic>> loadReceiptsData({
  int from = 0,
  int to = _pageSize - 1,
  DateTime? dateFilter,
}) {
  return _executeSupabaseQuery(from: from, to: to, dateFilter: dateFilter);
}

/// Función que calcula la suma total y la cantidad de comprobantes para un mes específico.
Future<Map<String, dynamic>> calculateMonthlyTotal(DateTime date) async {
  final startOfMonth = _getStartOfMonth(date);
  final endOfMonth = _getEndOfMonth(date);

  try {
    final totalQuery = await supabase
        .from(_tableName)
        .select(_amountColumn)
        .gte(_dateColumn, startOfMonth.toIso8601String())
        .lte(_dateColumn, endOfMonth.toIso8601String());
    // ✅ LÍNEA CLAVE: Usamos el alias 'postgrest' con CountMethod.

    final List<dynamic> data = totalQuery as List<dynamic>;
    final int receiptCount = data.length;

    double totalAmount = data.fold<double>(0.0, (sum, item) {
      return sum + (item[_amountColumn] as num).toDouble();
    });

    return {'total_amount': totalAmount, 'receipt_count': receiptCount};
  } on postgrest.PostgrestException catch (e) {
    throw Exception('Error PostgREST al calcular totales: ${e.message}');
  } catch (e) {
    throw Exception('Error desconocido al calcular totales: $e');
  }
}
