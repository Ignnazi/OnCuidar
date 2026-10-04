import 'package:flutter/material.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/widgets/tarjeta_contacto.dart';
import 'package:oncuidar/compartido/widgets/chip_franja.dart';
import 'package:oncuidar/compartido/widgets/tarjeta_dato.dart';
import 'package:oncuidar/compartido/widgets/tarjeta_perfil.dart';
import 'package:oncuidar/nucleo/utilidades/rut.dart';

enum _AccionPaciente {
  cambiar,
  agregar,
  eliminar,
  editar,
  archivar,
  verArchivados,
}

class TarjetaPacienteActivo extends StatelessWidget {
  const TarjetaPacienteActivo({
    super.key,
    required this.paciente,
    required this.archivadosCount,
    required this.onCambiar,
    required this.onAgregar,
    required this.onEditar,
    required this.onEliminar,
    required this.onArchivar,
    required this.onVerArchivados,
    required this.alLlamar,
    required this.alAbrirMapa,
  });

  final Paciente paciente;
  final int archivadosCount;
  final VoidCallback onCambiar;
  final VoidCallback onAgregar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onArchivar;
  final VoidCallback onVerArchivados;
  final Future<void> Function(String telefono) alLlamar;
  final Future<void> Function(String direccion) alAbrirMapa;

  @override
  Widget build(BuildContext context) {
    return MarcoTarjetaPerfil(
      menuArriba: 16,
      hijos: [
        CabeceraDorada(
          icono: Icons.child_care_rounded,
          etiqueta: 'PACIENTE ACTIVO',
          nombre: paciente.nombreCompleto.isEmpty
              ? 'Sin nombre'
              : paciente.nombreCompleto,
          franjas: [
            if (paciente.rut != null && paciente.rut!.isNotEmpty)
              ChipFranja(
                Icons.badge_outlined,
                'RUT: ${formatearRut(paciente.rut!)}',
              ),
            if (paciente.edad != null)
              ChipFranja(Icons.cake_outlined, 'Edad: ${paciente.edad} años'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((paciente.diagnostico != null &&
                      paciente.diagnostico!.isNotEmpty) ||
                  (paciente.tratamientoFase != null &&
                      paciente.tratamientoFase!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TarjetaDorada(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (paciente.diagnostico != null &&
                            paciente.diagnostico!.isNotEmpty)
                          FilaDato(
                            icono: Icons.medical_information_outlined,
                            etiqueta: 'Diagnóstico',
                            valor: paciente.diagnostico!,
                          ),
                        if ((paciente.diagnostico != null &&
                                paciente.diagnostico!.isNotEmpty) &&
                            (paciente.tratamientoFase != null &&
                                paciente.tratamientoFase!.isNotEmpty))
                          const SizedBox(height: 12),
                        if (paciente.tratamientoFase != null &&
                            paciente.tratamientoFase!.isNotEmpty)
                          FilaDato(
                            icono: Icons.medication_outlined,
                            etiqueta: 'Fase de tratamiento',
                            valor: paciente.tratamientoFase!,
                          ),
                      ],
                    ),
                  ),
                ),
              if (paciente.centroSaludNombre != null &&
                  paciente.centroSaludNombre!.isNotEmpty)
                _TarjetaContactoSeccion(
                  icono: Icons.local_hospital_outlined,
                  etiqueta: 'Centro de salud',
                  titulo: paciente.centroSaludNombre ?? 'Centro de salud',
                  direccion: paciente.centroSaludDireccion ?? '',
                  telefono: paciente.centroSaludTelefono ?? '',
                  alLlamar: alLlamar,
                  alAbrirMapa: alAbrirMapa,
                ),
              if (paciente.contactoEmergenciaNombre != null &&
                  paciente.contactoEmergenciaNombre!.isNotEmpty)
                _TarjetaContactoSeccion(
                  icono: Icons.emergency_outlined,
                  etiqueta: 'Contacto de emergencia',
                  titulo:
                      paciente.contactoEmergenciaNombre ??
                      'Contacto de emergencia',
                  direccion: '',
                  telefono: paciente.contactoEmergenciaTelefono ?? '',
                  alLlamar: alLlamar,
                  alAbrirMapa: alAbrirMapa,
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
      menu: PopupMenuButton<_AccionPaciente>(
        onSelected: (accion) {
          switch (accion) {
            case _AccionPaciente.cambiar:
              onCambiar();
            case _AccionPaciente.agregar:
              onAgregar();
            case _AccionPaciente.eliminar:
              onEliminar();
            case _AccionPaciente.editar:
              onEditar();
            case _AccionPaciente.archivar:
              onArchivar();
            case _AccionPaciente.verArchivados:
              onVerArchivados();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _AccionPaciente.cambiar,
            child: ListTile(
              leading: Icon(
                Icons.swap_horiz_rounded,
                color: Paleta.doradoOscuro,
              ),
              title: Text(
                'Cambiar paciente',
                style: TextStyle(
                  color: Paleta.doradoOscuro,
                  fontWeight: FontWeight.w700,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: _AccionPaciente.agregar,
            child: ListTile(
              leading: Icon(Icons.person_add_alt_1_outlined),
              title: Text('Agregar paciente'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: _AccionPaciente.editar,
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar paciente'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          PopupMenuItem(
            value: _AccionPaciente.eliminar,
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: Paleta.error),
              title: Text(
                'Eliminar paciente',
                style: TextStyle(
                  color: Paleta.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          PopupMenuItem(
            value: _AccionPaciente.archivar,
            child: ListTile(
              leading: Icon(Icons.archive_outlined, color: Paleta.doradoOscuro),
              title: Text(
                'Archivar paciente',
                style: TextStyle(
                  color: Paleta.doradoOscuro,
                  fontWeight: FontWeight.w700,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _AccionPaciente.verArchivados,
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(
                archivadosCount == 0
                    ? 'Ver archivados'
                    : 'Ver archivados ($archivadosCount)',
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
          child: Icon(Icons.more_vert_rounded, color: Paleta.sobreDorado),
        ),
        color: Paleta.tarjeta,
      ),
    );
  }
}

class _TarjetaContactoSeccion extends StatelessWidget {
  const _TarjetaContactoSeccion({
    required this.icono,
    required this.etiqueta,
    required this.titulo,
    required this.direccion,
    required this.telefono,
    required this.alLlamar,
    required this.alAbrirMapa,
  });

  final IconData icono;
  final String etiqueta;
  final String titulo;
  final String direccion;
  final String telefono;
  final Future<void> Function(String telefono) alLlamar;
  final Future<void> Function(String direccion) alAbrirMapa;

  @override
  Widget build(BuildContext context) {
    return TarjetaContacto(
      icono: icono,
      etiqueta: etiqueta,
      titulo: titulo,
      direccion: direccion,
      telefono: telefono,
      alLlamar: telefono.isNotEmpty ? () => alLlamar(telefono) : null,
      alAbrirMapa: () => alAbrirMapa(direccion),
    );
  }
}
