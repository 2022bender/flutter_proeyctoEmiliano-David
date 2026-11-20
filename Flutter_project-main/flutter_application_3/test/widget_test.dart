import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_3/main.dart';

void main() {
  testWidgets('Login screen renders at a narrow width',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const LoginApp());

    expect(find.text('INGRESAR'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Registration navigation returns to login',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const LoginApp());
    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();

    expect(find.text('CREAR CUENTA'), findsOneWidget);
    await tester.tap(find.text('Ya tengo una cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('INGRESAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
