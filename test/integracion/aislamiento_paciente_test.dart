import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-aislamiento';

void main() {
  late FakeFirebaseFirestore firestore;
  late BaseDatosSegura base;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    await cifrado.fijarClave(_uid, _clavePrueba);
    firestore = FakeFirebaseFirestore();
    base = BaseDatosSegura(base: firestore, uidPrueba: _uid, cifrado: cifrado);
  });

  group('Paciente declarado en el documento', () {
    test(
      'un recordatorio creado guarda pacienteId igual al de su ruta',
      () async {
        final ahora = DateTime.now();
        final id = await RepositorioRecordatorios(base).agregarRecordatorio(
          'pacienteA',
          Recordatorio(
            id: '',
            pacienteId: 'pacienteA',
            tipo: 'medicamento',
            titulo: 'Dar paracetamol',
            fechaHora: ahora,
            diasRepeticion: const [],
            activo: true,
            creadoEn: ahora,
          ),
        );
        final doc = await firestore
            .collection('usuarios')
            .doc(_uid)
            .collection('pacientes')
            .doc('pacienteA')
            .collection('recordatorios')
            .doc(id)
            .get();
        expect(doc.data()?['pacienteId'], 'pacienteA');
      },
    );
  });
}
