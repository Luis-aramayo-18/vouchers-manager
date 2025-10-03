import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart' as camera;

import 'package:vouchers_manager/widgets/main_drawer.dart';
import 'package:vouchers_manager/widgets/camera_options_fab.dart';
import 'package:vouchers_manager/screens/main_content_body.dart';
import 'package:vouchers_manager/screens/camera_screen.dart';
import 'package:vouchers_manager/screens/manual_entry_screen.dart';

class MyHomePage extends StatefulWidget {
  final List<camera.CameraDescription> cameras;

  const MyHomePage({super.key, required this.cameras});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _pickedImage;

  void _navigateToCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(cameras: widget.cameras),
      ),
    );
  }

  void _navigateToManual() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const MainAppBar(title: 'Mis Transferencias'),
      drawer: const MainDrawer(),
      extendBody: true,
      body: _pickedImage != null
          ? Center(child: Image.file(_pickedImage!))
          : const MainContentBody(),
      floatingActionButton: CameraOptionsFab(
        onCameraPressed: _navigateToCamera,
        onManualPressed: _navigateToManual,
      ),
    );
  }
}
