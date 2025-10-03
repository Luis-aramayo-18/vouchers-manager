import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vouchers_manager/services/mercado_pago_service.dart';
import 'dart:math' show pow;
import 'dart:developer';

import 'package:vouchers_manager/widgets/transfer_card.dart';
import 'package:vouchers_manager/services/verification_database_service.dart';

// ====================================================================
// CLASE AUXILIAR 1: Formato de CUIL
// ====================================================================
class CuilFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final StringBuffer newText = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 10) {
        newText.write('-');
      }
      newText.write(text[i]);
    }

    String formattedText = newText.toString();
    if (formattedText.length > 13) {
      formattedText = formattedText.substring(0, 13);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// ====================================================================
// CLASE AUXILIAR 2: Formato de Monto con dos decimales
// ====================================================================
class CurrencyFormatter extends TextInputFormatter {
  final int decimalDigits;

  CurrencyFormatter({this.decimalDigits = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Aseguramos que tengamos 2 decimales y el resto son enteros
    double value = int.parse(newText) / pow(10, decimalDigits);
    final String formatted = value.toStringAsFixed(decimalDigits);

    // Retorna el valor formateado
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ====================================================================
// PANTALLA PRINCIPAL
// ====================================================================
class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final MercadoPagoService _mpService = MercadoPagoService();
  final VerificationDatabaseService _dbService = VerificationDatabaseService();

  final _formKey = GlobalKey<FormState>();

  final _coelsaIdController = TextEditingController();
  final _cuilController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isLoading = false;

  Map<String, dynamic>? _verificationResultDetails;

  static const String _recipientCuil = '20379599738';

  @override
  void dispose() {
    // Asegurarse de liberar el nuevo controlador
    _coelsaIdController.dispose();
    _cuilController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    // Limpiar resultados anteriores al iniciar una nueva verificación
    setState(() {
      _verificationResultDetails = null;
    });

    // Validamos que al menos un campo tenga datos, ya que eliminamos los validadores individuales.
    final bool hasCoelsaId = _coelsaIdController.text.trim().isNotEmpty;
    final bool hasSenderCuil = _cuilController.text.trim().isNotEmpty;
    final bool hasAmount = _amountController.text.trim().isNotEmpty;

    if (!hasCoelsaId && !hasSenderCuil && !hasAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Debes ingresar al menos el Monto, el CUIL o el Coelsa ID.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() || true) {
      // El `|| true` está de más si quitamos validadores
      setState(() {
        _isLoading = true;
      });

      // === Preparación de Parámetros Opcionales ===

      // Coelsa ID: Si está vacío, se envía null.
      final String? coelsaId = hasCoelsaId
          ? _coelsaIdController.text.trim()
          : null;

      // CUIL: Si está vacío, se envía null. Se limpia de guiones antes de enviar.
      final String? senderCuil = hasSenderCuil
          ? _cuilController.text.replaceAll(RegExp(r'[^\d]'), '')
          : null;

      // Monto: Si está vacío, se envía null. Se limpia y parsea.
      double? amount;
      if (hasAmount) {
        final String cleanedAmountText = _amountController.text.replaceAll(
          ',',
          '.',
        );
        amount = double.tryParse(cleanedAmountText);
        // Si el parseo falla, el servicio de MP lo manejará como un criterio no válido,
        // pero aquí nos aseguramos de que sea un double si existe.
      }

      final VerificationResult result = await _mpService.verifyTransaction(
        // Si amount es null, se pasa null. Si se parseó correctamente, se pasa el valor.
        amount: amount,
        // Si senderCuil es null, se pasa null. Si tiene valor, se pasa la cadena limpia.
        senderCuil: senderCuil,
        // Si coelsaId es null, se pasa null.
        coelsaId: coelsaId,
        recipientCuil: _recipientCuil,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        if (result.isVerified && result.paymentDetails != null) {
          _verificationResultDetails = result.paymentDetails;
        } else {
          _verificationResultDetails = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isVerified ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      if (result.isVerified) {
        log(
          'Transferencia Verificada con éxito. Detalles: ${result.paymentDetails}',
        );
      }
    }
  }

  TransferStatus _getTransferStatus(String mpStatus) {
    if (mpStatus == 'approved') {
      return TransferStatus.completed;
    }

    return TransferStatus.failed;
  }

  void _handleSave() async {
    final Map<String, dynamic>? verificationDetails =
        _verificationResultDetails;

    if (verificationDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay una verificación aprobada para guardar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String message = await _dbService.saveVerification(
      verificationDetails,
    );

    Color snackBarColor = Colors.blueGrey;
    if (message.startsWith('✅')) {
      snackBarColor = Colors.green;
    } else if (message.startsWith('⚠️')) {
      snackBarColor = Colors.orange;
    } else if (message.startsWith('❌')) {
      snackBarColor = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: snackBarColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carga Manual'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ------------------ CAMPO COELSA ID (NUEVO) ------------------
                    TextFormField(
                      controller: _coelsaIdController,
                      // Eliminamos maxLength para Coelsa ID ya que puede ser variable
                      // Eliminamos inputFormatters y validator.
                      decoration: const InputDecoration(
                        labelText: 'Coelsa ID (Opcional)',
                        hintText: 'Ej: 2024100115304500012345MP',
                        prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      // ❌ Eliminamos el validator para hacerlo opcional.
                    ),
                    const SizedBox(height: 20),

                    // ------------------ CAMPO CUIL ------------------
                    TextFormField(
                      controller: _cuilController,
                      maxLength: 13,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CuilFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'CUIL del Remitente (Opcional)',
                        hintText: 'Ej: 20-37959973-8',
                        prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      // ❌ Eliminamos el validator para hacerlo opcional.
                    ),
                    const SizedBox(height: 20),

                    // ------------------ CAMPO MONTO ------------------
                    TextFormField(
                      controller: _amountController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Monto Transferido (Opcional)',
                        hintText: 'Ej: 1500.50 o 1500,50',
                        prefixText: '\$', // Símbolo de moneda
                        prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      // ❌ Eliminamos el validator para hacerlo opcional.
                    ),
                    const SizedBox(height: 30),

                    // ------------------ BOTÓN ENVIAR ------------------
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18.0),
                          elevation: 0,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Corroborar Transferencia',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Renderizado Condicional de la Tarjeta
              if (_verificationResultDetails != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    TransferCard(
                      // Mapeamos los campos extraídos de Mercado Pago a la TransferCard
                      status: _getTransferStatus(
                        _verificationResultDetails!['extracted_status']
                            as String,
                      ),
                      // Se usa .toString() para evitar el error de casting si el valor es un double.
                      amount: double.parse(
                        _verificationResultDetails!['extracted_amount']
                            .toString(),
                      ),
                      // 🌟 CAMBIO AQUÍ: Busca 'extracted_client_name' y si no existe, usa 'extracted_client_cuil'.
                      clientName:
                          (_verificationResultDetails!['extracted_client_name'] ??
                                  _verificationResultDetails!['extracted_client_cuil'])
                              .toString(),
                      date:
                          _verificationResultDetails!['extracted_date']
                              as String,
                      time:
                          _verificationResultDetails!['extracted_time']
                              as String,
                      sourceBank:
                          _verificationResultDetails!['extracted_source_bank']
                              as String,
                      onSave: _handleSave,
                    ),
                    const SizedBox(height: 20),
                    // Aquí podrías agregar más acciones o un botón para guardar
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
