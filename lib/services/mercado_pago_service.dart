import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vouchers_manager/services/verification_database_service.dart';

class VerificationResult {
  final bool isVerified;
  final String message;
  final bool isDuplicate;

  final Map<String, dynamic>? paymentDetails;

  VerificationResult({
    required this.isVerified,
    required this.message,
    this.paymentDetails,
    this.isDuplicate = false,
  });
}

class MercadoPagoService {
  static final String _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  static final String _qrFunctionUrl = dotenv.env['SUPABASE_QR_FUNCTION_URL']!;
  static final String _qrFunctionUrl2 = dotenv.env['SUPABASE_QR_FUNCTION_URL_2']!;

  static final String _mpClientId = _getEnvVar('MP_CLIENT_ID');
  static final String _mpClientSecret = _getEnvVar('MP_CLIENT_SECRET');

  static String _getEnvVar(String key) {
    final value = dotenv.env[key];
    if (value == null) {
      debugPrint('🔴 ERROR CRÍTICO DE ENTORNO: Falta la variable de entorno $key.');
      throw StateError('Falta la variable de entorno $key. Verifica tu archivo .env');
    }
    return value;
  }

  static const String _tokenUrl = 'https://api.mercadopago.com/oauth/token';
  static const String _paymentsSearchUrl = 'https://api.mercadopago.com/v1/payments/search';

  final VerificationDatabaseService _dbService;
  MercadoPagoService(this._dbService);

