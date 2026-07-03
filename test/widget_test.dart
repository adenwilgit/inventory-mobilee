import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inventory_mobile/app.dart';
import 'package:inventory_mobile/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('TirtaApp smoke test - renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(hasSession: false),
        child: const TirtaApp(),
      ),
    );
    // Verifikasi bahwa widget berhasil dirender
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
