import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/app/enrutador/destino_aviso.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/proveedores_perfil.dart';
import 'package:oncuidar/caracteristicas/perfil/datos/repositorio_cuidador.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/proveedores_perfil.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/boton_cerrar_sesion.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/dialogo_correos.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/dialogo_editar_cuidador.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/mensaje_error_datos.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/pie_version.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/widgets/tarjeta_perfil_cuidador.dart';
import 'package:oncuidar/compartido/widgets/dialogo_confirmacion.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

class PerfilCuidador extends ConsumerStatefulWidget {
  const PerfilCuidador({super.key});

  @override
  ConsumerState<PerfilCuidador> createState() => _PerfilCuidadorState();
}

class _PerfilCuidadorState extends ConsumerState<PerfilCuidador> {
  Map<String, dynamic>? _cuidador;
  bool _cargando = true;
  bool _error = false;
  bool _cerrandoSesion = false;

  @override
  void initState() {
    super.initState();
    _cargar();
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
      var datos = await repositorio.obtenerCuidador().timeout(
        const Duration(seconds: 5),
      );
      final pendiente = datos['pendienteCorreo'] as Map?;
      if (pendiente != null && pendiente['tipo'] == 'principal') {
        await _confirmarCambioCorreoConfirmado(repositorio, datos);
        datos = await repositorio.obtenerCuidador().timeout(
          const Duration(seconds: 5),
        );
      }
      if (datos['respaldoPendienteServidor'] == true) {
        datos = await _reintentarRespaldo(repositorio, datos);
      }
      if (!mounted) return;
      setState(() => _cuidador = datos);
    } catch (_) {
      if (!mounted) return;
      if (_cuidador == null) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarCambioCorreoConfirmado(
    RepositorioCuidador repositorio,
    Map<String, dynamic> datos,
  ) async {
    final pendiente = datos['pendienteCorreo'] as Map?;
    if (pendiente == null) return;
    if (pendiente['tipo'] != 'principal') return;
    final correoPendiente = (pendiente['correo'] as String?)?.toLowerCase();
    final correoAuth = ref
        .read(firebaseAuthProvider)
        .currentUser
        ?.email
        ?.toLowerCase();
    if (correoPendiente == null || correoPendiente.isEmpty) return;
    if (correoAuth == correoPendiente) {
      await repositorio.sincronizarCorreoPrincipal(correoPendiente);
      await repositorio.limpiarCambioCorreoPendiente();
    }
  }

  Future<Map<String, dynamic>> _reintentarRespaldo(
    RepositorioCuidador repositorio,
    Map<String, dynamic> datos,
  ) async {
    var confirmado = false;
    try {
      confirmado = await repositorio.reintentarRegistroRespaldo().timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {}
    if (confirmado) {
      return {...datos, 'respaldoPendienteServidor': false};
    }
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Tu correo de respaldo aún no se registra en el servidor. '
            'Lo reintentaremos al volver a abrir tu perfil.',
          ),
        ),
      );
    }
    return datos;
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
          const SizedBox(height: 28),
          const PieVersion(),
          const SizedBox(height: 8),
          BotonCerrarSesion(cargando: _cerrandoSesion, alPulsar: _cerrarSesion),
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
    final emailAuth =
        ref.read(firebaseAuthProvider).currentUser?.email?.trim() ?? '';
    final correoPrincipal =
        (_cuidador?['correo'] as String?)?.trim() ?? emailAuth;
    final pendiente = _cuidador?['pendienteCorreo'] as Map?;

    return TarjetaPerfilCuidador(
      nombre: nombre,
      relacion: relacion,
      direccion: direccion ?? '',
      telefono: telefono ?? '',
      correoPrincipal: correoPrincipal,
      correoRespaldo: (correoRespaldo != null && correoRespaldo.isNotEmpty)
          ? correoRespaldo
          : null,
      correoPrincipalPendiente: pendiente?['tipo'] == 'principal'
          ? pendiente!['correo'] as String?
          : null,
      respaldoPendiente: _cuidador?['respaldoPendienteServidor'] == true,
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

  Future<void> _cerrarSesion() async {
    final confirmar = await mostrarDialogoConfirmacion(
      context,
      icono: Icons.logout_rounded,
      titulo: 'Cerrar sesión',
      mensaje: '¿Seguro que deseas cerrar tu sesión?',
      textoConfirmar: 'Cerrar sesión',
      colorConfirmar: Paleta.doradoOscuro,
      iconoConfirmar: Icons.logout_rounded,
    );
    if (confirmar != true || !mounted) return;
    setState(() => _cerrandoSesion = true);
    await ref.read(idPacienteSeleccionadoProvider.notifier).seleccionar(null);
    ref.read(servicioCifradoProvider).bloquear();
    ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(false);
    try {
      await ref.read(servicioNotificacionesProvider).cancelarTodas();
    } catch (_) {
      // Si falla, se sigue igual.
    }
    try {
      await ref.read(firebaseAuthProvider).signOut();
    } catch (_) {
      // Si falla, se sigue igual.
    }
    EstadoArranque.reiniciar();
    if (mounted && context.mounted) context.go('/bienvenida');
  }
}
