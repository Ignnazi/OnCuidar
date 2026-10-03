import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/recordatorio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-aislamiento';

void main() {
  late FakeFirebaseFirestore firestore;
  late ServicioBaseDatos base;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    await cifrado.fijarClave(_uid, _clavePrueba);
    firestore = FakeFirebaseFirestore();
    base = ServicioBaseDatos(
      base: firestore,
      uidPrueba: _uid,
      cifrado: cifrado,
    );
  });

  group('Paciente declarado en el documento', () {
    test(
      'un recordatorio creado guarda pacienteId igual al de su ruta',
      () async {
        final ahora = DateTime.now();
        final id = await base.agregarRecordatorio(
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
            .collection('users')
            .doc(_uid)
            .collection('patients')
            .doc('pacienteA')
            .collection('recordatorios')
            .doc(id)
            .get();
        expect(doc.data()?['pacienteId'], 'pacienteA');
      },
    );
  });
}
