import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/proveedores_perfil.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/proveedores_perfil.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/dialogo_correos.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/dialogo_editar_cuidador.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/mensaje_error_datos.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/pie_version.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/tarjeta_configuracion.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/tarjeta_perfil_cuidador.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';

class PerfilCuidador extends ConsumerStatefulWidget {
  const PerfilCuidador({super.key});

  @override
  ConsumerState<PerfilCuidador> createState() => _PerfilCuidadorState();
}

class _PerfilCuidadorState extends ConsumerState<PerfilCuidador> {
  Map<String, dynamic>? _cuidador;
  bool _cargando = true;
  bool _error = false;

  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _cargar();
    _temporizador = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_cargando) unawaited(_cargar());
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (_cuidador == null) {
      setState(() {
        _cargando = true;
        _error = false;
      });
    }
    try {
      final repositorio = ref.read(repositorioCuidadorProvider);
      final datos = await repositorio.obtenerCuidador().timeout(
        const Duration(seconds: 5),
      );
      if (!mounted) return;
      setState(() => _cuidador = datos);
    } catch (_) {
      if (!mounted) return;
      if (_cuidador == null) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _reenviarVerificacion() async {
    final mensajero = ScaffoldMessenger.of(context);
    String texto;
    try {
      await ref.read(repositorioCuidadorProvider).reenviarVerificacion();
      texto = 'Te enviamos un enlace para verificar tu correo.';
    } on ExcepcionSesion catch (e) {
      texto = e.codigo == CodigoErrorSesion.demasiadosIntentos
          ? 'Espera un minuto antes de pedir otro enlace.'
          : 'No se pudo enviar el enlace. Intenta de nuevo.';
    } catch (_) {
      texto = 'No se pudo enviar el enlace. Intenta de nuevo.';
    }
    mensajero.showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_cargando)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error)
          MensajeErrorDatos(alReintentar: _cargar)
        else ...[
          _tarjetaPerfil(),
          const SizedBox(height: 16),
          const TarjetaConfiguracion(),
          const SizedBox(height: 28),
          const PieVersion(),
        ],
      ],
    );
  }

  Widget _tarjetaPerfil() {
    final nombre = (_cuidador?['nombre'] as String?) ?? '';
    final correoRespaldo = (_cuidador?['correoRespaldo'] as String?)?.trim();
    final telefono = (_cuidador?['telefono'] as String?)?.trim();
    final relacion = (_cuidador?['relacion'] as String?)?.trim();
    final direccion = (_cuidador?['direccion'] as String?)?.trim();
    final correoSesion =
        ref.read(servicioSesionProvider).actual?.correo.trim() ?? '';
    final correoPrincipal =
        (_cuidador?['correo'] as String?)?.trim() ?? correoSesion;

    return TarjetaPerfilCuidador(
      nombre: nombre,
      relacion: relacion,
      direccion: direccion ?? '',
      telefono: telefono ?? '',
      correoPrincipal: correoPrincipal,
      correoRespaldo: (correoRespaldo != null && correoRespaldo.isNotEmpty)
          ? correoRespaldo
          : null,
      respaldoPendiente: _cuidador?['respaldoPendiente'] == true,
      respaldoVerificado: _cuidador?['correoRespaldoVerificado'] == true,
      correoVerificado: _cuidador?['correoVerificado'] == true,
      pendienteCorreo: _cuidador?['pendienteCorreo'] as String?,
      onReenviarVerificacion: _reenviarVerificacion,
      onEditarDatos: _dialogoEditarCuidador,
      onEditarCorreoPrincipal: () => _dialogoCorreos(editarPrincipal: true),
      onEditarCorreoRespaldo: () => _dialogoCorreos(editarRespaldo: true),
    );
  }

  Future<void> _dialogoEditarCuidador() async {
    final repositorio = ref.read(repositorioCuidadorProvider);
    await mostrarDialogoEditarCuidador(
      context,
      cuidador: _cuidador ?? {},
      alGuardar:
          ({
            required String nombre,
            required String telefono,
            required String relacion,
            required String direccion,
          }) async {
            if (mounted) {
              setState(() {
                _cuidador = {
                  ...?_cuidador,
                  'nombre': nombre,
                  'telefono': telefono,
                  'relacion': relacion,
                  'direccion': direccion,
                };
              });
            }
            ref.invalidate(cuidadorProvider);
            unawaited(_cargar());
            await repositorio
                .actualizarCuidador(
                  nombre: nombre,
                  telefono: telefono,
                  relacion: relacion,
                  direccion: direccion,
                )
                .timeout(const Duration(seconds: 3));
            unawaited(_cargar());
          },
    );
  }

  Future<void> _dialogoCorreos({
    bool editarPrincipal = false,
    bool editarRespaldo = false,
  }) async {
    final cuidador = _cuidador ?? {};
    final correoPrincipalOriginal =
        (cuidador['correo'] as String?)?.trim() ?? '';
    final correoRespaldoOriginal =
        (cuidador['correoRespaldo'] as String?)?.trim() ?? '';
    await mostrarDialogoCorreos(
      context,
      repositorio: ref.read(repositorioCuidadorProvider),
      correoPrincipalOriginal: correoPrincipalOriginal,
      correoRespaldoOriginal: correoRespaldoOriginal,
      editarPrincipal: editarPrincipal,
      editarRespaldo: editarRespaldo,
      alRefrescar: _cargar,
    );
  }
}
