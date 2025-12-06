import 'package:flutter/material.dart';

class MercadoPagoSyncView extends StatelessWidget {
  final VoidCallback onSyncPressed;

  const MercadoPagoSyncView({super.key, required this.onSyncPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Sincroniza tu cuenta de Mercado Pago para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20.0),
              _buildMercadoPagoButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMercadoPagoButton(BuildContext context) {
    const Color mpPrimaryYellow = Color(0xFFFFCC00);

    return ElevatedButton(
      onPressed: onSyncPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: mpPrimaryYellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/mercado-pago-logo.png',
            height: 60,
          ),
          const SizedBox(width: 2),
          const Text(
            'VINCULAR CON MERCADO PAGO',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
