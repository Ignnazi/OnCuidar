import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/notificaciones/servicio_notificaciones.dart';
import 'package:oncuidar/nucleo/notificaciones/silencio_avisos.dart';

const clavePruebaRecordatorios = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const uidRecordatorios = 'uid-recordatorios';

class NotificacionesFalsas implements ServicioNotificaciones {
  int permisoSolicitado = 0;
  int canceladasTodas = 0;
  final programados = <Map<String, dynamic>>[];
  final cancelados = <int>[];
  String? payloadLanzamiento;

  @override
  void Function(String? payload)? alTocar;

  @override
  Future<String?> consumirPayloadLanzamiento() async {
    final payload = payloadLanzamiento;
    payloadLanzamiento = null;
    return payload;
  }

  @override
  Future<void> inicializar() async {}

  @override
  Future<bool> solicitarPermiso() async {
    permisoSolicitado++;
    return true;
  }

  @override
  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fechaHora,
    List<String>? diasRepeticion,
    bool mensual = false,
    String? idPaciente,
  }) async {
    if (await SilencioAvisos.silenciado(idPaciente: idPaciente)) {
      cancelados.add(id);
      return;
    }
    programados.add({
      'idPaciente': idPaciente,
      'id': id,
      'titulo': titulo,
      'cuerpo': cuerpo,
      'fechaHora': fechaHora,
      'dias': List<String>.from(diasRepeticion ?? const []),
      'mensual': mensual,
    });
  }

  @override
  Future<void> cancelar(int id) async => cancelados.add(id);

  @override
  Future<void> cancelarTodas() async => canceladasTodas++;
}

Future<(BaseDatosSegura, FakeFirebaseFirestore)> baseRecordatorios() async {
  final cifrado = ServicioCifrado(clavePrueba: clavePruebaRecordatorios);
  await cifrado.fijarClave(uidRecordatorios, clavePruebaRecordatorios);
  final firestore = FakeFirebaseFirestore();
  final base = BaseDatosSegura(
    base: firestore,
    uidPrueba: uidRecordatorios,
    cifrado: cifrado,
  );
  await RepositorioCuidador(base).crearCuidador({
    'nombre': 'Ana Torres',
    'correo': 'ana@correo.cl',
    'telefono': '+56 9 1111 1111',
    'relacion': 'Madre',
    'direccion': 'Av. Siempre Viva 742',
  });
  return (base, firestore);
}

Future<String> crearPacienteRecordatorios(
  BaseDatosSegura base, {
  String nombre = 'Paciente Test',
}) {
  return RepositorioPacientes(base).crearPaciente(
    Paciente(id: 'auto', nombreCompleto: nombre, creadoEn: DateTime.now()),
  );
}

Recordatorio recordatorioDe(
  String idPaciente, {
  String titulo = 'Dar paracetamol',
  String? descripcion,
  DateTime? fechaHora,
  List<String> dias = const [],
  String? recurrencia,
  String asignadoA = Recordatorio.asignadoAPaciente,
  bool activo = true,
}) {
  final fecha = fechaHora ?? DateTime.now().add(const Duration(days: 2));
  return Recordatorio(
    id: '',
    pacienteId: idPaciente,
    tipo: 'medicamento',
    titulo: titulo,
    descripcion: descripcion,
    fechaHora: fecha,
    diasRepeticion: dias,
    recurrencia: recurrencia,
    asignadoA: asignadoA,
    activo: activo,
    creadoEn: fecha,
  );
}
