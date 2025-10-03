import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import "app.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await initializeDateFormatting('es', null);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['PUBLIC_KEY']!,
  );

  try {
    final List<CameraDescription> cameras = await availableCameras();
    runApp(MyApp(cameras: cameras));
  } on CameraException catch (e) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text("Error al inicializar la cámara.")),
        ),
      ),
    );
  } catch (e) {
    runApp(const MyApp(cameras: []));
  }
}

final supabase = Supabase.instance.client;
