import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class VerificationResult {
  final bool isVerified;
  final String message;
  final Map<String, dynamic>? paymentDetails;

  VerificationResult({
    required this.isVerified,
    required this.message,
    this.paymentDetails,
  });
}

class MercadoPagoService {
  static final String _accessToken = dotenv.env['MERCADO_PAGO_ACCESS_TOKEN']!;

  static const String _baseUrl =
      'https://api.mercadopago.com/v1/payments/search';

  // ------------------------------------------------------------------
  // FUNCIÓN UTILITARIA: Formatea el CUIL/CUIT a XX-XXXXXXXX-X
  // ------------------------------------------------------------------
  String _formatCuil(String cuil) {
    // 1. Limpiar todos los caracteres no numéricos
    final String cleanCuil = cuil.replaceAll(RegExp(r'[^\d]'), '');

    // 2. Verificar que tenga 11 dígitos (formato estándar de CUIL/CUIT)
    if (cleanCuil.length != 11) {
      // Devolver el valor original si no cumple el formato esperado
      return cuil;
    }

    // 3. Aplicar el formato XX-XXXXXXXX-X
    final String prefix = cleanCuil.substring(0, 2);
    final String body = cleanCuil.substring(2, 10);
    final String suffix = cleanCuil.substring(10, 11);

    return '$prefix-$body-$suffix';
  }

  // ------------------------------------------------------------------
  // FUNCIÓN PRINCIPAL DE VERIFICACIÓN
  // ------------------------------------------------------------------
  Future<VerificationResult> verifyTransaction({
    double? amount,
    String? senderCuil,
    String? coelsaId,
    required String recipientCuil,
  }) async {
    if (amount == null &&
        senderCuil == null &&
        (coelsaId == null || coelsaId.isEmpty)) {
      return VerificationResult(
        isVerified: false,
        message:
            '❌ Debes proporcionar al menos el Monto, el CUIL del Remitente o el Coelsa ID para realizar la búsqueda.',
      );
    }
    // 1. Lógica de Rango de Fechas (Últimas 48 horas)
    final DateTime now = DateTime.now().toUtc();
    final DateTime fortyEightHoursAgo = now.subtract(const Duration(hours: 48));

    // Formato ISO 8601 requerido por Mercado Pago
    final DateFormat isoFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    final String beginDate = isoFormatter.format(fortyEightHoursAgo);
    final String endDate = isoFormatter.format(now);

    // 2. Construcción de la URL de la API
    String apiUrl =
        '$_baseUrl?begin_date=$beginDate&end_date=$endDate&collector.identification.number=$recipientCuil&sort=date_created&criteria=desc';

    if (coelsaId != null && coelsaId.isNotEmpty) {
      apiUrl += '&external_reference=$coelsaId';
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer ${_accessToken.trim()}'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        final List<dynamic> results = responseBody['results'];

        // 3. Filtrado LOCAL de Monto y CUIL del Remitente
        final matchingTransactions = results.where((payment) {
          final double transactionAmount = payment['transaction_amount']
              .toDouble();
          final String? payerCuil =
              payment['payer']['identification']?['number'];

          // Limpiar guiones del CUIL del remitente para comparación
          final String cleanedSenderCuil = (senderCuil ?? '').replaceAll(
            '-',
            '',
          );
          final String? cleanedPayerCuil = payerCuil?.replaceAll('-', '');

          final bool amountMatches =
              (amount == null) ||
              (transactionAmount.toStringAsFixed(2) ==
                  amount.toStringAsFixed(2));

          final bool cuilMatches =
              (senderCuil == null) ||
              (cleanedPayerCuil == cleanedSenderCuil &&
                  cleanedSenderCuil.isNotEmpty);

          final bool isApproved = payment['status'] == 'approved';

          return amountMatches && cuilMatches && isApproved;
        }).toList();

        // 4. Devolución del Resultado
        if (matchingTransactions.isNotEmpty) {
          final payment = matchingTransactions.first;
          
          final double foundAmount = payment['transaction_amount'].toDouble();
          final String foundStatus = payment['status'];

          final String clientIdentifierRaw =
              payment['payer']['identification']?['number'] ?? 'N/A';

          final String clientIdentifierFormatted = _formatCuil(
            clientIdentifierRaw,
          );

          final String? firstName = payment['payer']['first_name'];
          final String? lastName = payment['payer']['last_name'];

          String? clientName;
          if (firstName != null || lastName != null) {
            clientName = [
              firstName,
              lastName,
            ].where((name) => name != null).join(' ');
          }

          final String sourceBank =
              payment['financial_institution'] ?? 'Transferencia Bancaria';

          final DateTime approvedDateTime = DateTime.parse(
            payment['date_approved'],
          );

          final DateTime correctedDateTime = approvedDateTime
              .toLocal()
              .subtract(const Duration(hours: 3));

          final String formattedDate = DateFormat(
            'dd/MM/yyyy',
          ).format(correctedDateTime);

          final String formattedTime = DateFormat(
            'HH:mm',
          ).format(correctedDateTime);

          final String transactionId = payment['id'].toString();
          final String externalReference =
              payment['external_reference'] ?? 'N/A';
          final String idDisplay = coelsaId != null
              ? 'Coelsa ID: $externalReference'
              : 'ID MP: $transactionId';

          return VerificationResult(
            isVerified: true,
            message: "Transferencia APROBADA\n$idDisplay",
            paymentDetails: {
              ...payment,
              'extracted_status': foundStatus,
              'extracted_amount': foundAmount,
              'extracted_client_cuil':
                  clientIdentifierFormatted, // Usamos el CUIL formateado
              'extracted_client_name': clientName,
              'extracted_date': formattedDate,
              'extracted_time': formattedTime,
              'extracted_transaction_id': transactionId,
              'extracted_external_reference': externalReference,
              'extracted_source_bank': sourceBank,
            },
          );
        } else {
          return VerificationResult(
            isVerified: false,
            message:
                '❌ No se encontró ninguna transferencia APROBADA que coincida con los criterios: ${[if (amount != null) 'Monto: \$${amount.toStringAsFixed(2)}', if (senderCuil != null) 'CUIL: $senderCuil', if (coelsaId != null) 'Coelsa ID: $coelsaId'].join(' y ')}.',
          );
        }
      } else {
        return VerificationResult(
          isVerified: false,
          message:
              'Error en la API: Código ${response.statusCode}. Mensaje: ${response.body}',
        );
      }
    } catch (e) {
      print('Excepción durante la verificación: $e');
      return VerificationResult(
        isVerified: false,
        message: 'Ocurrió una excepción durante la verificación: $e',
      );
    }
  }
}
