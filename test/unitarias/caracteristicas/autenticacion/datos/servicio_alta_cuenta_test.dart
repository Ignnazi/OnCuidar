import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/servicio_alta_cuenta.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';
import 'package:oncuidar/nucleo/datos/base_datos_segura.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';

final _api = ClienteApi(urlBase: 'http://localhost', obtenerToken: () => null);
final _cifrado = ServicioCifrado(
  api: _api,
  almacen: AlmacenSecretoMemoria(),
  clavePrueba: base64.encode(List<int>.filled(32, 7)),
);
final _bd = BaseDatosSegura(api: _api, cifrado: _cifrado);

class SesionFalsa extends ServicioSesion {
  SesionFalsa() : super(api: _api, almacen: AlmacenSecretoMemoria());

  ExcepcionSesion? errorAlRegistrar;
  bool cuentaEliminada = false;

  @override
  Future<SesionUsuario> registrar(String correo, String contrasena) async {
    if (errorAlRegistrar != null) throw errorAlRegistrar!;
    return SesionUsuario(uid: 'u1', correo: correo, token: 't');
  }

  @override
  Future<void> eliminarCuenta() async => cuentaEliminada = true;
}

class PacientesFalsos extends RepositorioPacientes {
  PacientesFalsos() : super(_bd);

  bool falla = false;
  final creados = <String>[];

  @override
  Future<String> crearPaciente(Paciente paciente) async {
    if (falla) throw const ExcepcionApi.sinRed();
    creados.add(paciente.id);
    return paciente.id;
  }
}

class CuidadorFalso extends RepositorioCuidador {
  CuidadorFalso() : super(_bd);

  @override
  Future<void> crearCuidador(Map<String, dynamic> datos) async {}
}

final _datos = DatosRegistro(
  nombre: 'Ana Pérez',
  correo: 'ana@prueba.cl',
  telefono: '+56911111111',
  contrasena: 'secreta1',
  paciente: Paciente(
    id: 'p1',
    nombreCompleto: 'Tomás',
    creadoEn: DateTime(2026),
  ),
);

void main() {
  late SesionFalsa sesion;
  late PacientesFalsos pacientes;
  late ServicioRegistro registro;

  setUp(() {
    sesion = SesionFalsa();
    pacientes = PacientesFalsos();
    registro = ServicioRegistro(
      sesion: sesion,
      api: _api,
      cifrado: _cifrado,
      repositorioPacientes: pacientes,
      repositorioCuidador: CuidadorFalso(),
      registrarCorreoRespaldo: (_) async {},
    );
  });

  test('con todo bien crea la cuenta y el paciente', () async {
    expect(await registro.registrar(_datos), isA<RegistroExitoso>());
    expect(pacientes.creados, ['p1']);
    expect(sesion.cuentaEliminada, isFalse);
  });

  test('si falla guardar el paciente la cuenta no queda a medias', () async {
    pacientes.falla = true;
    expect(await registro.registrar(_datos), isA<RegistroFallido>());
    expect(sesion.cuentaEliminada, isTrue);
  });

  test('un correo ya registrado muestra un mensaje claro', () async {
    sesion.errorAlRegistrar = const ExcepcionSesion(
      CodigoErrorSesion.correoEnUso,
    );
    final resultado = await registro.registrar(_datos);
    expect(
      (resultado as RegistroFallido).mensaje,
      'Ya existe una cuenta con ese correo electrónico.',
    );
  });
}
