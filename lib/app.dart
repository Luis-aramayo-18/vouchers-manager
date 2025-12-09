import 'package:flutter/material.dart';
import 'package:vouchers_manager/screens/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Comprobantes',
      home: const MyHomePage(),
    );
  }
}