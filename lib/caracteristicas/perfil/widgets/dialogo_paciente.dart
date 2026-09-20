import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/servicios/servicio_base_datos.dart';
import '../../../core/tema/paleta.dart';
import '../../../core/utilidades/rut_utils.dart';
import '../../../modelos/paciente.dart';
import '../../../compartidos/widgets/boton_principal.dart';
import '../../../compartidos/widgets/campos_formulario.dart';
import '../../../compartidos/widgets/titulo_seccion.dart';

Future<void> mostrarDialogoPaciente(
  BuildContext context, {
  Paciente? paciente,
  required ServicioBaseDatos servicio,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PopScope(
      canPop: false,
      child: _DialogoPaciente(
        paciente: paciente,
        servicio: servicio,
      ),
    ),
  );
}

class _DialogoPaciente extends StatefulWidget {
  const _DialogoPaciente({
    required this.paciente,
    required this.servicio,
  });

  final Paciente? paciente;
  final ServicioBaseDatos servicio;

  @override
  State<_DialogoPaciente> createState() => _DialogoPacienteState();
}

class _DialogoPacienteState extends State<_DialogoPaciente> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _rutController;
  late final TextEditingController _edadController;
  late final TextEditingController _diagnosticoController;
  late final TextEditingController _faseController;
  late final TextEditingController _centroNombreController;
  late final TextEditingController _centroDireccionController;
  late final TextEditingController _centroTelefonoController;
  late final TextEditingController _emergenciaNombreController;
  late final TextEditingController _emergenciaTelefonoController;

  bool get _esEdicion => widget.paciente != null;

  @override
  void initState() {
    super.initState();
    final paciente = widget.paciente;
    _nombreController = TextEditingController(text: paciente?.fullName ?? '');
    _rutController = TextEditingController(text: paciente?.rut ?? '');
    _edadController = TextEditingController(
      text: paciente?.age?.toString() ?? '',
    );
    _diagnosticoController = TextEditingController(
      text: paciente?.diagnosis ?? '',
    );
    _faseController = TextEditingController(
      text: paciente?.tratamientoFase ?? '',
    );
    _centroNombreController = TextEditingController(
      text: paciente?.centroSaludNombre ?? '',
    );
    _centroDireccionController = TextEditingController(
      text: paciente?.centroSaludDireccion ?? '',
    );
    _centroTelefonoController = TextEditingController(
      text: paciente?.centroSaludTelefono ?? '',
    );
    _emergenciaNombreController = TextEditingController(
      text: paciente?.contactoEmergenciaNombre ?? '',
    );
    _emergenciaTelefonoController = TextEditingController(
      text: paciente?.contactoEmergenciaTelefono ?? '',
    );
    _rutController.addListener(_aplicarMascaraRut);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rutController.dispose();
    _edadController.dispose();
    _diagnosticoController.dispose();
    _faseController.dispose();
    _centroNombreController.dispose();
    _centroDireccionController.dispose();
    _centroTelefonoController.dispose();
    _emergenciaNombreController.dispose();
    _emergenciaTelefonoController.dispose();
    super.dispose();
  }

  void _aplicarMascaraRut() {
    final texto = _rutController.text;
    final formateado = formatearRut(texto);
    if (formateado != texto) {
      _rutController.value = TextEditingValue(
        text: formateado,
        selection: TextSelection.collapsed(offset: formateado.length),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final datos = <String, dynamic>{
      'fullName': _nombreController.text.trim(),
      'rut': _rutController.text.trim(),
      'age': int.tryParse(_edadController.text.trim()),
      'diagnosis': _diagnosticoController.text.trim(),
      'tratamientoFase': _faseController.text.trim(),
      'centroSaludNombre': _centroNombreController.text.trim(),
      'centroSaludDireccion': _centroDireccionController.text.trim(),
      'centroSaludTelefono': _centroTelefonoController.text.trim(),
      'contactoEmergenciaNombre': _emergenciaNombreController.text.trim(),
      'contactoEmergenciaTelefono': _emergenciaTelefonoController.text.trim(),
    };
    final servicio = widget.servicio;
    final esEdicion = _esEdicion;
    final paciente = widget.paciente;
    nav.pop();
    unawaited(_guardarEnBackground(
      messenger,
      servicio: servicio,
      datos: datos,
      esEdicion: esEdicion,
      paciente: paciente,
    ));
  }

  Future<void> _guardarEnBackground(
    ScaffoldMessengerState messenger, {
    required ServicioBaseDatos servicio,
    required Map<String, dynamic> datos,
    required bool esEdicion,
    required Paciente? paciente,
  }) async {
    try {
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            esEdicion ? 'Paciente actualizado' : 'Paciente agregado',
          ),
          backgroundColor: Paleta.doradoPrincipal,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar. Intenta de nuevo.'),
          backgroundColor: Paleta.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
                      _esEdicion
                          ? Icons.edit_outlined
                          : Icons.person_add_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _esEdicion ? 'Editar paciente' : 'Agregar paciente',
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
                key: _formKey,
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
                      controlador: _nombreController,
                      textoAyuda: 'Nombre completo *',
                      icono: Icons.badge_outlined,
                      validador: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa el nombre'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CampoFormulario(
                      controlador: _rutController,
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
                      controlador: _edadController,
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
                      controlador: _diagnosticoController,
                      textoAyuda: 'Diagnóstico *',
                      icono: Icons.medical_information_outlined,
                      accionTeclado: TextInputAction.next,
                      validador: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa el diagnóstico'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CampoFormulario(
                      controlador: _faseController,
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
                      controlador: _centroNombreController,
                      textoAyuda: 'Nombre del centro *',
                      icono: Icons.local_hospital_outlined,
                      accionTeclado: TextInputAction.next,
                      validador: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa el nombre del centro'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CampoFormulario(
                      controlador: _centroDireccionController,
                      textoAyuda: 'Dirección *',
                      icono: Icons.location_on_outlined,
                      accionTeclado: TextInputAction.next,
                      validador: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa la dirección'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CampoFormulario(
                      controlador: _centroTelefonoController,
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
                      controlador: _emergenciaNombreController,
                      textoAyuda: 'Nombre del contacto *',
                      icono: Icons.person_outline,
                      accionTeclado: TextInputAction.next,
                      validador: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa el nombre del contacto'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CampoFormulario(
                      controlador: _emergenciaTelefonoController,
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
                            etiqueta: _esEdicion
                                ? 'Guardar cambios'
                                : 'Guardar',
                            alPulsar: _guardar,
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
    );
  }
}