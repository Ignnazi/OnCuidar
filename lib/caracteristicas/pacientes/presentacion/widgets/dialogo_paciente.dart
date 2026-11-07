import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oncuidar/caracteristicas/pacientes/datos/repositorio_pacientes.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/fecha_nacimiento.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/widgets/boton_fecha_nacimiento.dart';
import 'package:oncuidar/compartido/widgets/aviso_app.dart';
import 'package:oncuidar/compartido/widgets/boton_principal.dart';
import 'package:oncuidar/compartido/widgets/campos_formulario.dart';
import 'package:oncuidar/compartido/widgets/hoja_dialogo.dart';
import 'package:oncuidar/compartido/widgets/titulo_seccion.dart';
import 'package:oncuidar/nucleo/utilidades/rut.dart';

Future<void> mostrarDialogoPaciente(
  BuildContext context, {
  Paciente? paciente,
  required RepositorioPacientes repositorio,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PopScope(
      canPop: false,
      child: _DialogoPaciente(paciente: paciente, repositorio: repositorio),
    ),
  );
}

class _DialogoPaciente extends StatefulWidget {
  const _DialogoPaciente({required this.paciente, required this.repositorio});

  final Paciente? paciente;
  final RepositorioPacientes repositorio;

  @override
  State<_DialogoPaciente> createState() => _DialogoPacienteState();
}

class _DialogoPacienteState extends State<_DialogoPaciente> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _rutController;
  late final TextEditingController _nacimientoController;
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
    _nombreController = TextEditingController(
      text: paciente?.nombreCompleto ?? '',
    );
    _rutController = TextEditingController(text: paciente?.rut ?? '');
    final nacimiento = paciente?.fechaNacimiento;
    _nacimientoController = TextEditingController(
      text: nacimiento == null ? '' : formatearFechaNacimiento(nacimiento),
    );
    _diagnosticoController = TextEditingController(
      text: paciente?.diagnostico ?? '',
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
    _nacimientoController.dispose();
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
    final aviso = AvisoApp.capturar(context);
    final nav = Navigator.of(context);
    final nacimiento = leerFechaNacimiento(_nacimientoController.text)!;
    final datos = <String, dynamic>{
      'nombreCompleto': _nombreController.text.trim(),
      'rut': _rutController.text.trim(),
      'fechaNacimiento': fechaNacimientoGuardada(nacimiento),
      'edad': edadEnAnios(nacimiento, DateTime.now()),
      'diagnostico': _diagnosticoController.text.trim(),
      'tratamientoFase': _faseController.text.trim(),
      'centroSaludNombre': _centroNombreController.text.trim(),
      'centroSaludDireccion': _centroDireccionController.text.trim(),
      'centroSaludTelefono': _centroTelefonoController.text.trim(),
      'contactoEmergenciaNombre': _emergenciaNombreController.text.trim(),
      'contactoEmergenciaTelefono': _emergenciaTelefonoController.text.trim(),
    };
    final repositorio = widget.repositorio;
    final esEdicion = _esEdicion;
    final paciente = widget.paciente;
    nav.pop();
    unawaited(
      _guardarEnBackground(
        aviso,
        repositorio: repositorio,
        datos: datos,
        esEdicion: esEdicion,
        paciente: paciente,
      ),
    );
  }

  Future<void> _guardarEnBackground(
    AvisoCapturado aviso, {
    required RepositorioPacientes repositorio,
    required Map<String, dynamic> datos,
    required bool esEdicion,
    required Paciente? paciente,
  }) async {
    try {
      if (esEdicion && paciente != null) {
        await repositorio.actualizarPaciente(paciente.id, datos);
      } else {
        await repositorio.crearPaciente(
          Paciente(
            id: '',
            nombreCompleto: datos['nombreCompleto'] as String,
            rut: datos['rut'] as String?,
            edad: datos['edad'] as int?,
            fechaNacimiento: DateTime.tryParse(
              datos['fechaNacimiento'] as String,
            ),
            diagnostico: datos['diagnostico'] as String?,
            tratamientoFase: datos['tratamientoFase'] as String?,
            centroSaludNombre: datos['centroSaludNombre'] as String?,
            centroSaludDireccion: datos['centroSaludDireccion'] as String?,
            centroSaludTelefono: datos['centroSaludTelefono'] as String?,
            contactoEmergenciaNombre:
                datos['contactoEmergenciaNombre'] as String?,
            contactoEmergenciaTelefono:
                datos['contactoEmergenciaTelefono'] as String?,
            creadoEn: DateTime.now(),
          ),
        );
      }
      aviso.info(
        esEdicion
            ? 'Los datos del paciente se actualizaron.'
            : 'El paciente se agregó correctamente.',
      );
    } catch (_) {
      aviso.alerta('No se pudo guardar. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HojaDialogo(
      icono: _esEdicion ? Icons.edit_outlined : Icons.person_add_outlined,
      titulo: _esEdicion ? 'Editar paciente' : 'Agregar paciente',
      tamanoInicial: 0.85,
      tamanoMinimo: 0.55,
      tamanoMaximo: 0.95,
      cuerpo: (ctx, scrollController) => [
        FormularioDeHoja(
          formKey: _formKey,
          controlador: scrollController,
          margenSuperior: 0,
          hijos: [
            const TituloSeccion(Icons.person_outline, 'Datos del paciente'),
            const SizedBox(height: 10),
            CampoFormulario(
              controlador: _nombreController,
              textoAyuda: 'Nombre completo *',
              icono: Icons.badge_outlined,
              validador: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
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
              controlador: _nacimientoController,
              textoAyuda: 'Fecha de nacimiento (dd/mm/aaaa) *',
              icono: Icons.cake_outlined,
              tipoTeclado: TextInputType.datetime,
              accionTeclado: TextInputAction.next,
              iconoSufijo: BotonFechaNacimiento(
                controlador: _nacimientoController,
              ),
              validador: validarFechaNacimiento,
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
            const TituloSeccion(
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
            const TituloSeccion(
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
                    etiqueta: _esEdicion ? 'Guardar cambios' : 'Guardar',
                    alPulsar: _guardar,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
