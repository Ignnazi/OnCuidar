import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../ayudas/recordatorios.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('RepositorioRecordatorios', () {
    test('agregarRecordatorio cifra título y descripción', () async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final fecha = DateTime.now();
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'medicamento',
          titulo: 'Dar paracetamol',
          descripcion: '500 mg con agua',
          fechaHora: fecha,
          diasRepeticion: const ['lun', 'mie'],
          activo: true,
          creadoEn: fecha,
        ),
      );
      final datos = await docRecordatorio(firestore, idPaciente, id);
      expect(datos, isNotNull);
      expect(datos!.containsKey('titulo'), isFalse);
      expect(datos.containsKey('descripcion'), isFalse);
      expect(datos['titulo_cifrado'], isA<String>());
      expect(datos['titulo_cifrado'], isNot('Dar paracetamol'));
      expect(datos['descripcion_cifrada'], isA<String>());
      expect(datos.containsKey('tipo'), isFalse);
      expect(datos.containsKey('fechaHora'), isFalse);
      expect(datos.containsKey('diasRepeticion'), isFalse);
      expect(datos['version_encriptacion'], 3);
      final payload = await payloadRecordatorio(firestore, idPaciente, id);
      expect(payload['tipo'], 'medicamento');
      expect(payload['diasRepeticion'], ['lun', 'mie']);
    });

    test('el stream devuelve los recordatorios descifrados', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final fecha = DateTime.now();
      await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'cita',
          titulo: 'Control médico',
          fechaHora: fecha,
          activo: true,
          creadoEn: fecha,
        ),
      );
      final recordatorios = await RepositorioRecordatorios(
        base,
      ).recordatoriosEnTiempoReal(idPaciente).first;
      expect(recordatorios, hasLength(1));
      expect(recordatorios.first.titulo, 'Control médico');
      expect(recordatorios.first.tipo, 'cita');
    });

    test('la recurrencia mensual se persiste y se descifra', () async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final fecha = DateTime.now();
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        Recordatorio(
          id: '',
          pacienteId: idPaciente,
          tipo: 'medicamento',
          titulo: 'Vitamina mensual',
          fechaHora: fecha,
          activo: true,
          creadoEn: fecha,
          recurrencia: 'mensual',
        ),
      );
      final datos = await docRecordatorio(firestore, idPaciente, id);
      final payload = await payloadRecordatorio(firestore, idPaciente, id);
      expect(payload['recurrencia'], 'mensual');
      expect(datos!.containsKey('completadoEn'), isFalse);

      var recordatorios = await RepositorioRecordatorios(
        base,
      ).recordatoriosEnTiempoReal(idPaciente).first;
      expect(recordatorios.single.esMensual, isTrue);

      await RepositorioRecordatorios(
        base,
      ).actualizarRecordatorio(idPaciente, id, recurrencia: '');
      recordatorios = await RepositorioRecordatorios(
        base,
      ).recordatoriosEnTiempoReal(idPaciente).first;
      expect(recordatorios.single.recurrencia, isNull);
    });
  });

  group('RepositorioRecordatorios — asignación', () {
    test('la asignación viaja dentro del payload cifrado', () async {
      final (base, firestore) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, asignadoA: Recordatorio.asignadoACuidador),
      );
      final doc = await firestore
          .collection('usuarios')
          .doc(uidRecordatorios)
          .collection('pacientes')
          .doc(idPaciente)
          .collection('recordatorios')
          .doc(id)
          .get();
      final datos = doc.data()!;
      expect(datos.containsKey('asignadoA'), isFalse);
      expect(datos['pacienteId'], idPaciente);
      final cifrado = ServicioCifrado(clavePrueba: clavePruebaRecordatorios);
      await cifrado.fijarClave(uidRecordatorios, clavePruebaRecordatorios);
      final payload =
          jsonDecode(
                await cifrado.descifrar(
                  uidRecordatorios,
                  datos['datos_cifrados'] as String,
                ),
              )
              as Map<String, dynamic>;
      expect(payload['asignadoA'], 'cuidador');

      final leidos = await RepositorioRecordatorios(
        base,
      ).recordatoriosEnTiempoReal(idPaciente).first;
      expect(leidos.single.asignadoA, Recordatorio.asignadoACuidador);
    });

    test('actualizar la asignación conserva el resto del payload', () async {
      final (base, _) = await baseRecordatorios();
      final idPaciente = await crearPacienteRecordatorios(base);
      final fecha = DateTime.now().add(const Duration(days: 3));
      final id = await RepositorioRecordatorios(base).agregarRecordatorio(
        idPaciente,
        recordatorioDe(idPaciente, fechaHora: fecha, dias: const ['lun']),
      );
      await RepositorioRecordatorios(base).actualizarRecordatorio(
        idPaciente,
        id,
        asignadoA: Recordatorio.asignadoACuidador,
      );
      final r = (await RepositorioRecordatorios(
        base,
      ).recordatoriosEnTiempoReal(idPaciente).first).single;
      expect(r.asignadoA, 'cuidador');
      expect(r.diasRepeticion, ['lun']);
      expect(r.tipo, 'medicamento');
    });
  });
}
