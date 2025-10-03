import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  String _extractedText = 'Extrayendo texto...';
  Map<String, String> _extractedData = {};
  bool _isProcessing = true;
  bool _isVerifying = false;
  // Variables para el estado de la verificación y el mensaje
  String _verificationMessage = '';
  bool _isVerified = false;

  // Tu token de acceso de Mercado Pago. ¡Manténlo seguro!
  final String _accessToken =
      'APP_USR-8396920650936292-061821-9d41c04056ca9f13b0a7ede67eef8a0e-156958740';

  @override
  void initState() {
    super.initState();
    _doOcrAndExtractText();
  }

  // Función auxiliar para buscar un valor de Regex después de una palabra clave.
  String? _extractValueAfterKeyword(
      String fullText, 
      List<String> keywords, 
      RegExp valueRegex
    ) {
    final String upperText = fullText.toUpperCase();

    for (final keyword in keywords) {
      final String upperKeyword = keyword.toUpperCase();
      final int startIndex = upperText.indexOf(upperKeyword);

      if (startIndex != -1) {
        // Buscar en la porción de texto que sigue a la palabra clave
        final String remainingText = fullText.substring(startIndex + upperKeyword.length);
        final RegExpMatch? match = valueRegex.firstMatch(remainingText);

        if (match != null) {
          return match.group(0);
        }
      }
    }
    return null; 
  }

  Map<String, String> _parseVoucherData(String fullText) {
    final Map<String, String> data = {};
    const String normalizedRecipientCuil = '20379599738'; 

    // 1. Extracción del CUIL Remitente
    final cuilRegex = RegExp(r'\b\d{2}(?:-)?\d{8}(?:-)?\d{1}\b');
    final cuilKeywords = ['CUIL', 'CUIT/CUIL', 'CUIT', 'CUIL/CUIT' ];

    String? foundCuil = _extractValueAfterKeyword(fullText, cuilKeywords, cuilRegex);

    if (foundCuil == null || foundCuil.replaceAll('-', '') == normalizedRecipientCuil) {
      final Iterable<RegExpMatch> allCuils = cuilRegex.allMatches(fullText);
      for (final RegExpMatch cuilMatch in allCuils) {
        final String currentCuil = cuilMatch.group(0)!;
        final String normalizedCuil = currentCuil.replaceAll('-', '');
        if (normalizedCuil != normalizedRecipientCuil) {
          data['cuil_remitente'] = normalizedCuil;
          break;
        }
      }
    } else {
      data['cuil_remitente'] = foundCuil.replaceAll('-', '');
    }


    // 2. Extracción del Monto
    // Regex flexible: captura números con o sin $, con punto o coma como decimal.
    final valueOnlyRegex = RegExp(r'[\$]?\s?\d{1,3}(?:\.?\d{3})*(?:,\d{2})?|\d{1,3}(?:,?\d{3})*(?:\.\d{2})?'); 
    final amountKeywords = ['MONTO', 'TOTAL', 'IMPORTE', 'VALOR'];
    
    String? amountMatch = _extractValueAfterKeyword(fullText, amountKeywords, valueOnlyRegex);

    if (amountMatch == null) {
      // Lógica de respaldo si la extracción por palabra clave falla
      final generalAmountRegex = RegExp(r'\$[ ]?\d{1,3}(?:\.\d{3})*(?:,\d{2})?');
      final RegExpMatch? generalMatch = generalAmountRegex.firstMatch(fullText);
      if (generalMatch != null) {
        amountMatch = generalMatch.group(0);
      }
    }

    if (amountMatch != null) {
      // Normalización del monto
      String normalizedAmount = amountMatch.replaceAll(RegExp(r'[\$]'), '');
      // Intentar eliminar separadores de miles (.), pero ser cuidadoso con los decimales
      
      // Si el formato es 1.000,00 (punto miles, coma decimal)
      if (normalizedAmount.contains(',') && normalizedAmount.lastIndexOf('.') < normalizedAmount.lastIndexOf(',')) {
        normalizedAmount = normalizedAmount.replaceAll('.', '').replaceAll(',', '.');
      } 
      // Si el formato es 1,000.00 (coma miles, punto decimal) o sin miles
      else {
        normalizedAmount = normalizedAmount.replaceAll(',', ''); 
      }
      
      final double? amountDouble = double.tryParse(normalizedAmount);

      if (amountDouble != null) {
        data['monto'] = amountDouble.toStringAsFixed(2);
      }
    }

    return data;
  }

  Future<void> _doOcrAndExtractText() async {
    setState(() {
      _isProcessing = true;
      _verificationMessage = '';
      _isVerified = false;
    });
    final inputImage = InputImage.fromFilePath(widget.imagePath);
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      setState(() {
        _extractedText = recognizedText.text;
        _extractedData = _parseVoucherData(_extractedText);
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _extractedText = 'Error al procesar la imagen: $e';
        _isProcessing = false;
      });
    } finally {
      textRecognizer.close();
    }
  }

  // --- Función para verificar en la API de Mercado Pago (AJUSTADA) ---
