import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/chat/datos/repositorio_conversaciones.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
const _uid = 'uid1';

List<MensajeConversacion> _mensajes() => const [
  MensajeConversacion(texto: 'Mi bebé tiene fiebre', delUsuario: true),
  MensajeConversacion(texto: 'Respuesta', delUsuario: false),
];

Future<(RepositorioConversaciones, FakeFirebaseFirestore)> _base() async {
  final cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
  await cifrado.fijarClave(_uid, _clavePrueba);
  final firestore = FakeFirebaseFirestore();
  final repositorio = RepositorioConversaciones(
    BaseDatosSegura(base: firestore, uidPrueba: _uid, cifrado: cifrado),
  );
  return (repositorio, firestore);
}

void main() {
  group('RepositorioConversaciones', () {
    test('crearConversacion cifra título y mensajes', () async {
      final (repositorio, firestore) = await _base();
      final id = await repositorio.crearConversacion(
        titulo: 'Duda sobre fiebre',
        mensajes: _mensajes(),
      );
      final datos =
          (await firestore
                  .collection('usuarios')
                  .doc(_uid)
                  .collection('conversaciones')
                  .doc(id)
                  .get())
              .data()!;
      expect(datos.containsKey('titulo'), isFalse);
      expect(datos.containsKey('mensajes'), isFalse);
      expect(datos['titulo_cifrado'], isA<String>());
      expect(datos['titulo_cifrado'], isNot('Duda sobre fiebre'));
      expect(datos['mensajes_cifrado'], isA<String>());
      expect(datos['version_encriptacion'], 3);
    });

    test(
      'el stream devuelve descifrado y ordenado por última actividad',
      () async {
        final (repositorio, _) = await _base();
        await repositorio.crearConversacion(
          titulo: 'Duda sobre fiebre',
          mensajes: _mensajes(),
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await repositorio.crearConversacion(
          titulo: 'Duda sobre catéter',
          mensajes: _mensajes(),
        );
        final conversaciones = await repositorio
            .conversacionesEnTiempoReal()
            .first;
        expect(conversaciones, hasLength(2));
        expect(conversaciones.first.titulo, 'Duda sobre catéter');
        expect(
          conversaciones.first.mensajes.first.texto,
          'Mi bebé tiene fiebre',
        );
        expect(conversaciones.first.mensajes.first.delUsuario, isTrue);
        expect(conversaciones.last.titulo, 'Duda sobre fiebre');
      },
    );
  });
}
