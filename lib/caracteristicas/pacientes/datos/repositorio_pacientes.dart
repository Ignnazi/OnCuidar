import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';

class RepositorioPacientes {
  RepositorioPacientes(this.bd);

  final BaseDatosSegura bd;

  Future<String> crearPaciente(Paciente paciente) async {
    final ref = bd.docUsuario.collection('pacientes').doc();
    final datos = await _cifrarPaciente(paciente);
    await bd.sinEsperarSinRed(() => ref.set(datos, SetOptions(merge: true)));
    return ref.id;
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
      plano['maximo_registros_dia'] = datos['maximo_registros_dia'];
    }
    if (plano.isEmpty) return;
    await bd.docUsuario
        .collection('pacientes')
        .doc(idPaciente)
        .set(plano, SetOptions(merge: true));
  }

  Future<void> archivarPaciente(String idPaciente) async {
    await bd.sinEsperarSinRed(
      () => bd.docUsuario.collection('pacientes').doc(idPaciente).set({
        'archivado': true,
      }, SetOptions(merge: true)),
    );
  }

  /// Restaura un paciente archivado.
  Future<void> desarchivarPaciente(String idPaciente) async {
    await bd.sinEsperarSinRed(
      () => bd.docUsuario.collection('pacientes').doc(idPaciente).set({
        'archivado': false,
      }, SetOptions(merge: true)),
    );
  }

  Future<void> eliminarPaciente(String idPaciente) async {
    final cola = bd.cola;
    if (cola != null) await cola.quitarDePaciente(bd.uid, idPaciente);
    final docPaciente = bd.docUsuario.collection('pacientes').doc(idPaciente);
    for (final sub in subcoleccionesPaciente) {
      await bd.borrarColeccionEnLotes(docPaciente.collection(sub));
    }
    await bd.confirmarBorrado(docPaciente.delete());
  }

  static const subcoleccionesPaciente = ['registrosClinicos', 'recordatorios'];

  Stream<List<Paciente>> pacientesArchivadosEnTiempoReal() {
    return bd.docUsuario
        .collection('pacientes')
        .snapshots()
        .asyncMap(
          (snap) => Future.wait(
            snap.docs
                .where((d) => d.data()['archivado'] == true)
                .map((d) => _descifrarPaciente(d.id, d.data())),
          ),
        );
  }

  Stream<List<Paciente>> pacientesEnTiempoReal() {
    return bd.docUsuario
        .collection('pacientes')
        .snapshots()
        .asyncMap(
          (snap) => Future.wait(
            snap.docs
                .where((d) => d.data()['archivado'] != true)
                .map((d) => _descifrarPaciente(d.id, d.data())),
          ),
        );
  }

  Future<Map<String, dynamic>> _cifrarPaciente(Paciente p) async {
    final data = <String, dynamic>{
      'notificaciones_activas': true,
      'maximo_registros_dia': 3,
      'creadoEn': FieldValue.serverTimestamp(),
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
    data['version_encriptacion'] = 2;
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
      creadoEn: (datos['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maximoRegistrosDia: (datos['maximo_registros_dia'] as num?)?.toInt() ?? 3,
    );
  }
}
