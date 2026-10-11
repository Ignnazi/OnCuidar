import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/app/enrutador/destino_aviso.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/compartido/widgets/aviso_sin_conexion.dart';
import 'package:oncuidar/compartido/widgets/dialogo_confirmacion.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

Future<void> cerrarSesionConfirmando(
  BuildContext context,
  WidgetRef ref, {
  required ValueChanged<bool> alCambiarEstado,
}) async {
  final confirmar = await mostrarDialogoConfirmacion(
    context,
    icono: Icons.logout_rounded,
    titulo: 'Cerrar sesión',
    mensaje: '¿Seguro que deseas cerrar tu sesión?',
    textoConfirmar: 'Cerrar sesión',
    colorConfirmar: Paleta.doradoRelleno,
    iconoConfirmar: Icons.logout_rounded,
    nota: const NotaSinConexion(
      texto: TextosSinConexion.cerrarSesion,
      alineacion: TextAlign.center,
      margen: EdgeInsets.only(top: 12),
    ),
  );
  if (confirmar != true || !context.mounted) return;
  alCambiarEstado(true);
  await ref.read(idPacienteSeleccionadoProvider.notifier).seleccionar(null);
  ref.read(servicioCifradoProvider).bloquear();
  ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(false);
  try {
    await ref.read(servicioNotificacionesProvider).cancelarTodas();
  } catch (_) {
    // Si falla, se sigue igual.
  }
  try {
    await ref.read(servicioSesionProvider).cerrarSesion();
  } catch (_) {
    // Si falla, se sigue igual.
  }
  EstadoArranque.reiniciar();
  if (context.mounted) context.go('/bienvenida');
}
