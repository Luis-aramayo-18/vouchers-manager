import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vouchers_manager/services/mercado_pago_service.dart';
import 'dart:math' show pow;
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vouchers_manager/widgets/transfer_card.dart';
import 'package:vouchers_manager/services/verification_database_service.dart';

// ====================================================================
// CLASE AUXILIAR 1: Formato de CUIL
// ====================================================================
class CuilFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
// CLASE AUXILIAR 2: Formato de Monto con dos decimales (Sin cambios)
// ====================================================================
class CurrencyFormatter extends TextInputFormatter {
  final int decimalDigits;

  CurrencyFormatter({this.decimalDigits = 2});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = int.parse(newText) / pow(10, decimalDigits);
    final String formatted = value.toStringAsFixed(decimalDigits);

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
  late final VerificationDatabaseService _dbService;
  late final MercadoPagoService _mpService;
  late final String _currentUserId;

  _ManualEntryScreenState() {
    _dbService = VerificationDatabaseService();
    _mpService = MercadoPagoService(_dbService);

    final User? currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      log('⚠️ ADVERTENCIA: Usuario de Supabase NO autenticado. Usando ID de emergencia.');
      _currentUserId = '00000000-0000-0000-0000-000000000000';
    } else {
      _currentUserId = currentUser.id;
      log('✅ Supabase User ID: $_currentUserId');
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _coelsaIdController = TextEditingController();
  final _cuilController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isLoading = false;

  VerificationResult? _verificationResult;

  static const String _recipientCuil = '20379599738';

  @override
  void dispose() {
    _coelsaIdController.dispose();
    _cuilController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    setState(() {
      _verificationResult = null;
    });

    final bool hasCoelsaId = _coelsaIdController.text.trim().isNotEmpty;
    final bool hasSenderCuil = _cuilController.text
        .trim()
        .replaceAll(RegExp(r'[^\d]'), '')
        .isNotEmpty;
    final bool hasAmount = _amountController.text.trim().isNotEmpty;

    if (!hasCoelsaId && !hasSenderCuil && !hasAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Debes ingresar al menos el Monto, el CUIL o el Coelsa ID.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() || true) {
      setState(() {
        _isLoading = true;
      });

      final String? coelsaId = hasCoelsaId ? _coelsaIdController.text.trim() : null;

      final String? senderCuil = hasSenderCuil
          ? _cuilController.text.replaceAll(RegExp(r'[^\d]'), '')
          : null;

      double? amount;
      if (hasAmount) {
        final String cleanedAmountText = _amountController.text.replaceAll(',', '.');
        amount = double.tryParse(cleanedAmountText);
      }

      final VerificationResult result = await _mpService.verifyTransaction(
        amount: amount,
        senderCuil: senderCuil,
        coelsaId: coelsaId,
        recipientCuil: _recipientCuil,
        userId: _currentUserId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isVerified ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      setState(() {
        _isLoading = false;

        if (result.isVerified) {
          _verificationResult = result;
        } else {
          _verificationResult = null;
        }
      });

      if (result.isVerified) {
        log('Transferencia Verificada con éxito. Detalles: ${result.paymentDetails}');
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
    final Map<String, dynamic>? verificationDetails = _verificationResult?.paymentDetails;

    if (verificationDetails == null || (_verificationResult?.isDuplicate ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se pueden guardar transacciones APROBADAS y NO REGISTRADAS.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String message = await _dbService.saveVerification(
      verificationDetails,
      userId: _currentUserId,
    );

    if (!mounted) return;

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

    if (message.startsWith('✅')) {
      setState(() {
        _verificationResult = VerificationResult(
          isVerified: true,
          isDuplicate: true,
          message: 'Guardado y Registrado',
          paymentDetails: verificationDetails,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _verificationResult?.paymentDetails;
    final isVerified = _verificationResult?.isVerified ?? false;
    final isDuplicate = _verificationResult?.isDuplicate ?? false;

    final VoidCallback? onSaveCallback = isVerified && !isDuplicate ? _handleSave : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carga Manual'),
        centerTitle: true,
        backgroundColor: Colors.blue,
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
                    // ------------------ CAMPO COELSA ID ------------------
                    TextFormField(
                      controller: _coelsaIdController,
                      decoration: InputDecoration(
                        labelText: 'Coelsa ID (Opcional)',
                        hintText: 'Ej: 2024100115304500012345MP',
                        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        contentPadding: EdgeInsets.zero,
                        labelStyle: const TextStyle(color: Color.fromARGB(179, 46, 46, 46)),
                        hintStyle: const TextStyle(color: Color.fromARGB(135, 94, 94, 94)),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color.fromARGB(175, 34, 34, 34),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 1.0),
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(176, 255, 255, 255),
                            width: 1.0,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ------------------ CAMPO CUIL ------------------
                    TextFormField(
                      controller: _cuilController,
                      maxLength: 13,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, CuilFormatter()],
                      decoration: InputDecoration(
                        labelText: 'CUIL del Remitente (Opcional)',
                        hintText: 'Ej: 20-37959973-8',
                        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        contentPadding: EdgeInsets.zero,
                        labelStyle: const TextStyle(color: Color.fromARGB(179, 46, 46, 46)),
                        hintStyle: const TextStyle(color: Color.fromARGB(135, 94, 94, 94)),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(175, 34, 34, 34),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 1.0),
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(176, 255, 255, 255),
                            width: 1.0,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // ------------------ CAMPO MONTO ------------------
                    TextFormField(
                      controller: _amountController,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      decoration: InputDecoration(
                        labelText: 'Monto Transferido (Opcional)',
                        hintText: 'Ej: 1500.50 o 1500,50',
                        prefixText: '\$',
                        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        contentPadding: EdgeInsets.zero,
                        labelStyle: const TextStyle(color: Color.fromARGB(179, 46, 46, 46)),
                        hintStyle: const TextStyle(color: Color.fromARGB(135, 94, 94, 94)),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(175, 34, 34, 34),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 1.0),
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(176, 255, 255, 255),
                            width: 1.0,
                          ),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 30),

                    // ------------------ BOTÓN ENVIAR ------------------
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(77, 0, 0, 0),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (details != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    TransferCard(
                      status: _getTransferStatus(details['extracted_status'] as String),
                      amount: double.parse(details['extracted_amount'].toString()),
                      clientName:
                          (details['extracted_client_name'] ?? details['extracted_client_cuil'])
                              .toString(),
                      date: details['extracted_date'] as String,
                      time: details['extracted_time'] as String,
                      sourceBank: details['extracted_source_bank'] as String,
                      onSave: onSaveCallback,
                      isRegistered: isDuplicate,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}