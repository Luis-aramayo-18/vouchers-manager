import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'package:vouchers_manager/screens/home_page.dart';
// Importación para logging, en reemplazo de `print`
import 'package:flutter/foundation.dart';

class MpVerificationScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MpVerificationScreen({super.key, required this.cameras});

  @override
  State<MpVerificationScreen> createState() => _MpVerificationScreenState();
}

class _MpVerificationScreenState extends State<MpVerificationScreen> {
  static const bool _isProduction = kReleaseMode;
  static final String _verifyCodeEndpoint = dotenv.env['SUPABASE_VERIFICATION_CODE_URL']!;

  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  // Función de logging simple para reemplazar `print`
  void _logError(String message, [dynamic error]) {
    if (!_isProduction) {
      debugPrint('ERROR MP_VERIFICATION: $message');
      if (error != null) {
        debugPrint('Detalle: $error');
      }
    }
  }

  Future<void> _verifyCode() async {
    final Session? session = Supabase.instance.client.auth.currentSession;
    final String? currentUserId = session?.user.id;
    final String? accessToken = session?.accessToken;

    if (currentUserId == null || accessToken == null) {
      if (mounted) {
        setState(() {
          _message =
              'Error: Sesión no encontrada o token no disponible. Por favor, vuelve a iniciar sesión.';
        });
      }
      return;
    }

    if (_codeController.text.isEmpty || _codeController.text.length != 6) {
      if (mounted) {
        setState(() {
          _message = 'Por favor, ingresa el código de 6 dígitos.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _message = '';
      });
    }

    try {
      final response = await http.post(
        Uri.parse(_verifyCodeEndpoint),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          'userId': currentUserId,
          'verificationCode': _codeController.text.trim(),
        }),
      );

      final responseBody = jsonDecode(response.body);

      // 🎯 CORRECCIÓN 1: Comprobar `mounted` antes de usar `context` y `setState`
      if (!mounted) return;

      if (response.statusCode == 200 && responseBody['success'] == true) {
        setState(() {
          _message = '¡Vinculación Confirmada con Éxito!';
        });

        // 🚀 NAVEGACIÓN A LA PANTALLA PRINCIPAL
        // 🎯 Paso 2: Pasar la lista real de cámaras recibida a HomePage
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage(cameras: widget.cameras)));
      } else {
        // Error de la Edge Function (código 400, 404, 500)
        setState(() {
          _message = responseBody['message'] ?? 'Error desconocido al verificar el código.';
        });
        _logError('Error de función Edge: ${response.statusCode}', responseBody);
      }
    } catch (e) {
      // Error de red (Time out, sin internet, etc.)
      // 🎯 CORRECCIÓN 2: Usar _logError en lugar de `print`
      _logError('Error de conexión/servidor', e);
      if (mounted) {
        setState(() {
          _message = 'Error de conexión: Verifica tu red.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Vinculación MP'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Ingresa el Código de Confirmación',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: Color(0xFF1E1E1E),
              ),
              decoration: InputDecoration(
                hintText: 'CÓDIGO DE 6 DIGITOS',
                hintStyle: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w400,
                ),
                counterText: '',
                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF00ADEE), width: 3),
                ),

                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              ),
            ),
            const SizedBox(height: 30),

            // Botón de Verificación
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ADEE),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirmar Código',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Mensaje de Estado
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message.contains('Éxito') ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.contains('Éxito') ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message.contains('Éxito') ? Colors.green.shade900 : Colors.red.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
