import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<List<dynamic>> loadReceiptsData() async {
  // Carga el contenido del archivo como una cadena de texto
  final String response = await rootBundle.loadString('assets/data/receipts_data.json');

  // Decodifica la cadena JSON en una lista de objetos
  final data = json.decode(response);

  return data;
}