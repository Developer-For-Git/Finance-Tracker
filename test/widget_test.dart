import 'package:flutter/material.dart';
import 'package:ather_wallet/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AtherWalletApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
