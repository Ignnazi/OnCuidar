import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/recordatorios/datos/repositorio_recordatorios.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/recordatorios.dart';

RegistroClinico _registro(String idPaciente, String id) {
  final ahora = DateTime.now();
  return RegistroClinico(
    id: id,
    pacienteId: idPaciente,
    fecha: ahora,
    creadoEn: ahora,
    tipoRegistro: 'programado',
    sintomas: const [],
    nivelAlerta: NivelAlerta.normal,
  );
}

Future<int> _cantidad(
  FakeFirebaseFirestore firestore,
  String idPaciente,
  String subcoleccion,
) async {
  final snap = await firestore
      .collection('usuarios')
      .doc(uidRecordatorios)
      .collection('pacientes')
      .doc(idPaciente)
      .collection(subcoleccion)
      .get();
  return snap.docs.length;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('eliminar un paciente deja vacías sus subcolecciones', () async {
    final (base, firestore) = await baseRecordatorios();
    final pacientes = RepositorioPacientes(base);
    final registros = RepositorioRegistrosClinicos(base);
    final recordatorios = RepositorioRecordatorios(base);
    final idA = await crearPacienteRecordatorios(base, nombre: 'Paciente A');
    final idB = await crearPacienteRecordatorios(base, nombre: 'Paciente B');
    for (final id in [idA, idB]) {
      await registros.guardarRegistroClinico(id, _registro(id, 'r1-$id'));
      await registros.guardarRegistroClinico(id, _registro(id, 'r2-$id'));
      await recordatorios.agregarRecordatorio(id, recordatorioDe(id));
    }
    expect(await _cantidad(firestore, idA, 'registrosClinicos'), 2);
    expect(await _cantidad(firestore, idA, 'recordatorios'), 1);

    await pacientes.eliminarPaciente(idA);

    expect(await _cantidad(firestore, idA, 'registrosClinicos'), 0);
    expect(await _cantidad(firestore, idA, 'recordatorios'), 0);
    final docA = await firestore
        .collection('usuarios')
        .doc(uidRecordatorios)
        .collection('pacientes')
        .doc(idA)
        .get();
    expect(docA.exists, isFalse);
    expect(await _cantidad(firestore, idB, 'registrosClinicos'), 2);
    expect(await _cantidad(firestore, idB, 'recordatorios'), 1);
  });

  test('las subcolecciones que se borran son registros y recordatorios', () {
    expect(
      RepositorioPacientes.subcoleccionesPaciente,
      containsAll(['registrosClinicos', 'recordatorios']),
    );
  });
}
