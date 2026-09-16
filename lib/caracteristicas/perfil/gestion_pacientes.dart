import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';
import '../../modelos/paciente.dart';
import '../../compartidos/widgets/boton_principal.dart';
import '../../compartidos/widgets/dialogo_confirmacion.dart';
import 'widgets/dialogo_archivados.dart';
import 'widgets/dialogo_cambiar_paciente.dart';
import 'widgets/dialogo_paciente.dart';
import 'widgets/tarjeta_paciente_activo.dart';
import 'widgets/tarjeta_sin_pacientes.dart';

class GestionPacientes extends ConsumerStatefulWidget {
  const GestionPacientes({super.key});

  @override
  ConsumerState<GestionPacientes> createState() => _GestionPacientesState();
}

class _GestionPacientesState extends ConsumerState<GestionPacientes> {
  @override
  Widget build(BuildContext context) {
    final pacientesAsync = ref.watch(patientsListProvider);
    final pacienteActualAsync = ref.watch(currentPatientProvider);
    final archivadosAsync = ref.watch(archivedPatientsListProvider);
    final pacientes = pacientesAsync.value ?? const <Paciente>[];
    final pacienteActual = pacienteActualAsync.value;
    final archivados = archivadosAsync.value ?? const <Paciente>[];

    if (pacientesAsync is AsyncLoading || pacienteActualAsync is AsyncLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (pacientes.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarjetaSinPacientes(alAgregar: _dialogoPaciente),
          if (archivados.isNotEmpty) ...[
            const SizedBox(height: 12),
            BotonPrincipal(
              etiqueta: 'Archivados (${archivados.length})',
              alPulsar: _dialogoArchivados,
              destacado: false,
            ),
          ],
        ],
      );
    }
    return _tarjetaPacienteActivo(pacienteActual, pacientes, archivados);
  }

  Widget _tarjetaPacienteActivo(
    Paciente? paciente,
    List<Paciente> pacientes,
    List<Paciente> archivados,
  ) {
    if (paciente == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return TarjetaPacienteActivo(
      paciente: paciente,
      archivadosCount: archivados.length,
      onCambiar: () => _cambiarPaciente(pacientes),
      onAgregar: _dialogoPaciente,
      onEditar: () => _dialogoPaciente(paciente: paciente),
      onEliminar: () => _eliminarPaciente(paciente),
      onArchivar: () => _archivarPaciente(paciente),
      onVerArchivados: _dialogoArchivados,
      alLlamar: _llamar,
      alAbrirMapa: _abrirMapa,
    );
  }

  Future<void> _abrirMapa(String direccion) async {
    final query = Uri.encodeComponent(direccion);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _llamar(String telefono) async {
    final uri = Uri(scheme: 'tel', path: telefono);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _dialogoArchivados() {
    return mostrarDialogoArchivados(
      context,
      alDesarchivar: _desarchivarPaciente,
    );
  }

  Future<void> _desarchivarPaciente(Paciente paciente) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(servicioBaseDatosProvider)
          .desarchivarPaciente(paciente.id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${paciente.fullName} restaurado'),
            backgroundColor: Paleta.doradoPrincipal,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo restaurar. Intenta de nuevo.'),
            backgroundColor: Paleta.error,
          ),
        );
      }
    }
  }

  void _cambiarPaciente(List<Paciente> pacientes) {
    final idActual = ref.read(currentPatientProvider).value?.id;
    mostrarDialogoCambiarPaciente(
      context,
      pacientes: pacientes,
      idActual: idActual,
      alCambiar: (p) async {
        await ref.read(selectedPatientIdProvider.notifier).select(p.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paciente activo: ${p.fullName}'),
              duration: const Duration(seconds: 2),
              backgroundColor: Paleta.doradoPrincipal,
            ),
          );
        }
      },
    );
  }

  Future<void> _dialogoPaciente({Paciente? paciente}) {
    return mostrarDialogoPaciente(
      context,
      paciente: paciente,
      servicio: ref.read(servicioBaseDatosProvider),
    );
  }

  Future<void> _archivarPaciente(Paciente paciente) async {
    final confirmar = await mostrarDialogoConfirmacion(
      context,
      icono: Icons.archive_outlined,
      titulo: 'Archivar paciente',
      mensaje:
          '¿Archivar a ${paciente.fullName}? Sus datos se conservarán y '
          'dejará de aparecer en la lista.',
      textoConfirmar: 'Archivar',
      colorConfirmar: Paleta.doradoMedio,
      iconoConfirmar: Icons.archive_outlined,
    );
    if (confirmar != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(servicioBaseDatosProvider).archivarPaciente(paciente.id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${paciente.fullName} archivado'),
            backgroundColor: Paleta.doradoPrincipal,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo archivar. Intenta de nuevo.'),
            backgroundColor: Paleta.error,
          ),
        );
      }
    }
  }

  Future<void> _eliminarPaciente(Paciente paciente) async {
    final confirmar = await mostrarDialogoConfirmacion(
      context,
      icono: Icons.delete_outline,
      titulo: 'Eliminar paciente',
      mensaje:
          '¿Eliminar a ${paciente.fullName} definitivamente? Esta acción no '
          'se puede deshacer y se borrarán todos sus datos.',
      textoConfirmar: 'Eliminar',
      colorConfirmar: Paleta.error,
      iconoConfirmar: Icons.delete_forever_outlined,
    );
    if (confirmar != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final eraActivo = ref.read(currentPatientProvider).value?.id == paciente.id;
    try {
      await ref.read(servicioBaseDatosProvider).eliminarPaciente(paciente.id);
      if (eraActivo) {
        final restantes =
            (ref.read(patientsListProvider).value ?? const <Paciente>[])
                .where((p) => p.id != paciente.id)
                .toList();
        await ref
            .read(selectedPatientIdProvider.notifier)
            .select(restantes.isEmpty ? null : restantes.first.id);
      }
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${paciente.fullName} eliminado'),
            backgroundColor: Paleta.doradoPrincipal,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar. Intenta de nuevo.'),
            backgroundColor: Paleta.error,
          ),
        );
      }
    }
  }
}