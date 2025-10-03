import 'package:flutter/material.dart';

import 'package:camera/camera.dart' as camera;
import 'package:vouchers_manager/screens/camera_screen.dart';

class CameraButton extends StatelessWidget {
  final List<camera.CameraDescription> cameras;

  const CameraButton({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(cameras: cameras),
          ),
        );
      },
      tooltip: 'Añadir Comprobante',
      child: const Icon(Icons.camera_alt),
    );
  }
}
