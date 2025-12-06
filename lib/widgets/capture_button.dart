import 'package:flutter/material.dart';

class CaptureButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CaptureButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10.0,
      left: 0,
      right: 0,
      child: Center(
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration( // Se agregó 'const'
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2.0),
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.circle,
                // 🎯 CORRECCIÓN: Reemplazamos withOpacity(0.8) por withAlpha(204)
                color: Colors.black.withAlpha(204), // 204 es el 80% de 255
                size: 50,
              ),
            ),
          ),
        ),
      ),
    );
  }
}