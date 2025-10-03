import 'package:supabase_flutter/supabase_flutter.dart';

const String kVerifiedPaymentsTable = 'vouchers';

class VerificationDatabaseService {
  final SupabaseClient _supabase;

  VerificationDatabaseService() : _supabase = Supabase.instance.client;

  Future<String> saveVerification(Map<String, dynamic> details) async {
    final String transactionId = details['extracted_transaction_id'];

    if (transactionId == 'N/A') {
      return 'Error: No se puede guardar, la transacción no tiene un ID de Mercado Pago válido.';
    }

    try {
      final response = await _supabase
          .from(kVerifiedPaymentsTable)
          .select('mp_transaction_id')
          .eq('mp_transaction_id', transactionId);

      if (response.isNotEmpty) {
        return '⚠️ Esta verificación (ID: $transactionId) ya fue guardada previamente.';
      }

      final String recipientCuil =
          details['collector']?['identification']?['number'] ??
          'CUIL_Desconocido';

      final dataToInsert = {
        'mp_transaction_id': transactionId,
        'sender_cuil': details['extracted_client_cuil'],
        'sender_name': details['extracted_client_name'] ?? 'Desconocido',
        'amount': details['extracted_amount'],
        'date_approved_local':
            '${details['extracted_date']} ${details['extracted_time']}',
        'source_bank': details['extracted_source_bank'],
        'recipient_cuil': recipientCuil,
        'full_data': details,
      };

      await _supabase.from(kVerifiedPaymentsTable).insert(dataToInsert);

      return '✅ Verificación guardada con éxito (ID: $transactionId).';
    } on PostgrestException catch (e) {
      print('Supabase Error: ${e.message}');
      if (e.message.contains('duplicate key value')) {
        return '⚠️ Error: Intento de duplicado de ID de transacción. El ID $transactionId ya existe.';
      }
      return '❌ Error al guardar en la base de datos: ${e.message}';
    } catch (e) {
      print('Excepción al guardar: $e');
      return '❌ Ocurrió un error inesperado al guardar.';
    }
  }
}
