
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vouchers_manager/app.dart'; 

void main() {
  testWidgets('Verifica el incremento del contador (Prueba de humo)', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp()); 

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}