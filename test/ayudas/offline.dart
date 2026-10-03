import 'dart:async';

import 'package:oncuidar/nucleo/conectividad/servicio_conectividad.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';

class ConectividadFalsa extends ServicioConectividad {
  ConectividadFalsa({bool enLinea = true}) : _estado = enLinea;

  bool _estado;
  final _controlador = StreamController<bool>.broadcast();

  @override
  Future<bool> estaEnLinea() async => _estado;

  @override
  Stream<bool> enLinea() => _controlador.stream;

  void fijar(bool enLinea) {
    _estado = enLinea;
    _controlador.add(enLinea);
  }
}

Future<void> esperarHasta(Future<bool> Function() condicion) async {
  for (var i = 0; i < 300; i++) {
    if (await condicion()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('La condición no se cumplió a tiempo');
}

EscrituraPendiente escrituraDe({
  String id = 'e1',
  String ruta = 'usuarios/u1/pacientes/p1/recordatorios/c1',
  OperacionPendiente operacion = OperacionPendiente.crear,
  Map<String, dynamic>? datos,
  String pacienteId = 'p1',
  int encoladoEn = 1,
}) => EscrituraPendiente(
  id: id,
  ruta: ruta,
  operacion: operacion,
  datos: datos ?? {'paciente_id': pacienteId, 'titulo_cifrado': 'a.b.c'},
  pacienteId: pacienteId,
  encoladoEn: encoladoEn,
);
