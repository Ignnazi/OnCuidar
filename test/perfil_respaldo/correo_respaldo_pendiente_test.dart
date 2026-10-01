import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-respaldo';

void main() {
  late FakeFirebaseFirestore firestore;
  late ServicioBaseDatos base;
  late List<String> registrados;

  Future<Map<String, dynamic>?> docCuidador() async =>
      (await firestore.collection('users').doc(_uid).get()).data();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    await cifrado.fijarClave(_uid, _clavePrueba);
    firestore = FakeFirebaseFirestore();
    base = ServicioBaseDatos(
      base: firestore,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
      ),
      cifrado: cifrado,
    );
    registrados = [];
  });

  test('si el servidor falla deja la marca pendiente y devuelve false', () async {
    base.registrarCorreoRespaldoServidor = (_) async =>
        throw Exception('sin conexión');

    final confirmado = await base.cambiarCorreoRespaldo(
      contrasena: 'clave-valida',
      nuevoCorreo: 'Respaldo@Test.cl',
    );

    expect(confirmado, isFalse);
    final datos = await docCuidador();
    expect(datos?['respaldo_pendiente_servidor'], isTrue);
    expect(datos?['correo_respaldo_cifrado'], isNotNull);
    expect(datos?.containsKey('correo_respaldo_hash'), isFalse);
  });

  test('reintentar registra el correo normalizado y limpia la marca', () async {
    base.registrarCorreoRespaldoServidor = (_) async =>
        throw Exception('sin conexión');
    await base.cambiarCorreoRespaldo(
      contrasena: 'clave-valida',
      nuevoCorreo: 'Respaldo@Test.cl',
    );

    base.registrarCorreoRespaldoServidor = (correo) async =>
        registrados.add(correo);
    final resuelto = await base.reintentarRegistroRespaldo();

    expect(resuelto, isTrue);
    expect(registrados, ['respaldo@test.cl']);
    expect((await docCuidador())?['respaldo_pendiente_servidor'], isNull);
  });

  test('sin marca pendiente el reintento no llama al servidor', () async {
    base.registrarCorreoRespaldoServidor = (correo) async =>
        registrados.add(correo);

    expect(await base.reintentarRegistroRespaldo(), isTrue);
    expect(registrados, isEmpty);
  });
}
