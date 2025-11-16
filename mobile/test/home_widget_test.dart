import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetwash_mobile/main.dart' as app;

void main() {
  testWidgets('Home has expected buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const app.JetWashApp());

    // espera o frame
    await tester.pumpAndSettle();

    expect(find.text('Pátio (OS)'), findsOneWidget);
    expect(find.text('Onboarding / White‑label'), findsOneWidget);
    expect(find.text('OCR de placa (câmera)'), findsOneWidget);
    expect(find.text('Upload foto (Storage)'), findsOneWidget);
  });
}
