import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/datos/rutas_api.dart';
import 'package:oncuidar/nucleo/sincronizacion/cola_escrituras.dart';
import 'package:uuid/uuid.dart';

class RepositorioPacientes {
  RepositorioPacientes(this.bd);

  final BaseDatosSegura bd;

  Future<String> crearPaciente(Paciente paciente) async {
    final id = const Uuid().v4();
    final datos = await _cifrarPaciente(paciente);
    await bd.escribir(
      RutasApi.paciente(id),
      datos,
      operacion: OperacionPendiente.guardar,
      idPaciente: id,
    );
    return id;
  }

  Future<void> actualizarPaciente(
    String idPaciente,
    Map<String, dynamic> datos,
  ) async {
    final plano = <String, dynamic>{};

    Future<void> campo({
      required String claveFormulario,
      required dynamic valor,
      required String clave,
    }) async {
      if (!datos.containsKey(claveFormulario)) return;
      final texto = valor?.toString();
      await bd.reemplazarPorCifrado(plano, plano: texto, cifrado: clave);
    }

    await campo(
      claveFormulario: 'nombreCompleto',
      valor: datos['nombreCompleto'],
      clave: 'nombre_cifrado',
    );
    await campo(
      claveFormulario: 'rut',
      valor: datos['rut'],
      clave: 'rut_cifrado',
    );
    await campo(
      claveFormulario: 'edad',
      valor: datos['edad'],
      clave: 'edad_cifrada',
    );
    await campo(
      claveFormulario: 'diagnostico',
      valor: datos['diagnostico'],
      clave: 'diagnostico_cifrado',
    );
    await campo(
      claveFormulario: 'tratamientoFase',
      valor: datos['tratamientoFase'],
      clave: 'fase_tratamiento_cifrado',
    );
    await campo(
      claveFormulario: 'centroSaludNombre',
      valor: datos['centroSaludNombre'],
      clave: 'centro_salud_nombre_cifrado',
    );
    await campo(
      claveFormulario: 'centroSaludDireccion',
      valor: datos['centroSaludDireccion'],
      clave: 'centro_salud_direccion_cifrado',
    );
    await campo(
      claveFormulario: 'centroSaludTelefono',
      valor: datos['centroSaludTelefono'],
      clave: 'centro_salud_telefono_cifrado',
    );
    await campo(
      claveFormulario: 'contactoEmergenciaNombre',
      valor: datos['contactoEmergenciaNombre'],
      clave: 'contacto_emergencia_nombre_cifrado',
    );
    await campo(
      claveFormulario: 'contactoEmergenciaTelefono',
      valor: datos['contactoEmergenciaTelefono'],
      clave: 'contacto_emergencia_telefono_cifrado',
    );
    if (datos['maximo_registros_dia'] is int) {
      plano['maximoRegistrosDia'] = datos['maximo_registros_dia'];
    }
    if (plano.isEmpty) return;
    await bd.escribir(
      RutasApi.paciente(idPaciente),
      plano,
      operacion: OperacionPendiente.fusionar,
      idPaciente: idPaciente,
    );
  }

  Future<void> archivarPaciente(String idPaciente) => bd.escribir(
    RutasApi.paciente(idPaciente),
    {'archivado': true},
    operacion: OperacionPendiente.fusionar,
    idPaciente: idPaciente,
  );

  /// Restaura un paciente archivado.
  Future<void> desarchivarPaciente(String idPaciente) => bd.escribir(
    RutasApi.paciente(idPaciente),
    {'archivado': false},
    operacion: OperacionPendiente.fusionar,
    idPaciente: idPaciente,
  );

  Future<void> eliminarPaciente(String idPaciente) async {
    final cola = bd.cola;
    if (cola != null) await cola.quitarDePaciente(bd.uid, idPaciente);
    await bd.borrar(RutasApi.paciente(idPaciente), idPaciente);
  }

  Stream<List<Paciente>> pacientesArchivadosEnTiempoReal() =>
      _pacientes(archivados: true);

