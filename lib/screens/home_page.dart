import 'package:flutter/material.dart';
import 'package:vouchers_manager/screens/camera_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Comprobantes'),
        backgroundColor: Colors.blue,
      ),
      body: Center(child: Column(children: [])),
      backgroundColor: Colors.blue,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        tooltip: 'Añadir Comprobante',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
