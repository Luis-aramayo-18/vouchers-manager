import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class FlashButton extends StatelessWidget {
  final VoidCallback onPressed;
  final FlashMode flashMode;

  const FlashButton({
    super.key,
    required this.onPressed,
    required this.flashMode,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (flashMode == FlashMode.off) {
      icon = Icons.flash_off;
    } else if (flashMode == FlashMode.torch) {
      icon = Icons.flashlight_on;
    } else {
      icon = Icons.flash_auto;
    }

    return Positioned(
      top: 10.0,
      right: 10.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 30),
          onPressed: onPressed,
        ),
      ),
    );
  }
}