// lib/widgets/_camera_control_buttons.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as camera;

class CameraButtons extends StatelessWidget {
  final VoidCallback onToggleFlash;
  final VoidCallback onToggleGrid;
  final VoidCallback onCloseCamera;
  final VoidCallback onTakePicture;
  final camera.FlashMode flashMode;
  final bool showGrid;

  const CameraButtons({super.key, 
    required this.onToggleFlash,
    required this.onToggleGrid,
    required this.onCloseCamera,
    required this.onTakePicture,
    required this.flashMode,
    required this.showGrid,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 40.0,
          right: 16.0,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: "btn_flash",
                onPressed: onToggleFlash,
                mini: true,
                child: Icon(
                  flashMode == camera.FlashMode.off
                      ? Icons.flash_off
                      : flashMode == camera.FlashMode.torch
                          ? Icons.flash_on
                          : Icons.flash_auto,
                ),
              ),
              const SizedBox(height: 16.0),
              FloatingActionButton(
                heroTag: "btn_grid",
                onPressed: onToggleGrid,
                mini: true,
                child: Icon(showGrid ? Icons.grid_off : Icons.grid_on),
              ),
              const SizedBox(height: 16.0),
              FloatingActionButton(
                heroTag: "btn_close",
                onPressed: onCloseCamera,
                mini: true,
                child: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 30.0,
          left: (MediaQuery.of(context).size.width - 72.0) / 2,
          child: FloatingActionButton(
            heroTag: "btn_capture",
            onPressed: onTakePicture,
            child: const Icon(Icons.camera),
          ),
        ),
      ],
    );
  }
}