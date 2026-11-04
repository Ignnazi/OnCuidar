import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oncuidar/nucleo/red/config_api.dart';

String correoNuevo() => 'e2e-${Random().nextInt(1 << 32)}@prueba.cl';

Finder campo(String etiqueta) => find.descendant(
  of: find
      .ancestor(of: find.text(etiqueta), matching: find.byType(Column))
      .first,
  matching: find.byType(TextFormField),
);

Future<void> escribir(WidgetTester tester, Finder destino, String texto) async {
  await tester.scrollUntilVisible(
    destino,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(destino, texto);
  await tester.pump();
}

Future<void> elegir(WidgetTester tester, String etiqueta, String opcion) async {
  final desplegable = find.descendant(
    of: find
        .ancestor(of: find.text(etiqueta), matching: find.byType(Column))
        .first,
    matching: find.byType(DropdownButtonFormField<String>),
  );
  await tester.scrollUntilVisible(
    desplegable,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(desplegable);
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcion).last);
  await tester.pumpAndSettle();
}

Future<void> tocar(WidgetTester tester, Finder destino) async {
  await tester.ensureVisible(destino);
  await tester.pumpAndSettle();
  await tester.tap(destino);
  await tester.pumpAndSettle();
}

Future<void> esperar(
  WidgetTester tester,
  Finder destino, {
  Duration limite = const Duration(seconds: 30),
}) async {
  final fin = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fin)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (destino.evaluate().isNotEmpty) return;
  }
  final textos = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .join(' | ');
  throw TestFailure('No apareció $destino. En pantalla: $textos');
}

class ApiDirecta {
  ApiDirecta(this.token);

  final String token;

  static Future<ApiDirecta> entrar(String correo, String contrasena) async {
    final r = await http.post(
      Uri.parse('${ConfigApi.urlBase}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );
    return ApiDirecta(jsonDecode(r.body)['token'] as String);
  }

  Future<List<dynamic>> obtener(String ruta) async {
    final r = await http.get(
      Uri.parse('${ConfigApi.urlBase}/$ruta'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(r.body) as List<dynamic>;
  }
}
