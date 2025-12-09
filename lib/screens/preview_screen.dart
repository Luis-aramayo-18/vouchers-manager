import 'dart:io';
import 'package:flutter/material.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Previa del Comprobante'),
      ),
      body: Center(
        child: Image.file(
          File(imagePath),
        ),
      ),
    );
  }
}