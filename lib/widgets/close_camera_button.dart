// lib/widgets/close_camera_button.dart
import 'package:flutter/material.dart';

class CloseCameraButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CloseCameraButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10.0,
      left: 10.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: onPressed,
        ),
      ),
    );
  }
}