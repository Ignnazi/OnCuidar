import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/ciclo_de_vida_paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/notificaciones/silencio_avisos.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _api = ClienteApi(urlBase: 'http://localhost', obtenerToken: () => null);
final _bd = BaseDatosSegura(
  api: _api,
  uidPrueba: 'u1',
  cifrado: ServicioCifrado(
    api: _api,
    almacen: AlmacenSecretoMemoria(),
    clavePrueba: base64.encode(List<int>.filled(32, 1)),
  ),
);

/// Anota en orden lo que pasa para revisar la secuencia
final _pasos = <String>[];

class PacientesFalsos extends RepositorioPacientes {
  PacientesFalsos() : super(_bd);

  List<Paciente> activos = [];

  @override
  Future<void> archivarPaciente(String idPaciente) async =>
      _pasos.add('archivar $idPaciente');

  @override
  Future<void> desarchivarPaciente(String idPaciente) async =>
      _pasos.add('restaurar $idPaciente');

  @override
  Future<void> eliminarPaciente(String idPaciente) async =>
      _pasos.add('eliminar $idPaciente');

  @override
  Stream<List<Paciente>> pacientesEnTiempoReal() => Stream.value(activos);
}

class RecordatoriosFalsos extends RepositorioRecordatorios {
  RecordatoriosFalsos() : super(_bd);

  List<Recordatorio> lista = [];

  @override
  Future<void> cancelarNotificacionesPaciente(
    String idPaciente,
    ServicioNotificaciones notif,
  ) async => _pasos.add('cancelar avisos $idPaciente');

  @override
  Stream<List<Recordatorio>> recordatoriosEnTiempoReal(String idPaciente) =>
      Stream.value(lista);
}

class NotificacionesFalsas implements ServicioNotificaciones {
  final programados = <String>[];

  @override
  Future<void> cancelarTodas() async => programados.clear();

  @override
  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fechaHora,
    List<String>? diasRepeticion,
    bool mensual = false,
    String? idPaciente,
  }) async => programados.add(cuerpo);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Recordatorio _recordatorio(
  String titulo, {
  required DateTime fechaHora,
  bool activo = true,
  List<String> dias = const [],
}) => Recordatorio(
  id: titulo,
  pacienteId: 'p1',
  tipo: 'medicamento',
  titulo: titulo,
  fechaHora: fechaHora,
  diasRepeticion: dias,
  activo: activo,
  creadoEn: DateTime(2026),
);

void main() {
  late PacientesFalsos pacientes;
  late RecordatoriosFalsos recordatorios;
  late NotificacionesFalsas notificaciones;
  late CicloDeVidaPaciente ciclo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _pasos.clear();
    pacientes = PacientesFalsos();
    recordatorios = RecordatoriosFalsos();
    notificaciones = NotificacionesFalsas();
    ciclo = CicloDeVidaPaciente(
      pacientes: pacientes,
      recordatorios: recordatorios,
      notificaciones: notificaciones,
    );
  });

  test('archivar un paciente apaga sus avisos', () async {
    await ciclo.archivar('p1');
    expect(_pasos, ['archivar p1', 'cancelar avisos p1']);
  });

  test(
    'eliminar apaga los avisos antes de borrar y quita su silencio',
    () async {
      await SilencioAvisos.fijarPaciente('p1', true);
      await ciclo.eliminar('p1');
      expect(_pasos, ['cancelar avisos p1', 'eliminar p1']);
      expect(await SilencioAvisos.pacienteSilenciado('p1'), isFalse);
    },
  );

  test(
    'restaurar vuelve a programar solo los avisos que corresponden',
    () async {
      pacientes.activos = [
        Paciente(id: 'p1', nombreCompleto: 'Tomás', creadoEn: DateTime(2026)),
      ];
      final futuro = DateTime.now().add(const Duration(days: 1));
      final pasado = DateTime.now().subtract(const Duration(days: 1));
      recordatorios.lista = [
        _recordatorio('Activo', fechaHora: futuro),
        _recordatorio('Pausado', fechaHora: futuro, activo: false),
        _recordatorio('Ya pasó', fechaHora: pasado),
        _recordatorio('Semanal', fechaHora: pasado, dias: ['lunes']),
      ];

      await ciclo.desarchivar('p1');
      expect(_pasos, ['restaurar p1']);
      expect(notificaciones.programados, ['Activo', 'Semanal']);
    },
  );
}
