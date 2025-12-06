import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as camera;
import 'package:provider/provider.dart';

import 'package:vouchers_manager/screens/deep_link_listener_screen.dart';
import 'package:vouchers_manager/providers/mp_sync_provider.dart'; 

import 'package:vouchers_manager/screens/auth_check_screen.dart';
import 'package:vouchers_manager/screens/home_page.dart';

class MyApp extends StatelessWidget {
  final List<camera.CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MpSyncProvider(),
      child: MaterialApp(
        title: 'Gestor de Comprobantes',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFFF3F4F6), 
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          useMaterial3: true,
        ),
        routes: {
          '/main_app': (context) => HomePage(cameras: cameras), 
        },
        home: DeepLinkListenerScreen(
          cameras: cameras,
          child: AuthCheckScreen(cameras: cameras), 
        ),
      ),
    );
  }
}