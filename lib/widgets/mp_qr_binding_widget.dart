import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MpQrBindingWidget extends StatelessWidget {
  final String bindingToken;
  final VoidCallback onNavigateToManualVerification;

  const MpQrBindingWidget({
    super.key,
    required this.bindingToken,
    required this.onNavigateToManualVerification,
  });

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFFE600);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'En tu telefono secundario:',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          const Text(
            '''1. Escanea el QR.
2. Navega al enlace.
3. Otorga los permisos necesarios.
4. Presiona "Continuar".''',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          Center(
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: QrImageView(
                  data: bindingToken,
                  version: QrVersions.auto,
                  size: 270.0,
                  gapless: true,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color.fromARGB(255, 0, 0, 0)),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: onNavigateToManualVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 5,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}
