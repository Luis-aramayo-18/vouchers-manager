import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as camera;

import 'package:vouchers_manager/widgets/close_camera_button.dart';
import 'package:vouchers_manager/widgets/grid_button.dart';
import 'package:vouchers_manager/widgets/flash_button.dart';
import 'package:vouchers_manager/widgets/capture_button.dart';
import 'package:vouchers_manager/widgets/rule_of_thirds_grid.dart';
import 'package:vouchers_manager/screens/preview_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<camera.CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late camera.CameraController _controller;
  late Future<void> _initializeControllerFuture;

  bool _isCapturing = false;

  camera.FlashMode _flashMode = camera.FlashMode.off;
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    _controller = camera.CameraController(
      widget.cameras[0],
      camera.ResolutionPreset.max,
      imageFormatGroup: camera.ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlashMode() {
    setState(() {
      if (_flashMode == camera.FlashMode.off) {
        _flashMode = camera.FlashMode.torch;
        _controller.setFlashMode(camera.FlashMode.torch);
      } else if (_flashMode == camera.FlashMode.torch) {
        _flashMode = camera.FlashMode.auto;
        _controller.setFlashMode(camera.FlashMode.auto);
      } else {
        _flashMode = camera.FlashMode.off;
        _controller.setFlashMode(camera.FlashMode.off);
      }
    });
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  Future<void> _takePicture() async {
    if (_isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                const SizedBox(height: 50.0),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Stack(
                        children: [
                          SizedBox.expand(
                            child: camera.CameraPreview(_controller),
                          ),
                          if (_showGrid)
                            const SizedBox.expand(child: RuleOfThirdsGrid()),

                          CloseCameraButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Positioned(
                            top: 10.0,
                            left: 0,
                            right: 0, // Centrado
                            child: Center(
                              child: GridButton(
                                onPressed: _toggleGrid,
                                isGridActive: _showGrid,
                              ),
                            ),
                          ),
                          FlashButton(
                            onPressed: _toggleFlashMode,
                            flashMode: _flashMode,
                          ),
                          CaptureButton(
                            // Solución: Usar una función vacía en lugar de null
                            onPressed: _isCapturing
                                ? () {}
                                : () => _takePicture(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50.0),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
