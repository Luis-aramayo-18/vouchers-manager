import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vouchers_manager/app.dart';
import 'package:camera/camera.dart';

void main() {
  const List<CameraDescription> mockCameras = [];

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(cameras: mockCameras));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
