import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/compartido/widgets/campos_formulario.dart';
import 'package:oncuidar/compartido/widgets/dialogo_confirmacion.dart';

Future<void> mostrarDialogoCambiarPaciente(
  BuildContext context, {
  required List<Paciente> pacientes,
  required String? idActual,
  required Future<void> Function(Paciente) alCambiar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _DialogoCambiarPaciente(
      pacientes: pacientes,
      idActual: idActual,
      alCambiar: alCambiar,
    ),
  );
}

class _DialogoCambiarPaciente extends StatefulWidget {
  const _DialogoCambiarPaciente({
    required this.pacientes,
    required this.idActual,
    required this.alCambiar,
  });

  final List<Paciente> pacientes;
  final String? idActual;
  final Future<void> Function(Paciente) alCambiar;

  @override
  State<_DialogoCambiarPaciente> createState() =>
      _DialogoCambiarPacienteState();
}

class _DialogoCambiarPacienteState extends State<_DialogoCambiarPaciente> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.pacientes
        .where(
          (p) => p.nombreCompleto.toLowerCase().contains(
            _busqueda.trim().toLowerCase(),
          ),
        )
        .toList();
    return SafeArea(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              textInputAction: TextInputAction.search,
              decoration: decoracionEntrada(
                textoAyuda: 'Buscar por nombre',
                icono: Icons.search_outlined,
              ),
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Paleta.textoPrincipal,
              ),
            ),
          ),
          Flexible(
            child: filtrados.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 40,
                            color: Paleta.textoSecundario,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No se encontraron pacientes',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: Paleta.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(
                      bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    children: [
                      for (final p in filtrados)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.id == widget.idActual
                                ? Paleta.doradoPrincipal
                                : Paleta.doradoClaro,
                            child: Text(
                              p.nombreCompleto.isNotEmpty
                                  ? p.nombreCompleto[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                color: p.id == widget.idActual
                                    ? Colors.white
                                    : Paleta.doradoOscuro,
                              ),
                            ),
                          ),
                          title: Text(
                            p.nombreCompleto,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: Paleta.textoPrincipal,
                            ),
                          ),
                          subtitle:
                              (p.diagnostico != null &&
                                  p.diagnostico!.isNotEmpty)
                              ? Text(
                                  p.diagnostico!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: Paleta.textoSecundario,
                                  ),
                                )
                              : null,
                          trailing: p.id == widget.idActual
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Paleta.doradoPrincipal,
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () async {
                            final nav = Navigator.of(context);
                            if (p.id != widget.idActual &&
                                !_pacienteTieneDatosCompletos(p)) {
                              final confirmar =
                                  await mostrarDialogoConfirmacion(
                                    context,
                                    icono: Icons.warning_amber_rounded,
                                    titulo: 'Datos incompletos',
                                    mensaje:
                                        '${p.nombreCompleto} no tiene todos '
                                        'los datos completos (nombre, '
                                        'RUT, edad, diagnóstico, fase, '
                                        'centro de salud y contacto de '
                                        'emergencia). ¿Cambiar a este '
                                        'paciente de todas formas?',
                                    textoConfirmar: 'Cambiar',
                                    colorConfirmar: Paleta.doradoOscuro,
                                    iconoConfirmar: Icons.swap_horiz_rounded,
                                  );
                              if (confirmar != true) return;
                            }
                            nav.pop();
                            if (p.id == widget.idActual) return;
                            await widget.alCambiar(p);
                          },
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

bool _pacienteTieneDatosCompletos(Paciente p) {
  bool lleno(String? v) => v != null && v.trim().isNotEmpty;
  return lleno(p.nombreCompleto) &&
      lleno(p.rut) &&
      p.edad != null &&
      lleno(p.diagnostico) &&
      lleno(p.tratamientoFase) &&
      lleno(p.centroSaludNombre) &&
      lleno(p.centroSaludDireccion) &&
      lleno(p.centroSaludTelefono) &&
      lleno(p.contactoEmergenciaNombre) &&
      lleno(p.contactoEmergenciaTelefono);
}
