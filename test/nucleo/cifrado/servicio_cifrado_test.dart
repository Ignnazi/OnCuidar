import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';

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

  group('Cifrado en los repositorios', () {
    late FakeFirebaseFirestore base;
    late ServicioCifrado cifrado;
    late BaseDatosSegura servicio;

    setUp(() {
      base = FakeFirebaseFirestore();
      cifrado = ServicioCifrado(clavePrueba: _clavePrueba);
      servicio = BaseDatosSegura(
        base: base,
        uidPrueba: 'uid-1',
        cifrado: cifrado,
      );
    });

    Future<Paciente> paciente(String nombre) async {
      await cifrado.restaurarClave('uid-1');
      return Paciente(
        id: 'auto',
        nombreCompleto: nombre,
        rut: '12.345.678-9',
        edad: 72,
        diagnostico: 'Cancer de mama',
        tratamientoFase: 'Tratamiento',
        centroSaludNombre: 'Hospital Central',
        centroSaludTelefono: '+56 9 1234 5678',
        contactoEmergenciaNombre: 'Carlos Vejar',
        contactoEmergenciaTelefono: '+56 9 8765 4321',
        creadoEn: DateTime.now(),
      );
    }

    test('crearPaciente guarda campos sensibles cifrados', () async {
      final id = await RepositorioPacientes(
        servicio,
      ).crearPaciente(await paciente('Ana Torres'));

      final doc = await base
          .collection('usuarios')
          .doc('uid-1')
          .collection('pacientes')
          .doc(id)
          .get();
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
      expect(datos.containsKey('nombreCompleto'), isFalse);
      expect(datos.containsKey('diagnostico'), isFalse);
      expect(datos.containsKey('healthCenter'), isFalse);
      expect(datos.containsKey('rut'), isFalse);
      expect(datos.containsKey('edad'), isFalse);
    });

    test('pacientesEnTiempoReal descifra de vuelta', () async {
      final id = await RepositorioPacientes(
        servicio,
      ).crearPaciente(await paciente('Ana Torres'));

      final pacientes = await RepositorioPacientes(
        servicio,
      ).pacientesEnTiempoReal().first;
      expect(pacientes, hasLength(1));
      expect(pacientes.first.id, id);
      expect(pacientes.first.nombreCompleto, 'Ana Torres');
      expect(pacientes.first.rut, '12.345.678-9');
      expect(pacientes.first.edad, 72);
      expect(pacientes.first.diagnostico, 'Cancer de mama');
      expect(pacientes.first.tratamientoFase, 'Tratamiento');
      expect(pacientes.first.centroSaludTelefono, '+56 9 1234 5678');
    });

    test('crearCuidador guarda correo en texto plano y cifra demas', () async {
      await cifrado.restaurarClave('uid-1');
      await RepositorioCuidador(servicio).crearCuidador({
        'nombre': 'Ana Torres',
        'correo': 'ana@correo.cl',
        'telefono': '+56 9 1111 2222',
        'relacion': 'Madre',
      });

      final datos = (await base.collection('usuarios').doc('uid-1').get())
          .data()!;
      expect(datos['correo'], 'ana@correo.cl');
      expect(
        datos.containsKey('correo_respaldo_hash'),
        isFalse,
        reason: 'el cliente nunca escribe el hash; lo hace el servidor',
      );
      expect(datos['nombre_cifrado'], isNot('Ana Torres'));
      expect(datos['telefono_cifrado'], isNot('+56 9 1111 2222'));
      expect(datos['relacion_cifrada'], isNot('Madre'));
      expect(datos.containsKey('nombre'), isFalse);
      expect(datos.containsKey('telefono'), isFalse);
      expect(datos.containsKey('relacion'), isFalse);
    });
  });
}
