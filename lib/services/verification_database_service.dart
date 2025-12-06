import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';

const String kVerifiedPaymentsTable = 'vouchers';
const String kMpAccountsTable = 'mp_accounts';

class VerificationDatabaseService {
  final SupabaseClient _supabase;

  VerificationDatabaseService() : _supabase = Supabase.instance.client;

  // ------------------------------------------------------------------
  // 🔑 NUEVO MÉTODO: Obtener todos los detalles de la cuenta MP (incluyendo refresh y expiración)
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchMpAccountDetails(String userId) async {
    try {
      final response = await _supabase
          .from(kMpAccountsTable)
          .select('access_token, refresh_token, expires_at')
          .eq('user_id', userId)
          .maybeSingle();

      // Si no hay datos, o los datos son nulos, devolvemos null
      if (response == null || response.isEmpty) {
        return null;
      }
          
      // Comprobación básica de tipos antes de devolver
      if (response['access_token'] is String && 
          response['refresh_token'] is String && 
          response['expires_at'] is String) {
        return response;
      }

      // Si falta alguno de los campos críticos, devolvemos null
      return null;

    } on PostgrestException catch (e) {
      log('Supabase Error al buscar detalles de MP para $userId: ${e.message}');
      return null;
    } catch (e) {
      log('Excepción al buscar detalles de MP para $userId: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // 🔄 NUEVO MÉTODO: Actualizar los tokens de MP después de un refresco (¡Añadido onConflict!)
  // ------------------------------------------------------------------
  Future<bool> updateMpTokens({
    required String userId,
    required String accessToken,
    required String refreshToken,
    required String expiresAt,
  }) async {
    try {
      final dataToUpdate = {
          'user_id': userId, 
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt,
        'status': 'ACTIVE',
      };

      // >>> CAMBIO CRÍTICO: Añadimos onConflict: 'user_id'
      // Esto le dice a Supabase que si detecta un 'user_id' duplicado,
      // debe actualizar la fila existente en lugar de intentar insertar una nueva.
      await _supabase
          .from(kMpAccountsTable)
          .upsert(dataToUpdate, onConflict: 'user_id');

      return true;
    } on PostgrestException catch (e) {
      // Log mejorado para hacer visible el error de Postgrest
      log('🔴 Supabase Error CRÍTICO al actualizar/insertar tokens para $userId: ${e.message}');
      return false;
    } catch (e) {
      // Log mejorado para hacer visible cualquier otra excepción
      log('🔴 Excepción CRÍTICA al actualizar/insertar tokens para $userId: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // FUNCIÓN DE CONVENIENCIA: Usada por el servicio antiguo, ahora llama a fetchMpAccountDetails
  // ------------------------------------------------------------------
  Future<String?> fetchMpAccessToken(String userId) async {
    // Esta función ahora es solo un wrapper que llama al método más completo.
    final details = await fetchMpAccountDetails(userId);
    return details?['access_token'] as String?;
  }

  // ------------------------------------------------------------------
  // FUNCIÓN EXISTENTE: Verifica si la transacción ya fue registrada
  // ------------------------------------------------------------------
  Future<bool> checkIfTransactionExists(String transactionId) async {
    try {
      final response = await _supabase
          .from(kVerifiedPaymentsTable)
          .select('mp_transaction_id')
          .eq('mp_transaction_id', transactionId)
          .limit(1);

      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      log('Supabase Error al verificar duplicado en DB: ${e.message}');
      return false;
    } catch (e) {
      log('Excepción al verificar duplicado en DB: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // FUNCIÓN EXISTENTE: Guarda el registro de la verificación exitosa
  // ------------------------------------------------------------------
  Future<String> saveVerification(Map<String, dynamic> details, {required String userId}) async {
    final String transactionId = details['extracted_transaction_id'];

    if (transactionId == 'N/A') {
      return 'Error: No se puede guardar, la transacción no tiene un ID de Mercado Pago válido.';
    }

    try {
      final String recipientCuil =
          details['collector']?['identification']?['number'] ?? 'CUIL_Desconocido';

      if (userId.isEmpty || userId == '00000000-0000-0000-0000-000000000000') {
        return '❌ Error de Autenticación: El ID de usuario no es válido para guardar.';
      }

      final dataToInsert = {
        'mp_transaction_id': transactionId,
        'sender_cuil': details['extracted_client_cuil'],
        'sender_name': details['extracted_client_name'] ?? 'Desconocido',
        'amount': details['extracted_amount'],
        'date_approved_local': details['extracted_datetime_iso'], 
        'source_bank': details['extracted_source_bank'],
        'recipient_cuil': recipientCuil,
        'user_id': userId, 
        'full_data': details,
      };

      print(dataToInsert);

      await _supabase.from(kVerifiedPaymentsTable).insert(dataToInsert);

      return '✅ Verificación guardada con éxito (ID: $transactionId).';
    } on PostgrestException catch (e) {
      print('Supabase Error al guardar: ${e.message}');
      if (e.message.contains('duplicate key value')) {
        return '⚠️ Error: Intento de duplicado de ID de transacción. El ID $transactionId ya existe.';
      }
      return '❌ Error al guardar en la base de datos: ${e.message}';
    } catch (e) {
      log('Excepción al guardar: $e');
      return '❌ Ocurrió un error inesperado al guardar.';
    }
  }
}
