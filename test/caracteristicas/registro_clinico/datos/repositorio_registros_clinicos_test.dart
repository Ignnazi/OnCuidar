import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ayudas/offline.dart';
import '../../../ayudas/recordatorios.dart';

RegistroClinico _registro(String idPaciente, int minuto) {
  final momento = DateTime(2026, 10, 1, 8).add(Duration(minutes: minuto));
  return RegistroClinico(
    id: 'r$minuto',
    pacienteId: idPaciente,
    fecha: momento,
    creadoEn: momento,
    tipoRegistro: 'programado',
    observaciones: 'Registro $minuto',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin conexión se ven los 50 registros más recientes', () async {
    final (enLinea, firestore) = await baseRecordatorios();
    final idPaciente = await crearPacienteRecordatorios(enLinea);
    final guardar = RepositorioRegistrosClinicos(enLinea);
    for (var i = 0; i < 52; i++) {
      await guardar.guardarRegistroClinico(
        idPaciente,
        _registro(idPaciente, i),
      );
    }

    final cifrado = ServicioCifrado(clavePrueba: clavePruebaRecordatorios);
    await cifrado.fijarClave(uidRecordatorios, clavePruebaRecordatorios);
    final sinRed = BaseDatosSegura(
      base: firestore,
      uidPrueba: uidRecordatorios,
      cifrado: cifrado,
      cola: ColaEscrituras(),
      conectividad: ConectividadFalsa(enLinea: false),
    );
    final leidos = await RepositorioRegistrosClinicos(
      sinRed,
    ).registrosClinicosEnTiempoReal(idPaciente).first;

    expect(leidos, hasLength(50));
    expect(leidos.first.id, 'r51', reason: 'primero el más reciente');
    expect(leidos.last.id, 'r2');
    expect(leidos.first.observaciones, 'Registro 51');
  });
}
