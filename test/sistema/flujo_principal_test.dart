@Tags(['dispositivo'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oncuidar/main.dart' as app;

import 'ayudas.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crear cuenta, registrar signos y que lleguen cifrados', (
    tester,
  ) async {
    final correo = correoNuevo();
    await app.main();
    await esperar(tester, find.text('Crear Cuenta'));
    await tocar(tester, find.text('Crear Cuenta'));

    await escribir(tester, campo('Nombre completo'), 'Ana Pérez');
    await elegir(tester, 'Relación con el paciente', 'Madre');
    await escribir(tester, campo('Teléfono'), '+56911111111');
    await escribir(tester, campo('Dirección'), 'Av. Siempre Viva 123');
    await escribir(tester, campo('Correo electrónico'), correo);
    await escribir(tester, campo('Contraseña'), 'secreta1');
    await escribir(tester, campo('Confirmar contraseña'), 'secreta1');
    await escribir(tester, campo('Nombre del paciente'), 'Tomás Pérez');
    await escribir(tester, campo('RUT del paciente'), '11.111.111-1');
    await escribir(tester, campo('Fecha de nacimiento'), '10/03/2018');
    await escribir(tester, campo('Diagnóstico'), 'Leucemia');
    await elegir(tester, 'Fase de tratamiento', 'Tratamiento');
    await escribir(tester, campo('Centro de salud'), 'Hospital Sótero del Río');
    await escribir(tester, campo('Dirección del centro'), 'Concha y Toro 3459');
    await escribir(tester, campo('Tel. contacto del centro'), '+56222222222');
    await escribir(tester, campo('Contacto de emergencia'), 'Juan Pérez');
    await escribir(tester, campo('Tel. de urgencia'), '+56933333333');
    await tocar(tester, find.text('Guardar y continuar'));

    await esperar(tester, find.text('Aprende'));
    await tocar(tester, find.text('Registro').last);
    await esperar(tester, find.text('Guardar registro'));
    final temperatura = find.ancestor(
      of: find.text('37.0'),
      matching: find.byType(TextField),
    );
    await tester.enterText(temperatura, '38.6');
    await tocar(tester, find.text('Guardar registro'));
    await esperar(tester, find.text('Guardado correctamente'));

    final api = await ApiDirecta.entrar(correo, 'secreta1');
    final pacientes = await api.obtener('pacientes');
    expect(pacientes, hasLength(1));
    final registros = await api.obtener(
      'pacientes/${pacientes.single['id']}/registros',
    );
    expect(registros, hasLength(1));
    final guardado = jsonEncode(registros.single);
    expect(guardado, isNot(contains('38.6')));
    expect(jsonEncode(pacientes.single), isNot(contains('Tomás')));
  });
}
