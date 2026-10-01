import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/core/servicios/servicio_notificaciones.dart';
import 'package:oncuidar/modelos/paciente.dart';
import 'package:oncuidar/modelos/recordatorio.dart';

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
  }) async {
    programados.add({
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

Future<(ServicioBaseDatos, FakeFirebaseFirestore)> baseRecordatorios() async {
  final cifrado = ServicioCifrado(clavePrueba: clavePruebaRecordatorios);
  await cifrado.fijarClave(uidRecordatorios, clavePruebaRecordatorios);
  final firestore = FakeFirebaseFirestore();
  final base = ServicioBaseDatos(
    base: firestore,
    uidPrueba: uidRecordatorios,
    cifrado: cifrado,
  );
  await base.crearCuidador({
    'displayName': 'Ana Torres',
    'email': 'ana@correo.cl',
    'phone': '+56 9 1111 1111',
    'relationship': 'Madre',
    'address': 'Av. Siempre Viva 742',
  });
  return (base, firestore);
}

Future<String> crearPacienteRecordatorios(
  ServicioBaseDatos base, {
  String nombre = 'Paciente Test',
}) {
  return base.crearPaciente(
    Paciente(id: 'auto', fullName: nombre, createdAt: DateTime.now()),
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