  Stream<List<Paciente>> pacientesEnTiempoReal() =>
      _pacientes(archivados: false);

  Stream<List<Paciente>> _pacientes({required bool archivados}) {
    return bd.flujo<List<Paciente>>(
      RutasApi.pacientes,
      convertir: (json) async {
        final items = [
          for (final e in json as List)
            if (((e as Map)['archivado'] == true) == archivados)
              e.cast<String, dynamic>(),
        ];
        return Future.wait(
          items.map((d) => _descifrarPaciente(d['id'] as String, d)),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _cifrarPaciente(Paciente p) async {
    final data = <String, dynamic>{
      'notificacionesActivas': true,
      'maximoRegistrosDia': 3,
      'creadoEn': DateTime.now().toUtc().toIso8601String(),
    };
    await bd.reemplazarPorCifrado(
      data,
      plano: p.nombreCompleto,
      cifrado: 'nombre_cifrado',
    );
    await bd.reemplazarPorCifrado(data, plano: p.rut, cifrado: 'rut_cifrado');
    await bd.reemplazarPorCifrado(
      data,
      plano: p.edad?.toString(),
      cifrado: 'edad_cifrada',
    );
    await bd.reemplazarPorCifrado(
      data,
      plano: p.diagnostico,
      cifrado: 'diagnostico_cifrado',
    );
    await bd.reemplazarPorCifrado(
      data,
      plano: p.tratamientoFase,
      cifrado: 'fase_tratamiento_cifrado',
    );
    await bd.reemplazarPorCifrado(
      data,
      plano: p.centroSaludNombre,
      cifrado: 'centro_salud_nombre_cifrado',
    );
    await bd.reemplazarPorCifrado(
      data,
      plano: p.centroSaludDireccion,
      cifrado: 'centro_salud_direccion_cifrado',
    );
    await bd.reemplazarPorCifrado(
      data,
      plano: p.centroSaludTelefono,
      cifrado: 'centro_salud_telefono_cifrado',
    );
    await bd.reemplazarPorCifrado(
      data,
      plano: p.contactoEmergenciaNombre,
      cifrado: 'contacto_emergencia_nombre_cifrado',
    );
    await bd.reemplazarPorCifrado(
      data,
      plano: p.contactoEmergenciaTelefono,
      cifrado: 'contacto_emergencia_telefono_cifrado',
    );
    data['versionEncriptacion'] = 2;
    return data;
  }

  Future<Paciente> _descifrarPaciente(
    String id,
    Map<String, dynamic> datos,
  ) async {
    final nombre = await bd.descifrarCampo(datos, 'nombre_cifrado');
    final edad = await bd.descifrarCampo(datos, 'edad_cifrada');
    return Paciente(
      id: id,
      nombreCompleto: nombre ?? '',
      rut: await bd.descifrarCampo(datos, 'rut_cifrado'),
      edad: int.tryParse(edad ?? ''),
      diagnostico: await bd.descifrarCampo(datos, 'diagnostico_cifrado'),
      tratamientoFase: await bd.descifrarCampo(
        datos,
        'fase_tratamiento_cifrado',
      ),
      centroSaludNombre: await bd.descifrarCampo(
        datos,
        'centro_salud_nombre_cifrado',
      ),
      centroSaludDireccion: await bd.descifrarCampo(
        datos,
        'centro_salud_direccion_cifrado',
      ),
      centroSaludTelefono: await bd.descifrarCampo(
        datos,
        'centro_salud_telefono_cifrado',
      ),
      contactoEmergenciaNombre: await bd.descifrarCampo(
        datos,
        'contacto_emergencia_nombre_cifrado',
      ),
      contactoEmergenciaTelefono: await bd.descifrarCampo(
        datos,
        'contacto_emergencia_telefono_cifrado',
      ),
      creadoEn: bd.fechaTolerante(datos['creadoEn']),
      maximoRegistrosDia: (datos['maximoRegistrosDia'] as num?)?.toInt() ?? 3,
    );
  }
}
