import 'package:flutter/material.dart';

import 'package:camera/camera.dart' as camera;
import 'package:vouchers_manager/screens/home_page.dart';

class MyApp extends StatelessWidget {
  final List<camera.CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Comprobantes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blue,
      ),
      home: MyHomePage(cameras: cameras),
    );
  }
}
