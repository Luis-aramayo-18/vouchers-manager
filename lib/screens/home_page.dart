import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart' as camera;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vouchers_manager/widgets/main_drawer.dart';
import 'package:vouchers_manager/widgets/camera_options_fab.dart';
import 'package:vouchers_manager/screens/main_content_body.dart';
import 'package:vouchers_manager/screens/camera_screen.dart';
import 'package:vouchers_manager/screens/manual_entry_screen.dart';
import 'package:vouchers_manager/screens/login_view.dart';

class HomePage extends StatefulWidget {
  final List<camera.CameraDescription> cameras;

  const HomePage({super.key, required this.cameras});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  File? _pickedImage;

  // ----------------------------------------------------
  // 1. Lógica de Cierre de Sesión y Navegación
  // ----------------------------------------------------
  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        // Navegamos a LoginView y limpiamos el stack de navegación.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false, // Elimina todas las rutas anteriores
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToCamera() async {
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(cameras: widget.cameras),
      ),
    );

    if (result != null) {
      setState(() {
        _pickedImage = result;
      });
    }
  }


  void _navigateToManual() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
    );
  }


  void _clearPickedImage() {
    setState(() {
      _pickedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de Comprobantes'),
        backgroundColor: Colors.blue, 
        foregroundColor: Colors.white,
        actions: [
          if (_pickedImage != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearPickedImage,
              tooltip: 'Volver a la vista principal',
            ),
        ],
      ),
      drawer: MainDrawer(onLogout: _handleLogout), 
      extendBody: true,
      body: _pickedImage != null
            ? Center(
                child: Container(
                  color: Colors.white,
                  child: Image.file(_pickedImage!),
                ),
              )
            : const MainContentBody(),
      floatingActionButton: CameraOptionsFab(
        onCameraPressed: _navigateToCamera,
        onManualPressed: _navigateToManual,
      ),
    );
  }
}