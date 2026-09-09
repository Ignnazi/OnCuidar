import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';
import '../../core/utilidades/rut_utils.dart';
import '../../modelos/paciente.dart';
import '../../compartidos/widgets/boton_principal.dart';
import '../../compartidos/widgets/campos_formulario.dart';
import '../../compartidos/widgets/chip_franja.dart';
import '../../compartidos/widgets/titulo_seccion.dart';

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
          _tarjetaSinPacientes(),
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

  // ── Paciente activo ──

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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Paleta.tarjeta,
            borderRadius: const BorderRadius.vertical(
              top: Radius.zero,
              bottom: Radius.circular(24),
            ),
            border: Border.all(color: Paleta.bordeTarjeta),
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabecera dorada del paciente activo ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 44, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Paleta.doradoOscuro,
                      Paleta.doradoPrincipal,
                      Paleta.doradoMedio,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.child_care_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PACIENTE ACTIVO',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            paciente.fullName.isEmpty
                                ? 'Sin nombre'
                                : paciente.fullName,
                            style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (paciente.rut != null &&
                                  paciente.rut!.isNotEmpty ||
                              paciente.age != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (paciente.rut != null &&
                                      paciente.rut!.isNotEmpty)
                                    ChipFranja(
                                      Icons.badge_outlined,
                                      'RUT: ${formatearRut(paciente.rut!)}',
                                    ),
                                  if (paciente.age != null)
                                    ChipFranja(
                                      Icons.cake_outlined,
                                      'Edad: ${paciente.age} años',
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Datos del paciente ──
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (paciente.diagnosis != null &&
                        paciente.diagnosis!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _filaDato(
                          icono: Icons.medical_information_outlined,
                          etiqueta: 'Diagnóstico',
                          valor: paciente.diagnosis!,
                        ),
                      ),
                    if (paciente.tratamientoFase != null &&
                        paciente.tratamientoFase!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _filaDato(
                          icono: Icons.medication_outlined,
                          etiqueta: 'Fase de tratamiento',
                          valor: paciente.tratamientoFase!,
                        ),
                      ),
                    if (paciente.centroSaludNombre != null &&
                        paciente.centroSaludNombre!.isNotEmpty)
                      _seccionCentroSalud(paciente),
                    if (paciente.contactoEmergenciaNombre != null &&
                        paciente.contactoEmergenciaNombre!.isNotEmpty)
                      _seccionContactoEmergencia(paciente),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: BotonPrincipal(
                              etiqueta: archivados.isEmpty
                                  ? 'Archivados'
                                  : 'Archivados (${archivados.length})',
                              alPulsar: _dialogoArchivados,
                              destacado: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BotonPrincipal(
                              etiqueta: 'Cambiar',
                              alPulsar: () => _cambiarPaciente(pacientes),
                              destacado: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 10,
          child: PopupMenuButton<_AccionPaciente>(
            onSelected: (accion) {
              switch (accion) {
                case _AccionPaciente.agregar:
                  _dialogoPaciente();
                case _AccionPaciente.editar:
                  _dialogoPaciente(paciente: paciente);
                case _AccionPaciente.archivar:
                  _archivarPaciente(paciente);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AccionPaciente.agregar,
                child: ListTile(
                  leading: Icon(Icons.person_add_alt_1_outlined),
                  title: Text('Agregar paciente'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: _AccionPaciente.editar,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: _AccionPaciente.archivar,
                child: ListTile(
                  leading: Icon(Icons.archive_outlined, color: Paleta.error),
                  title: Text(
                    'Archivar',
                    style: TextStyle(color: Paleta.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert_rounded, color: Colors.white),
            ),
            color: Paleta.tarjeta,
          ),
        ),
      ],
    );
  }

  // ── Centro de salud: tarjeta con miniatura de mapa y llamada compacta ──

  Widget _seccionCentroSalud(Paciente paciente) {
    final telefono = paciente.centroSaludTelefono ?? '';
    final direccion = paciente.centroSaludDireccion ?? '';
    return _tarjetaContacto(
      icono: Icons.local_hospital_outlined,
      etiqueta: 'Centro de salud',
      titulo: paciente.centroSaludNombre ?? 'Centro de salud',
      direccion: direccion,
      telefono: telefono,
      alLlamar: telefono.isNotEmpty ? () => _llamar(telefono) : null,
    );
  }

  // ── Contacto de emergencia con llamada rápida ──

  Widget _seccionContactoEmergencia(Paciente paciente) {
    final telefono = paciente.contactoEmergenciaTelefono ?? '';
    return _tarjetaContacto(
      icono: Icons.emergency_outlined,
      etiqueta: 'Contacto de emergencia',
      titulo: paciente.contactoEmergenciaNombre ?? 'Contacto de emergencia',
      direccion: '',
      telefono: telefono,
      alLlamar: telefono.isNotEmpty ? () => _llamar(telefono) : null,
    );
  }

  /// Tarjeta de contacto a todo lo ancho de la tarjeta activa: nombre y
  /// teléfono a la izquierda, botón dorado circular a la derecha, y el mapa
  /// con la dirección en su esquina. Fondo blanco con borde dorado suave.
  Widget _tarjetaContacto({
    required IconData icono,
    required String etiqueta,
    required String titulo,
    String? direccion,
    String? telefono,
    VoidCallback? alLlamar,
  }) {
    final tieneDireccion = direccion != null && direccion.isNotEmpty;
    final tieneTelefono =
        telefono != null && telefono.isNotEmpty && alLlamar != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Paleta.tarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Paleta.doradoClaro),
          boxShadow: [
            BoxShadow(
              color: Paleta.doradoOscuro.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Paleta.doradoClaro.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, size: 18, color: Paleta.doradoOscuro),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etiqueta,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Paleta.textoTerciario,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        titulo,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Paleta.textoPrincipal,
                        ),
                      ),
                      if (telefono != null && telefono.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          telefono,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (tieneTelefono) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: alLlamar,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Paleta.doradoPrincipal, Paleta.doradoOscuro],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Paleta.doradoOscuro.withValues(alpha: 0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (tieneDireccion) ...[
              const SizedBox(height: 10),
              _tarjetaMapa(
                direccion: direccion,
                onTap: () => _abrirMapa(direccion),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Miniatura que "parece mapa" (calles + pin, sin API key) y abre
  /// Google Maps al tocarla. Ocupa todo el ancho de la tarjeta.
  Widget _tarjetaMapa({
    required String direccion,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 88,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Paleta.fondoEntrada,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Paleta.bordeTarjeta),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _MapaPintor()),
            Align(
              alignment: const Alignment(0, -0.45),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Paleta.doradoPrincipal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Paleta.doradoOscuro,
                  size: 20,
                ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      color: Paleta.doradoOscuro,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        direccion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Paleta.doradoOscuro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _tarjetaSinPacientes() {
    return TarjetaSeccion(
      icono: Icons.child_care_outlined,
      titulo: 'Pacientes',
      hijos: [
        const Icon(
          Icons.child_care_outlined,
          size: 44,
          color: Paleta.doradoMedio,
        ),
        const SizedBox(height: 12),
        Text(
          'Aún no tienes pacientes registrados.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Paleta.textoPrincipal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Agrega el primero para comenzar a registrar sus cuidados.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            height: 1.4,
            color: Paleta.textoSecundario,
          ),
        ),
        const SizedBox(height: 18),
        BotonPrincipal(
          etiqueta: 'Agregar paciente',
          alPulsar: _dialogoPaciente,
        ),
      ],
    );
  }

  // ── Pacientes archivados: modal "ver y desarchivar" ──

  Future<void> _dialogoArchivados() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Consume el provider en vivo: al desarchivar, la fila desaparece al
      // instante (y si no queda nadie, aparece el estado vacío).
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final archivados =
              ref.watch(archivedPatientsListProvider).value ??
              const <Paciente>[];
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            builder: (ctx, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Paleta.tarjeta,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Paleta.bordeTarjeta,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Paleta.doradoPrincipal,
                                Paleta.doradoOscuro,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.archive_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            archivados.length == 1
                                ? '1 paciente archivado'
                                : '${archivados.length} pacientes archivados',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Paleta.textoPrincipal,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 1, color: Paleta.bordeTarjeta),
                  if (archivados.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.inbox_outlined,
                                size: 40,
                                color: Paleta.textoSecundario,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No hay pacientes archivados.',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Paleta.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          for (final p in archivados) _filaArchivado(p),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filaArchivado(Paciente paciente) {
    final inicial = paciente.fullName.isNotEmpty
        ? paciente.fullName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: Paleta.fondoEntrada.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Paleta.bordeTarjeta),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Paleta.doradoClaro.withValues(alpha: 0.7),
              child: Text(
                inicial,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: Paleta.doradoOscuro,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paciente.fullName.isEmpty
                        ? 'Sin nombre'
                        : paciente.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Paleta.textoPrincipal,
                    ),
                  ),
                  if (paciente.diagnosis != null &&
                      paciente.diagnosis!.isNotEmpty)
                    Text(
                      paciente.diagnosis!,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Paleta.textoSecundario,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _desarchivarPaciente(paciente),
              tooltip: 'Restaurar ${paciente.fullName}',
              icon: const Icon(
                Icons.unarchive_outlined,
                color: Paleta.doradoOscuro,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Paleta.doradoClaro.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
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

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Paleta.bordeTarjeta,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Seleccionar paciente',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Paleta.textoPrincipal,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Los datos que veas se actualizarán según el paciente '
                'seleccionado.',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Paleta.textoTerciario,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in pacientes)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p.id == idActual
                            ? Paleta.doradoPrincipal
                            : Paleta.doradoClaro,
                        child: Text(
                          p.fullName.isNotEmpty
                              ? p.fullName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: p.id == idActual
                                ? Colors.white
                                : Paleta.doradoOscuro,
                          ),
                        ),
                      ),
                      title: Text(
                        p.fullName,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: Paleta.textoPrincipal,
                        ),
                      ),
                      subtitle: (p.diagnosis != null && p.diagnosis!.isNotEmpty)
                          ? Text(
                              p.diagnosis!,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: Paleta.textoSecundario,
                              ),
                            )
                          : null,
                      trailing: p.id == idActual
                          ? const Icon(
                              Icons.check_circle,
                              color: Paleta.doradoPrincipal,
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        if (p.id == idActual) return;
                        final messenger = ScaffoldMessenger.of(context);
                        await ref
                            .read(selectedPatientIdProvider.notifier)
                            .select(p.id);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Paciente activo: ${p.fullName}'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Paleta.doradoPrincipal,
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _archivarPaciente(Paciente paciente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archivar paciente'),
        content: Text(
          '¿Archivar a ${paciente.fullName}? Sus datos se conservarán y '
          'dejará de aparecer en la lista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Archivar'),
          ),
        ],
      ),
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

  Future<void> _dialogoPaciente({Paciente? paciente}) async {
    final esEdicion = paciente != null;
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: paciente?.fullName ?? '',
    );
    final rutController = TextEditingController(text: paciente?.rut ?? '');
    final edadController = TextEditingController(
      text: paciente?.age?.toString() ?? '',
    );
    final diagnosticoController = TextEditingController(
      text: paciente?.diagnosis ?? '',
    );
    final faseController = TextEditingController(
      text: paciente?.tratamientoFase ?? '',
    );
    final centroNombreController = TextEditingController(
      text: paciente?.centroSaludNombre ?? '',
    );
    final centroDireccionController = TextEditingController(
      text: paciente?.centroSaludDireccion ?? '',
    );
    final centroTelefonoController = TextEditingController(
      text: paciente?.centroSaludTelefono ?? '',
    );
    final emergenciaNombreController = TextEditingController(
      text: paciente?.contactoEmergenciaNombre ?? '',
    );
    final emergenciaTelefonoController = TextEditingController(
      text: paciente?.contactoEmergenciaTelefono ?? '',
    );
    bool cargando = false;

    rutController.addListener(() {
      final texto = rutController.text;
      final formateado = formatearRut(texto);
      if (formateado != texto) {
        rutController.value = TextEditingValue(
          text: formateado,
          selection: TextSelection.collapsed(offset: formateado.length),
        );
      }
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // El formulario no se cierra al arrastrar, al tocar fuera ni con el
      // gesto "atrás" del sistema: los datos escritos nunca se pierden por
      // accidente (solo se cierra con Cancelar o la X).
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Paleta.tarjeta,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Paleta.bordeTarjeta,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Paleta.doradoPrincipal,
                              Paleta.doradoOscuro,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          esEdicion
                              ? Icons.edit_outlined
                              : Icons.person_add_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          esEdicion ? 'Editar paciente' : 'Agregar paciente',
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Paleta.textoPrincipal,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Form(
                    key: formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        24 + MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      children: [
                        TituloSeccion(
                          Icons.person_outline,
                          'Datos del paciente',
                        ),
                        const SizedBox(height: 10),
                        CampoFormulario(
                          controlador: nombreController,
                          textoAyuda: 'Nombre completo *',
                          icono: Icons.badge_outlined,
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa el nombre'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        CampoFormulario(
                          controlador: rutController,
                          textoAyuda: 'RUT *',
                          icono: Icons.pin_outlined,
                          accionTeclado: TextInputAction.next,
                          validador: (v) {
                            final valor = v?.trim() ?? '';
                            if (valor.isEmpty) return 'Ingresa el RUT';
                            return validarRut(valor) ? null : 'RUT inválido';
                          },
                        ),
                        const SizedBox(height: 12),
                        CampoFormulario(
                          controlador: edadController,
                          textoAyuda: 'Edad *',
                          icono: Icons.cake_outlined,
                          tipoTeclado: TextInputType.number,
                          accionTeclado: TextInputAction.next,
                          validador: (v) {
                            final valor = v?.trim() ?? '';
                            if (valor.isEmpty) return 'Ingresa la edad';
                            return int.tryParse(valor) == null
                                ? 'Ingresa un número'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CampoFormulario(
                          controlador: diagnosticoController,
                          textoAyuda: 'Diagnóstico *',
                          icono: Icons.medical_information_outlined,
                          accionTeclado: TextInputAction.next,
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa el diagnóstico'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        CampoFormulario(
                          controlador: faseController,
                          textoAyuda: 'Fase de tratamiento *',
                          icono: Icons.medication_outlined,
                          accionTeclado: TextInputAction.next,
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa la fase de tratamiento'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TituloSeccion(
                          Icons.local_hospital_outlined,
                          'Centro de salud',
                        ),
                        const SizedBox(height: 10),
                        CampoFormulario(
                          controlador: centroNombreController,
                          textoAyuda: 'Nombre del centro *',
                          icono: Icons.local_hospital_outlined,
                          accionTeclado: TextInputAction.next,
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa el nombre del centro'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        CampoFormulario(
                          controlador: centroDireccionController,
                          textoAyuda: 'Dirección *',
                          icono: Icons.location_on_outlined,
                          accionTeclado: TextInputAction.next,
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa la dirección'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        CampoFormulario(
                          controlador: centroTelefonoController,
                          textoAyuda: 'Teléfono del centro *',
                          icono: Icons.phone_outlined,
                          tipoTeclado: TextInputType.phone,
                          accionTeclado: TextInputAction.next,
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa el teléfono del centro'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TituloSeccion(
                          Icons.emergency_outlined,
                          'Contacto de emergencia',
                        ),
                        const SizedBox(height: 10),
                        CampoFormulario(
                          controlador: emergenciaNombreController,
                          textoAyuda: 'Nombre del contacto *',
                          icono: Icons.person_outline,
                          accionTeclado: TextInputAction.next,
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa el nombre del contacto'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        CampoFormulario(
                          controlador: emergenciaTelefonoController,
                          textoAyuda: 'Teléfono de emergencia *',
                          icono: Icons.phone_in_talk_outlined,
                          tipoTeclado: TextInputType.phone,
                          accionTeclado: TextInputAction.done,
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa el teléfono de emergencia'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: BotonPrincipal(
                                etiqueta: 'Cancelar',
                                alPulsar: () => Navigator.of(ctx).pop(),
                                destacado: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: BotonPrincipal(
                                etiqueta: cargando
                                    ? 'Guardando…'
                                    : (esEdicion
                                          ? 'Guardar cambios'
                                          : 'Guardar'),
                                alPulsar: cargando
                                    ? () {}
                                    : () => _guardarPaciente(
                                        ctx: ctx,
                                        formKey: formKey,
                                        esEdicion: esEdicion,
                                        paciente: paciente,
                                        nombreController: nombreController,
                                        rutController: rutController,
                                        edadController: edadController,
                                        diagnosticoController:
                                            diagnosticoController,
                                        faseController: faseController,
                                        centroNombreController:
                                            centroNombreController,
                                        centroDireccionController:
                                            centroDireccionController,
                                        centroTelefonoController:
                                            centroTelefonoController,
                                        emergenciaNombreController:
                                            emergenciaNombreController,
                                        emergenciaTelefonoController:
                                            emergenciaTelefonoController,
                                        onCargando: (v) =>
                                            setState(() => cargando = v),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardarPaciente({
    required BuildContext ctx,
    required GlobalKey<FormState> formKey,
    required bool esEdicion,
    required Paciente? paciente,
    required TextEditingController nombreController,
    required TextEditingController rutController,
    required TextEditingController edadController,
    required TextEditingController diagnosticoController,
    required TextEditingController faseController,
    required TextEditingController centroNombreController,
    required TextEditingController centroDireccionController,
    required TextEditingController centroTelefonoController,
    required TextEditingController emergenciaNombreController,
    required TextEditingController emergenciaTelefonoController,
    required ValueChanged<bool> onCargando,
  }) async {
    if (!formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(ctx);
    final datos = <String, dynamic>{
      'fullName': nombreController.text.trim(),
      'rut': rutController.text.trim(),
      'age': int.tryParse(edadController.text.trim()),
      'diagnosis': diagnosticoController.text.trim(),
      'tratamientoFase': faseController.text.trim(),
      'centroSaludNombre': centroNombreController.text.trim(),
      'centroSaludDireccion': centroDireccionController.text.trim(),
      'centroSaludTelefono': centroTelefonoController.text.trim(),
      'contactoEmergenciaNombre': emergenciaNombreController.text.trim(),
      'contactoEmergenciaTelefono': emergenciaTelefonoController.text.trim(),
    };
    onCargando(true);
    try {
      final servicio = ref.read(servicioBaseDatosProvider);
      if (esEdicion && paciente != null) {
        await servicio.actualizarPaciente(paciente.id, datos);
      } else {
        await servicio.crearPaciente(
          Paciente(
            id: '',
            fullName: datos['fullName'] as String,
            rut: datos['rut'] as String?,
            age: datos['age'] as int?,
            diagnosis: datos['diagnosis'] as String?,
            tratamientoFase: datos['tratamientoFase'] as String?,
            centroSaludNombre: datos['centroSaludNombre'] as String?,
            centroSaludDireccion: datos['centroSaludDireccion'] as String?,
            centroSaludTelefono: datos['centroSaludTelefono'] as String?,
            contactoEmergenciaNombre:
                datos['contactoEmergenciaNombre'] as String?,
            contactoEmergenciaTelefono:
                datos['contactoEmergenciaTelefono'] as String?,
            createdAt: DateTime.now(),
          ),
        );
      }
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            esEdicion ? 'Paciente actualizado' : 'Paciente agregado',
          ),
          backgroundColor: Paleta.doradoPrincipal,
        ),
      );
    } catch (_) {
      if (mounted) onCargando(false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar. Intenta de nuevo.'),
          backgroundColor: Paleta.error,
        ),
      );
    }
  }

  Widget _filaDato({
    required IconData icono,
    required String etiqueta,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Paleta.doradoClaro.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 18, color: Paleta.doradoOscuro),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Paleta.textoTerciario,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Paleta.textoPrincipal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _AccionPaciente { agregar, editar, archivar }

/// Dibuja una miniatura estilizada tipo mapa: fondo crema con manzanas y
/// calles simples más un pin dorado centrado. Sin API keys.
class _MapaPintor extends CustomPainter {
  const _MapaPintor();

  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Paint()..color = const Color(0xFFF7ECDA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      fondo,
    );

    // Manzanas (bloques suaves en tono crema más claro).
    final bloque = Paint()..color = const Color(0xFFFDF6EC);
    final margen = size.width * 0.28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          margen * 0.35,
          size.height * 0.22,
          size.width * 0.32,
          size.height * 0.28,
        ),
        const Radius.circular(8),
      ),
      bloque,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.62,
          size.height * 0.55,
          size.width * 0.30,
          size.height * 0.30,
        ),
        const Radius.circular(8),
      ),
      bloque,
    );

    // Calles: trazos anchos en blanco, como vías principales.
    final calle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.62, size.height),
      calle,
    );
    final calle2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.48),
      Offset(size.width, size.height * 0.30),
      calle2,
    );

    // Acera secundaria fina.
    final via = Paint()
      ..color = const Color(0xFFF3DCA8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width * 0.5, size.height),
      via,
    );
  }

  @override
  bool shouldRepaint(covariant _MapaPintor oldDelegate) => false;
}