  // ------------------------------------------------------------------
  // 🚀 NUEVA FUNCIÓN: Verificar si la cuenta de MP está vinculada
  // Usada por MpSyncProvider al iniciar.
  // ------------------------------------------------------------------
  Future<bool> isMpAccountLinked(String userId) async {
    try {
      final Map<String, dynamic>? mpData = await _dbService.fetchMpAccountDetails(userId);

      // Una cuenta está vinculada si tenemos los tres tokens esenciales
      final bool isLinked =
          mpData != null &&
          mpData['access_token'] != null &&
          mpData['refresh_token'] != null &&
          mpData['expires_at'] != null;

      if (!isLinked) {
        debugPrint('Estado de vinculación para $userId: Cuenta no vinculada o incompleta.');
      }
      return isLinked;
    } catch (e) {
      debugPrint('Error al verificar el estado de vinculación de MP: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // FUNCIÓN PRIVADA: Refresca el Access Token de MP
  // ------------------------------------------------------------------
  Future<String?> _refreshMpToken(String refreshToken, String userId) async {
    debugPrint('Iniciando refresco de token de Mercado Pago para $userId...');
    try {
      final mpRequestBody = {
        'client_id': _mpClientId,
        'client_secret': _mpClientSecret,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      };

      final mpResponse = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(mpRequestBody),
      );

      final mpData = json.decode(mpResponse.body);

      if (mpResponse.statusCode != 200 || mpData['error'] != null) {
        debugPrint(
          '🔴 FALLO CRÍTICO EN REFRESCO. Estado: ${mpResponse.statusCode}. Mensaje MP: ${mpData['error_description'] ?? mpData['message']}',
        );
        debugPrint('Asegúrate de que MP_CLIENT_ID y MP_CLIENT_SECRET sean correctos.');
        return null;
      }

      final String newAccessToken = mpData['access_token'];
      final String? newRefreshToken = mpData['refresh_token'];
      final int expiresIn = mpData['expires_in'] ?? 21600;

      final DateTime newExpiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresIn));

      final bool updateSuccess = await _dbService.updateMpTokens(
        userId: userId,
        accessToken: newAccessToken,
        refreshToken: newRefreshToken ?? refreshToken,
        expiresAt: newExpiresAt.toIso8601String(),
      );

      if (updateSuccess) {
        debugPrint(
          '✅ Token de Mercado Pago refrescado y guardado exitosamente. Nuevo token válido hasta: ${newExpiresAt.toLocal()}',
        );
        return newAccessToken;
      } else {
        debugPrint('🔴 Token refrescado, pero falló el guardado en la DB.');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 Excepción durante el refresco de token: $e');
      debugPrint('StackTrace refresco: $stackTrace');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // FUNCIÓN PRIVADA: Obtener y Refrescar el Access Token
  // ------------------------------------------------------------------
  Future<String> _getUserMpAccessToken({required String userId}) async {
    try {
      final Map<String, dynamic>? mpData = await _dbService.fetchMpAccountDetails(userId);

      if (mpData == null ||
          mpData['access_token'] == null ||
          mpData['refresh_token'] == null ||
          mpData['expires_at'] == null) {
        debugPrint('🔴 Cuenta MP incompleta o no vinculada para el usuario $userId.');
        throw Exception(
          'Cuenta MP incompleta o no vinculada. Se requiere token, refresh_token y expires_at.',
        );
      }

      final String accessToken = mpData['access_token'] as String;
      final String refreshToken = mpData['refresh_token'] as String;

      final DateTime expiresAt = DateTime.parse(mpData['expires_at']).toUtc();
      final DateTime nowUtc = DateTime.now().toUtc();

      final bool isExpired = expiresAt.subtract(const Duration(minutes: 1)).isBefore(nowUtc);

      debugPrint('--- Estado del Token de MP ---');
      debugPrint('DB Expires At (UTC): ${expiresAt.toIso8601String()}');
      debugPrint('Hora Actual (UTC): ${nowUtc.toIso8601String()}');
      debugPrint('¿Está expirado? $isExpired');
      debugPrint('---------------------------');

      if (isExpired) {
        debugPrint(
          'El token de MP para $userId ha caducado o está a punto de hacerlo. Intentando refrescar...',
        );
        final String? newToken = await _refreshMpToken(refreshToken, userId);

        if (newToken != null) {
          return newToken;
        } else {
          throw Exception(
            'Fallo al refrescar el token. El usuario necesita re-vincular su cuenta.',
          );
        }
      }
      return accessToken;
    } catch (e, stackTrace) {
      debugPrint('🔴 Error al obtener/refrescar el token de usuario: $e');
      debugPrint('StackTrace token: $stackTrace');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // FUNCIÓN UTILITARIA: Formatea el CUIL/CUIT a XX-XXXXXXXX-X (sin cambios)
  // ------------------------------------------------------------------
  String _formatCuil(String cuil) {
    final String cleanCuil = cuil.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanCuil.length != 11) {
      return cuil;
    }

    final String prefix = cleanCuil.substring(0, 2);
    final String body = cleanCuil.substring(2, 10);
    final String suffix = cleanCuil.substring(10, 11);

    return '$prefix-$body-$suffix';
  }

  // ------------------------------------------------------------------
  // 🚀 FUNCIÓN: Generar la URL de OAuth (Llama a la Edge Function - sin cambios)
  // Nota: Usa esta y considera eliminar getMpAuthorizationUrl2
  // ------------------------------------------------------------------
  Future<String> getMpAuthorizationUrl({required String userId}) async {
    try {
      final response = await http.post(
        Uri.parse(_qrFunctionUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_supabaseAnonKey'},
        body: json.encode({'userId': userId, 'action': 'bind_account'}),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authorizationUrl = data['authorization_url'];

        if (authorizationUrl != null && authorizationUrl is String) {
          return authorizationUrl;
        } else {
          debugPrint('La función no devolvió el campo "authorization_url" correctamente.');
          throw Exception('La función no devolvió el campo "authorization_url" correctamente.');
        }
      } else {
        debugPrint('Binding Function Error: ${response.statusCode} - ${response.body}');
        throw Exception('Error (${response.statusCode}) al obtener el token de vinculación.');
      }
    } catch (e) {
      debugPrint('Excepción durante la obtención del token: $e');
      throw Exception('Fallo de conexión o error desconocido al obtener el token.');
    }
  }

  Future<String> getMpAuthorizationUrl2({required String userId}) async {
    try {
      final response = await http.post(
        Uri.parse(_qrFunctionUrl2),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_supabaseAnonKey'},
        body: json.encode({'userId': userId, 'action': 'bind_account'}),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authorizationUrl = data['authorization_url'];

        if (authorizationUrl != null && authorizationUrl is String) {
          return authorizationUrl;
        } else {
          debugPrint('La función no devolvió el campo "authorization_url" correctamente.');
          throw Exception('La función no devolvió el campo "authorization_url" correctamente.');
        }
      } else {
        debugPrint('Binding Function Error: ${response.statusCode} - ${response.body}');
        throw Exception('Error (${response.statusCode}) al obtener el token de vinculación.');
      }
    } catch (e) {
      debugPrint('Excepción durante la obtención del token: $e');
      throw Exception('Fallo de conexión o error desconocido al obtener el token.');
    }
  }

  // ------------------------------------------------------------------
  // FUNCIÓN PRINCIPAL DE VERIFICACIÓN (AHORA CON LÓGICA DE RETRY MEJORADA)
  // ------------------------------------------------------------------
  Future<VerificationResult> verifyTransaction({
    double? amount,
    String? senderCuil,
    String? coelsaId,
    required String recipientCuil,
    required String userId,
  }) async {
    debugPrint('📢 Iniciando verificación para usuario $userId...');
    debugPrint(
      'Criterios: Monto=$amount, CUIL Remitente=$senderCuil, Coelsa ID=$coelsaId, CUIL Receptor=$recipientCuil',
    );

    String? userMpToken;

    for (int attempt = 0; attempt < 2; attempt++) {
      if (userMpToken == null) {
        try {
          userMpToken = await _getUserMpAccessToken(userId: userId);
        } catch (e) {
          debugPrint('🔴 Fallo al obtener el token: $e');

          if (attempt == 0) {
            return VerificationResult(
              isVerified: false,
              message:
                  '❌ Error de autenticación. El usuario debe vincular su cuenta de Mercado Pago o su token ha caducado y no pudo ser refrescado.',
            );
          }
          break;
        }
      }

      if (amount == null && senderCuil == null && (coelsaId == null || coelsaId.isEmpty)) {
        debugPrint('🔴 Error de validación: Faltan parámetros de búsqueda.');
        return VerificationResult(
          isVerified: false,
          message:
              '❌ Debes proporcionar al menos el Monto, el CUIL del Remitente o el Coelsa ID para realizar la búsqueda.',
        );
      }

      final DateTime now = DateTime.now().toUtc();
      final DateTime fortyEightHoursAgo = now.subtract(const Duration(hours: 48));

      final DateFormat isoFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
      final String beginDate = isoFormatter.format(fortyEightHoursAgo);
      final String endDate = isoFormatter.format(now);

      String apiUrl =
          '$_paymentsSearchUrl?begin_date=$beginDate&end_date=$endDate&collector.identification.number=$recipientCuil&sort=date_created&criteria=desc';

      if (coelsaId != null && coelsaId.isNotEmpty) {
        apiUrl += '&external_reference=$coelsaId';
      }

      debugPrint('➡️ URL de búsqueda MP: $apiUrl');

      try {
        final response = await http.get(
          Uri.parse(apiUrl),
          headers: {'Authorization': 'Bearer $userMpToken'},
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseBody = json.decode(response.body);
          final List<dynamic> results = responseBody['results'];

          debugPrint('🔍 Resultados encontrados en MP: ${results.length}');

          final matchingTransactions = results.where((payment) {
            final double transactionAmount = payment['transaction_amount'].toDouble();
            final String? payerCuil = payment['payer']['identification']?['number'];

            final String cleanedSenderCuil = (senderCuil ?? '').replaceAll('-', '');
            final String? cleanedPayerCuil = payerCuil?.replaceAll('-', '');

            final bool amountMatches =
                (amount == null) ||
                (transactionAmount.toStringAsFixed(2) == amount.toStringAsFixed(2));

            final bool cuilMatches =
                (senderCuil == null) ||
                (cleanedPayerCuil == cleanedSenderCuil && cleanedSenderCuil.isNotEmpty);

            final bool isApproved = payment['status'] == 'approved';

            if (kDebugMode) {
              debugPrint(
                ' - Analizando Pago ${payment['id']}: Monto Coincide=$amountMatches, CUIL Coincide=$cuilMatches, Aprobado=$isApproved',
              );
            }

            return amountMatches && cuilMatches && isApproved;
          }).toList();

          if (matchingTransactions.isNotEmpty) {
            final Map<String, dynamic> payment = matchingTransactions.first;

            final double foundAmount = payment['transaction_amount'].toDouble();
            final String foundStatus = payment['status'];

            final String clientIdentifierRaw =
                payment['payer']['identification']?['number'] ?? 'N/A';
            final String clientIdentifierFormatted = _formatCuil(clientIdentifierRaw);

            final String? firstName = payment['payer']['first_name'];
            final String? lastName = payment['payer']['last_name'];
            String? clientName;
            if (firstName != null || lastName != null) {
              clientName = [firstName, lastName].where((name) => name != null).join(' ');
            }

            final String sourceBank = payment['financial_institution'] ?? 'Transferencia Bancaria';

            final DateTime approvedDateTime = DateTime.parse(payment['date_approved']);

            final DateTime approvedDateTimeUtc = approvedDateTime.toUtc();

            final DateTime correctedDateTime = approvedDateTimeUtc.subtract(
              const Duration(hours: 3),
            );

            final String formattedDateTimeDB = DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(correctedDateTime);

            if (kDebugMode) {
              debugPrint('✅ Hora en DB (UTC-3): $formattedDateTimeDB');
            }

            final String formattedDate = DateFormat('dd/MM/yyyy').format(correctedDateTime);
            final String formattedTime = DateFormat('HH:mm').format(correctedDateTime);

            final String transactionId = payment['id'].toString();
            final String externalReference = payment['external_reference'] ?? 'N/A';

            debugPrint(
              'Verificando si la transacción MP ID $transactionId es un duplicado en la DB.',
            );

            final bool isDuplicate = await _dbService.checkIfTransactionExists(transactionId);

            final Map<String, dynamic> paymentDetails = {
              ...payment,
              'extracted_status': foundStatus,
              'extracted_amount': foundAmount,
              'extracted_client_cuil': clientIdentifierFormatted,
              'extracted_client_name': clientName,
              'extracted_date': formattedDate,
              'extracted_time': formattedTime,
              'extracted_datetime_iso': formattedDateTimeDB,
              'extracted_transaction_id': transactionId,
              'extracted_external_reference': externalReference,
              'extracted_source_bank': sourceBank,
            };

            final String idDisplay = coelsaId != null
                ? 'Coelsa ID: $externalReference'
                : 'ID MP: $transactionId';

            if (isDuplicate) {
              debugPrint('Transacción $transactionId es duplicada.');
              return VerificationResult(
                isVerified: true,
                isDuplicate: true,
                message: '⚠️ Transferencia APROBADA y REGISTRADA.\n$idDisplay',
                paymentDetails: paymentDetails,
              );
            }

            return VerificationResult(
              isVerified: true,
              isDuplicate: false,
              message: "Transferencia APROBADA y NO REGISTRADA\n$idDisplay",
              paymentDetails: paymentDetails,
            );
          } else {
            debugPrint(
              '❌ No se encontró ninguna transacción que cumpla con todos los criterios de filtro.',
            );
            return VerificationResult(
              isVerified: false,
              message:
                  '❌ No se encontró ninguna transferencia APROBADA que coincida con los criterios: ${[if (amount != null) 'Monto: \$${amount.toStringAsFixed(2)}', if (senderCuil != null) 'CUIL: $senderCuil', if (coelsaId != null) 'Coelsa ID: $coelsaId'].join(' y ')}.',
            );
          }
        } else if (response.statusCode == 401 && attempt == 0) {
          debugPrint('🚨 401 DETECTADO. Forzando intento de refresco y reintento de búsqueda...');

          final Map<String, dynamic>? mpData = await _dbService.fetchMpAccountDetails(userId);
          final String? refreshToken = mpData?['refresh_token'] as String?;

          if (refreshToken != null) {
            final String? newToken = await _refreshMpToken(refreshToken, userId);

            if (newToken != null) {
              userMpToken = newToken;
              debugPrint('✅ Refresco en caliente exitoso. Reintentando con el nuevo token.');
              continue;
            }
          }
          break;
        } else {
          String errorBody = response.body;
          if (response.statusCode == 401) {
            debugPrint('🔴 Fallo Crítico: El token recién refrescado sigue siendo inválido.');
            errorBody =
                'Token de acceso de Mercado Pago caducado o inválido. El usuario necesita re-vincular su cuenta.';
          }
          debugPrint(
            '🔴 ERROR DE API MP: Código ${response.statusCode}. Mensaje: $errorBody. URL: $apiUrl',
          );

          return VerificationResult(
            isVerified: false,
            message: 'Error en la API: Código ${response.statusCode}. Mensaje: $errorBody',
          );
        }
      } catch (e, stackTrace) {
        debugPrint('🔴 Excepción durante la verificación: $e');
        debugPrint('StackTrace verificación: $stackTrace');

        return VerificationResult(
          isVerified: false,
          message: 'Ocurrió una excepción durante la verificación: $e',
        );
      }
    }

    return VerificationResult(
      isVerified: false,
      message:
          '❌ Fallo en la autenticación. El token de Mercado Pago ha caducado y no pudo ser refrescado. Por favor, re-vincula tu cuenta.',
    );
  }
}
