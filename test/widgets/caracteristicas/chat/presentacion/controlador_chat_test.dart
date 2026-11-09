import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/chat/datos/proveedores_chat.dart';
import 'package:oncuidar/caracteristicas/chat/datos/repositorio_conversaciones.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/controlador_chat.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/proveedor_chat_activo.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RepositorioFalso implements RepositorioConversaciones {
  final creadas = <List<String>>[];
  final actualizadas = <String, List<String>>{};
  Completer<String>? respuestaCrear;

  @override
  Future<String> crearConversacion({
    required String titulo,
    required List<MensajeConversacion> mensajes,
  }) {
    creadas.add([for (final m in mensajes) m.texto]);
    return (respuestaCrear ??= Completer<String>()).future;
  }

  @override
  Future<void> actualizarConversacion(
    String id, {
    String? titulo,
    required List<MensajeConversacion> mensajes,
  }) async {
    actualizadas[id] = [for (final m in mensajes) m.texto];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late RepositorioFalso repositorio;
  late ControladorChat chat;
  late ProviderContainer contenedor;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repositorio = RepositorioFalso();
  });

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uidSesionProvider.overrideWithValue('u1'),
          repositorioConversacionesProvider.overrideWithValue(repositorio),
          contenidosEducativosProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            chat = ControladorChat(ref);
            contenedor = ProviderScope.containerOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    chat.nueva(null);
  }

  void guardar() =>
      chat.encolarGuardado(sigueAbierta: () => true, alFallar: () {});

  String? idActivo() => contenedor.read(chatActivoProvider).conversacionId;

  testWidgets('el id creado no se pega a la conversación abierta después', (
    tester,
  ) async {
    await montar(tester);
    chat.preguntar('Pregunta de A');
    guardar();
    await tester.pump();
    chat.nueva(null);
    repositorio.respuestaCrear!.complete('idA');
    await tester.pump();
    expect(idActivo(), isNull);

    repositorio.respuestaCrear = Completer<String>()..complete('idB');
    chat.preguntar('Pregunta de B');
    guardar();
    await tester.pump();
    expect(repositorio.creadas.last, ['Pregunta de B']);
    expect(repositorio.actualizadas.containsKey('idA'), isFalse);
    expect(idActivo(), 'idB');
  });

  testWidgets('el segundo guardado actualiza la conversación recién creada', (
    tester,
  ) async {
    await montar(tester);
    chat.preguntar('Pregunta');
    guardar();
    chat.responder(null, consulta: 'Pregunta');
    guardar();
    await tester.pump();
    chat.nueva(null);
    repositorio.respuestaCrear!.complete('idA');
    await tester.pump();
    expect(repositorio.creadas, hasLength(1));
    expect(repositorio.actualizadas['idA'], hasLength(2));
    expect(idActivo(), isNull);
  });

  testWidgets('si la pantalla se cierra al crear, el id igual queda', (
    tester,
  ) async {
    await montar(tester);
    var abierta = true;
    chat.preguntar('Pregunta');
    chat.encolarGuardado(sigueAbierta: () => abierta, alFallar: () {});
    await tester.pump();
    abierta = false;
    repositorio.respuestaCrear!.complete('idA');
    await tester.pump();
    expect(idActivo(), 'idA');
  });

  testWidgets('un guardado pendiente no revive una conversación borrada', (
    tester,
  ) async {
    await montar(tester);
    chat.cargar(
      Conversacion(
        id: 'X',
        titulo: 'Vieja',
        mensajes: const [],
        creadoEn: DateTime(2026),
        ultimaActividad: DateTime(2026),
      ),
    );
    chat.preguntar('Pregunta');
    chat.marcarEliminada('X');
    guardar();
    await tester.pump();
    expect(repositorio.actualizadas.containsKey('X'), isFalse);

    chat.desmarcarEliminada('X');
    guardar();
    await tester.pump();
    expect(repositorio.actualizadas['X'], ['Pregunta']);
  });

  testWidgets('la generación cambia al abrir otra conversación', (
    tester,
  ) async {
    await montar(tester);
    final antes = chat.generacion;
    chat.preguntar('Hola');
    expect(chat.generacion, antes);
    chat.cargar(
      Conversacion(
        id: 'c1',
        titulo: 'Otra',
        mensajes: const [],
        creadoEn: DateTime(2026),
        ultimaActividad: DateTime(2026),
      ),
    );
    expect(chat.generacion, isNot(antes));
  });
}
