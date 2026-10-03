import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-respaldo';

void main() {
  late FakeFirebaseFirestore firestore;
  late RepositorioCuidador repositorio;
  late List<String> registrados;

  Future<Map<String, dynamic>?> docCuidador() async =>
      (await firestore.collection('usuarios').doc(_uid).get()).data();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    await cifrado.fijarClave(_uid, _clavePrueba);
    firestore = FakeFirebaseFirestore();
    repositorio = RepositorioCuidador(
      BaseDatosSegura(
        base: firestore,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: _uid, email: 'cuidador@test.cl'),
        ),
        cifrado: cifrado,
      ),
    );
    registrados = [];
  });

  test(
    'si el servidor falla deja la marca pendiente y devuelve false',
    () async {
      repositorio.registrarCorreoRespaldoServidor = (_) async =>
          throw Exception('sin conexión');

      final confirmado = await repositorio.cambiarCorreoRespaldo(
        contrasena: 'clave-valida',
        nuevoCorreo: 'Respaldo@Test.cl',
      );

      expect(confirmado, isFalse);
      final datos = await docCuidador();
      expect(datos?['respaldo_pendiente_servidor'], isTrue);
      expect(datos?['correo_respaldo_cifrado'], isNotNull);
      expect(datos?.containsKey('correo_respaldo_hash'), isFalse);
    },
  );

  test('reintentar registra el correo normalizado y limpia la marca', () async {
    repositorio.registrarCorreoRespaldoServidor = (_) async =>
        throw Exception('sin conexión');
    await repositorio.cambiarCorreoRespaldo(
      contrasena: 'clave-valida',
      nuevoCorreo: 'Respaldo@Test.cl',
    );

    repositorio.registrarCorreoRespaldoServidor = (correo) async =>
        registrados.add(correo);
    final resuelto = await repositorio.reintentarRegistroRespaldo();

    expect(resuelto, isTrue);
    expect(registrados, ['respaldo@test.cl']);
    expect((await docCuidador())?['respaldo_pendiente_servidor'], isNull);
  });

  test('sin marca pendiente el reintento no llama al servidor', () async {
    repositorio.registrarCorreoRespaldoServidor = (correo) async =>
        registrados.add(correo);

    expect(await repositorio.reintentarRegistroRespaldo(), isTrue);
    expect(registrados, isEmpty);
  });
}
