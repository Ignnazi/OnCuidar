import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/core/servicios/servicio_base_datos.dart';
import 'package:oncuidar/core/servicios/servicio_cifrado.dart';
import 'package:oncuidar/modelos/paciente.dart';

const _clavePrueba = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';

void main() {
  group('ServicioCifrado', () {
    test('cifrar y descifrar redondear texto', () async {
      final servicio = ServicioCifrado(clavePrueba: _clavePrueba);
      await servicio.restaurarClave('uid-1');

      final cifrado = await servicio.cifrar('uid-1', 'Ana Torres');
      expect(cifrado, isNot(contains('Ana Torres')));
      expect(cifrado.split('.'), hasLength(3));

      final claro = await servicio.descifrar('uid-1', cifrado);
      expect(claro, 'Ana Torres');
    });

    test('clave invalida lanza FormatException', () async {
      final servicio = ServicioCifrado(clavePrueba: _clavePrueba);
      expect(
        () => servicio.fijarClave('uid-1', 'corta'),
        throwsA(isA<FormatException>()),
      );
    });

    test('bloquear impide cifrar', () async {
      final servicio = ServicioCifrado(clavePrueba: _clavePrueba);
      await servicio.restaurarClave('uid-1');
      servicio.bloquear();

      expect(
        () => servicio.cifrar('uid-1', 'secreto'),
        throwsA(isA<StateError>()),
      );
    });

    test('clave por uid distinto lanza StateError', () async {
      final servicio = ServicioCifrado(clavePrueba: _clavePrueba);
      await servicio.restaurarClave('uid-1');

      expect(
        () => servicio.cifrar('uid-2', 'secreto'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ServicioBaseDatos', () {
    late FakeFirebaseFirestore base;
    late ServicioCifrado cifrado;
    late ServicioBaseDatos servicio;

    setUp(() {
      base = FakeFirebaseFirestore();
      cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      servicio = ServicioBaseDatos(
        base: base,
        uidPrueba: 'uid-1',
        cifrado: cifrado,
      );
    });

    Future<Paciente> paciente(String nombre) async {
      await cifrado.restaurarClave('uid-1');
      return Paciente(
        id: 'auto',
        fullName: nombre,
        rut: '12.345.678-9',
        age: 72,
        diagnosis: 'Cancer de mama',
        tratamientoFase: 'Tratamiento',
        centroSaludNombre: 'Hospital Central',
        centroSaludTelefono: '+56 9 1234 5678',
        contactoEmergenciaNombre: 'Carlos Vejar',
        contactoEmergenciaTelefono: '+56 9 8765 4321',
        createdAt: DateTime.now(),
      );
    }

    test('crearPaciente guarda campos sensibles cifrados', () async {
      final id = await servicio.crearPaciente(await paciente('Ana Torres'));

      final doc = await base.collection('users').doc('uid-1').collection('patients').doc(id).get();
      final datos = doc.data()!;

      expect(datos.containsKey('nombre_cifrado'), isTrue);
      expect(datos['nombre_cifrado'], isNot('Ana Torres'));
      expect(datos.containsKey('rut_cifrado'), isTrue);
      expect(datos['rut_cifrado'], isNot('12.345.678-9'));
      expect(datos.containsKey('edad_cifrada'), isTrue);
      expect(datos['edad_cifrada'], isNot('72'));
      expect(datos.containsKey('diagnostico_cifrado'), isTrue);
      expect(datos.containsKey('fase_tratamiento_cifrado'), isTrue);
      expect(datos.containsKey('contacto_emergencia_nombre_cifrado'), isTrue);
      expect(datos.containsKey('centro_salud_telefono_cifrado'), isTrue);
      // Campos sensibles no quedan en texto plano
      expect(datos.containsKey('fullName'), isFalse);
      expect(datos.containsKey('diagnosis'), isFalse);
      expect(datos.containsKey('healthCenter'), isFalse);
      expect(datos.containsKey('rut'), isFalse);
      expect(datos.containsKey('edad'), isFalse);
    });

    test('obtenerPacientes descifra de vuelta', () async {
      final id = await servicio.crearPaciente(await paciente('Ana Torres'));

      final pacientes = await servicio.obtenerPacientes();
      expect(pacientes, hasLength(1));
      expect(pacientes.first.id, id);
      expect(pacientes.first.fullName, 'Ana Torres');
      expect(pacientes.first.rut, '12.345.678-9');
      expect(pacientes.first.age, 72);
      expect(pacientes.first.diagnosis, 'Cancer de mama');
      expect(pacientes.first.tratamientoFase, 'Tratamiento');
      expect(pacientes.first.centroSaludTelefono, '+56 9 1234 5678');
    });

    test('crearCuidador guarda email en texto plano y cifra demas', () async {
      await cifrado.restaurarClave('uid-1');
      await servicio.crearCuidador({
        'displayName': 'Ana Torres',
        'email': 'ana@correo.cl',
        'correo_respaldo_hash': 'hash-respaldo-abc123',
        'phone': '+56 9 1111 2222',
        'relationship': 'Madre',
      });

      final datos = (await base.collection('users').doc('uid-1').get()).data()!;
      expect(datos['email'], 'ana@correo.cl');
      expect(datos['correo_respaldo_hash'], 'hash-respaldo-abc123');
      expect(datos['nombre_cifrado'], isNot('Ana Torres'));
      expect(datos['telefono_cifrado'], isNot('+56 9 1111 2222'));
      expect(datos['relacion_cifrada'], isNot('Madre'));
      expect(datos.containsKey('displayName'), isFalse);
      expect(datos.containsKey('phone'), isFalse);
      expect(datos.containsKey('relationship'), isFalse);
    });
  });
}