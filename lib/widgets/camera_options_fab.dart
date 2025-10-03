import 'package:flutter/material.dart';

class CameraOptionsFab extends StatefulWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onManualPressed;

  const CameraOptionsFab({
    super.key,
    required this.onCameraPressed,
    required this.onManualPressed,
  });

  @override
  State<CameraOptionsFab> createState() => _CameraOptionsFabState();
}

class _CameraOptionsFabState extends State<CameraOptionsFab> {
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize:
          MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        AnimatedOpacity(
          opacity: _isMenuOpen ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_isMenuOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'manual_fab',
                  mini: true,
                  onPressed: widget.onManualPressed,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                const SizedBox(height: 16.0),
                FloatingActionButton(
                  heroTag: 'camera_fab',
                  mini: true,
                  onPressed: widget.onCameraPressed,
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        // Botón principal
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: _toggleMenu,
          backgroundColor: _isMenuOpen ? Colors.red : Colors.blue,
          child: AnimatedRotation(
            turns: _isMenuOpen ? 0.25 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
