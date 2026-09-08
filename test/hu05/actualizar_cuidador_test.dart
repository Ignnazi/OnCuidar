import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid-test';

void main() {
  test('actualizarCuidador reemplaza campos cifrados y devuelve datos nuevos',
      () async {
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    await cifrado.fijarClave(_uid, _clavePrueba);
    final base = ServicioBaseDatos(
      base: FakeFirebaseFirestore(),
      uidPrueba: _uid,
      cifrado: cifrado,
    );
    await base.crearCuidador({
      'displayName': 'Ana Torres',
      'email': 'ana@correo.cl',
      'phone': '+56 9 1111 1111',
      'relationship': 'Madre',
    });

    await base.actualizarCuidador(
      nombre: 'Ana María Torres',
      telefono: '+56 9 2222 2222',
      relacion: 'Hija',
    );

    final datos = await base.obtenerCuidador();
    expect(datos['nombre'], 'Ana María Torres');
    expect(datos['telefono'], '+56 9 2222 2222');
    expect(datos['relacion'], 'Hija');
    expect(datos['email'], 'ana@correo.cl');
  });

  test('actualizarCuidador con correo respaldo guarda hash del correo',
      () async {
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    await cifrado.fijarClave(_uid, _clavePrueba);
    final fake = FakeFirebaseFirestore();
    final base = ServicioBaseDatos(
      base: fake,
      uidPrueba: _uid,
      cifrado: cifrado,
    );
    await base.crearCuidador({
      'displayName': 'Ana Torres',
      'email': 'ana@correo.cl',
    });

    await base.actualizarCuidador(correoRespaldo: 'respaldo@correo.cl');

    final doc = await fake.collection('users').doc(_uid).get();
    final datos = doc.data()!;
    // El hash debe estar presente y NO ser el correo en texto plano.
    expect(datos['correo_respaldo_hash'], isNotNull);
    expect(datos['correo_respaldo_hash'], isNot('respaldo@correo.cl'));
    expect(datos['correo_respaldo_hash'], isA<String>());
  });

  test('actualizarCuidador con campos vacios no rompe y conserva lo previo',
      () async {
    final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
    await cifrado.fijarClave(_uid, _clavePrueba);
    final base = ServicioBaseDatos(
      base: FakeFirebaseFirestore(),
      uidPrueba: _uid,
      cifrado: cifrado,
    );
    await base.crearCuidador({
      'displayName': 'Ana Torres',
      'email': 'ana@correo.cl',
      'phone': '+56 9 1111 1111',
      'relationship': 'Madre',
    });

    // Solo enviamos correo respaldo; el resto debe quedar intacto.
    await base.actualizarCuidador(correoRespaldo: '  respaldo@correo.cl  ');

    final datos = await base.obtenerCuidador();
    expect(datos['nombre'], 'Ana Torres');
    expect(datos['telefono'], '+56 9 1111 1111');
    expect(datos['relacion'], 'Madre');
  });
}