// --- Función para verificar en la API de Mercado Pago (CORREGIDA) ---
Future<void> _verifyTransaction() async {
  if (_extractedData['cuil_remitente'] == null || _extractedData['monto'] == null) {
    setState(() {
      _verificationMessage = 'Faltan datos clave (CUIL Remitente y/o Monto) para la verificación.';
      _isVerified = false;
    });
    // Puedes usar un SnackBar de respaldo aquí para visibilidad inmediata si lo deseas.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_verificationMessage, style: const TextStyle(color: Colors.white))),
    );
    return;
  }

  setState(() {
    _isVerifying = true;
    _verificationMessage = 'Verificando transacción...';
  });

  // Datos extraídos del comprobante
  final String extractedAmountString = _extractedData['monto']!;
  final double extractedAmount = double.parse(extractedAmountString);
  final String extractedCuil = _extractedData['cuil_remitente']!;

  // --- LÓGICA DE FECHA (Últimas 48 horas) ---
  final DateTime now = DateTime.now().toUtc();
  final DateTime fortyEightHoursAgo = now.subtract(const Duration(hours: 48));

  final DateFormat isoFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  final String beginDate = isoFormatter.format(fortyEightHoursAgo);
  final String endDate = isoFormatter.format(now);

  // CUIL del destinatario (el tuyo) para la búsqueda en la API.
  const String cuilABuscar = '20379599738';

  // URL de la API: SOLO incluye fecha y el CUIL del RECEPTOR (collector)
  final String apiUrl =
      'https://api.mercadopago.com/v1/payments/search?begin_date=$beginDate&end_date=$endDate&collector.identification.number=$cuilABuscar&sort=date_created&criteria=desc';

  try {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final List<dynamic> results = responseBody['results'];

      // --- Lógica de filtrado LOCAL de Monto y CUIL Remitente ---
      final matchingTransactions = results.where((payment) {
        final double transactionAmount = payment['transaction_amount'].toDouble();
        final String? payerCuil = payment['payer']['identification']?['number'];

        final bool amountMatches = 
            (transactionAmount.toStringAsFixed(2) == extractedAmount.toStringAsFixed(2));

        final bool cuilMatches = (payerCuil?.replaceAll('-', '') == extractedCuil);

        return amountMatches && cuilMatches;
      }).toList();

      if (matchingTransactions.isNotEmpty) {
        final payment = matchingTransactions.first;
        setState(() {
          _isVerified = true;
          _verificationMessage = 
              '✅ ¡Transferencia APROBADA encontrada! ID: ${payment['id']}, Monto: \$${payment['transaction_amount']}, Estado: ${payment['status']}';
        });
      } else {
        setState(() {
          _isVerified = false;
          _verificationMessage = 
              '❌ No se encontró ninguna transferencia APROBADA que coincida con el CUIL y Monto extraídos en las últimas 48hs.';
        });
      }
    } else {
      setState(() {
        _isVerified = false;
        _verificationMessage = 'Error en la API de Mercado Pago: Código ${response.statusCode}';
      });
    }
  } catch (e) {
    setState(() {
      _isVerified = false;
      _verificationMessage = 'Ocurrió una excepción durante la verificación: $e';
    });
  } finally {
    setState(() {
      _isVerifying = false;
    });
  }
}
  // --- Widget build (la interfaz de usuario) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Previa del Comprobante'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _extractedData.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Datos extraídos:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  for (var entry in _extractedData.entries)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Text(
                                        '${entry.key.toUpperCase()}: ${entry.value}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  // Mostrar el mensaje de verificación
                                  Text(
                                    _verificationMessage,
                                    style: TextStyle(
                                      color: _isVerified ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: (_isVerifying || _extractedData['cuil_remitente'] == null || _extractedData['monto'] == null)
                                        ? null
                                        : _verifyTransaction,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isVerifying
                                        ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                        : const Text(
                                              'Corroborar Transferencia',
                                            ),
                                  ),
                                ],
                              )
                            : const Text(
                                'No se pudo extraer la información clave.',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}