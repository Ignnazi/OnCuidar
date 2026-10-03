import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../compartidos/widgets/campos_formulario.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/router/destino_aviso.dart';
import '../../core/servicios/servicio_registro.dart';
import '../../core/tema/paleta.dart';
import '../../core/utilidades/rut_utils.dart';
import '../../core/utilidades/validacion_correo.dart';
import '../../modelos/paciente.dart';

const _relaciones = ['Madre', 'Padre', 'Tutor', 'Otro'];

const _fasesTratamiento = [
  'Diagnóstico',
  'Tratamiento',
  'Remisión',
  'Cuidados paliativos',
  'No aplica',
  'Otro',
];

String? _validarObligatorio(String? v, String mensaje) =>
    v == null || v.trim().isEmpty ? mensaje : null;

String? _validarCorreo(String? v, {bool opcional = false}) {
  final valor = v?.trim() ?? '';
  if (valor.isEmpty) return opcional ? null : 'Ingresa tu correo';
  return regexCorreo.hasMatch(valor) ? null : 'Ingresa un correo válido';
}

String? _validarContrasena(String? v) {
  if (v == null || v.isEmpty) return 'Ingresa una contraseña';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

class Registro extends ConsumerStatefulWidget {
  const Registro({super.key});

  @override
  ConsumerState<Registro> createState() => _RegistroState();
}

class _RegistroState extends ConsumerState<Registro> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _correoController = TextEditingController();
  final _correoRespaldoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarController = TextEditingController();

  final _nombrePacienteController = TextEditingController();
  final _rutController = TextEditingController();
  final _edadController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  final _contactoEmergenciaNombreController = TextEditingController();

  final _centroNombreController = TextEditingController();
  final _centroDireccionController = TextEditingController();
  final _centroTelefonoController = TextEditingController();
  final _urgenciaTelefonoController = TextEditingController();

  final _relacionOtroController = TextEditingController();
  final _faseOtroController = TextEditingController();

  String? _relacion;
  String? _faseTratamiento;
  bool _ocultarContrasena = true;
  bool _ocultarConfirmar = true;
  bool _cargando = false;

  late final List<TextEditingController> _controllers = [
    _nombreController,
    _telefonoController,
    _direccionController,
    _correoController,
    _correoRespaldoController,
    _contrasenaController,
    _confirmarController,
    _nombrePacienteController,
    _rutController,
    _edadController,
    _diagnosticoController,
    _contactoEmergenciaNombreController,
    _centroNombreController,
    _centroDireccionController,
    _centroTelefonoController,
    _urgenciaTelefonoController,
    _relacionOtroController,
    _faseOtroController,
  ];

  @override
  void dispose() {
    for (final controlador in _controllers) {
      controlador.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final resultado = await ref
        .read(servicioRegistroProvider)
        .registrar(
          DatosRegistro(
            nombre: _nombreController.text.trim(),
            correo: _correoController.text.trim(),
            telefono: _telefonoController.text.trim(),
            relacion: _relacion == 'Otro'
                ? _relacionOtroController.text.trim()
                : _relacion,
            correoRespaldo: _correoRespaldoController.text.trim(),
            direccion: _direccionController.text.trim(),
            contrasena: _contrasenaController.text,
            paciente: Paciente(
              id: 'auto',
              fullName: _nombrePacienteController.text.trim(),
              rut: _rutController.text.trim(),
              age: int.tryParse(_edadController.text.trim()),
              diagnosis: _diagnosticoController.text.trim(),
              tratamientoFase: _faseTratamiento == 'Otro'
                  ? _faseOtroController.text.trim()
                  : _faseTratamiento,
              contactoEmergenciaNombre: _contactoEmergenciaNombreController.text
                  .trim(),
              centroSaludNombre: _centroNombreController.text.trim(),
              centroSaludDireccion: _centroDireccionController.text.trim(),
              centroSaludTelefono: _centroTelefonoController.text.trim(),
              contactoEmergenciaTelefono: _urgenciaTelefonoController.text
                  .trim(),
              createdAt: DateTime.now(),
            ),
          ),
        );

    switch (resultado) {
      case RegistroExitoso():
        if (mounted) {
          FocusManager.instance.primaryFocus?.unfocus();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta creada exitosamente!'),
              backgroundColor: Paleta.doradoPrincipal,
            ),
          );
          context.go(EstadoArranque.consumirDestino());
        }
        break;
      case RegistroFallido(:final mensaje):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensaje), backgroundColor: Paleta.error),
          );
        }
        break;
    }

    if (mounted) setState(() => _cargando = false);
  }

  String? _validarConfirmacion(String? v) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != _contrasenaController.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Widget _campoEtiquetado({
    required String etiqueta,
    required TextEditingController controlador,
    required String textoAyuda,
    required IconData icono,
    TextInputType? tipoTeclado,
    TextInputAction? accionTeclado,
    bool oculto = false,
    Widget? iconoSufijo,
    String? Function(String?)? validador,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtiquetaCampo(texto: etiqueta),
        const SizedBox(height: 8),
        CampoFormulario(
          controlador: controlador,
          textoAyuda: textoAyuda,
          icono: icono,
          tipoTeclado: tipoTeclado,
          accionTeclado: accionTeclado,
          oculto: oculto,
          iconoSufijo: iconoSufijo,
          validador: validador,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _dropdownEtiquetado({
    required String etiqueta,
    required String? valor,
    required List<String> opciones,
    required IconData icono,
    required ValueChanged<String?> alCambiar,
    required String mensajeValidacion,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtiquetaCampo(texto: etiqueta),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          decoration: decoracionEntrada(
            textoAyuda: 'Seleccionar',
            icono: icono,
          ),
          items: opciones
              .map(
                (opcion) => DropdownMenuItem(
                  value: opcion,
                  child: Text(opcion, style: GoogleFonts.nunito(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: alCambiar,
          validator: (v) => v == null ? mensajeValidacion : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _campoRut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EtiquetaCampo(texto: 'RUT del paciente'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _rutController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
            LengthLimitingTextInputFormatter(9),
            TextInputFormatter.withFunction((valorAnterior, valorNuevo) {
              final formateado = formatearRut(valorNuevo.text);
              if (formateado == valorNuevo.text) return valorNuevo;
              return TextEditingValue(
                text: formateado,
                selection: TextSelection.collapsed(offset: formateado.length),
              );
            }),
          ],
          validator: (v) {
            final valor = (v ?? '').trim();
            if (valor.isEmpty) return 'Ingresa el RUT del paciente';
            if (!validarRut(valor)) return 'RUT no válido';
            return null;
          },
          style: GoogleFonts.nunito(fontSize: 14, color: Paleta.textoPrincipal),
          decoration: decoracionEntrada(
            textoAyuda: '12.345.678-9',
            icono: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _camposCuidador() {
    return [
      _campoEtiquetado(
        etiqueta: 'Nombre completo',
        controlador: _nombreController,
        textoAyuda: 'Nombre completo',
        icono: Icons.badge_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) => _validarObligatorio(v, 'Ingresa tu nombre'),
      ),
      _dropdownEtiquetado(
        etiqueta: 'Relación con el paciente',
        valor: _relacion,
        opciones: _relaciones,
        icono: Icons.family_restroom_outlined,
        alCambiar: (v) => setState(() => _relacion = v),
        mensajeValidacion: 'Selecciona una relación',
      ),
      if (_relacion == 'Otro')
        _campoEtiquetado(
          etiqueta: 'Especifica la relación',
          controlador: _relacionOtroController,
          textoAyuda: 'Ej: Madrastra, Abuelo(a), Hermano(a)',
          icono: Icons.edit_outlined,
          accionTeclado: TextInputAction.next,
          validador: (v) => _validarObligatorio(v, 'Especifica la relación'),
        ),
      _campoEtiquetado(
        etiqueta: 'Teléfono',
        controlador: _telefonoController,
        textoAyuda: '+56 9 0000 0000',
        icono: Icons.phone_outlined,
        tipoTeclado: TextInputType.phone,
        accionTeclado: TextInputAction.next,
        validador: (v) => _validarObligatorio(v, 'Ingresa un teléfono'),
      ),
      _campoEtiquetado(
        etiqueta: 'Dirección',
        controlador: _direccionController,
        textoAyuda: 'Dirección del cuidador',
        icono: Icons.location_on_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) => _validarObligatorio(v, 'Ingresa la dirección'),
      ),
      _campoEtiquetado(
        etiqueta: 'Correo electrónico',
        controlador: _correoController,
        textoAyuda: 'correo@ejemplo.com',
        icono: Icons.email_outlined,
        tipoTeclado: TextInputType.emailAddress,
        accionTeclado: TextInputAction.next,
        validador: _validarCorreo,
      ),
      _campoEtiquetado(
        etiqueta: 'Correo de respaldo',
        controlador: _correoRespaldoController,
        textoAyuda: 'Para recuperar tu contraseña',
        icono: Icons.lock_reset_outlined,
        tipoTeclado: TextInputType.emailAddress,
        accionTeclado: TextInputAction.next,
        validador: _validarCorreo,
      ),
      _campoEtiquetado(
        etiqueta: 'Contraseña',
        controlador: _contrasenaController,
        textoAyuda: 'Mínimo 6 caracteres',
        icono: Icons.lock_outlined,
        oculto: _ocultarContrasena,
        iconoSufijo: IconButton(
          icon: Icon(
            _ocultarContrasena
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _ocultarContrasena = !_ocultarContrasena),
        ),
        accionTeclado: TextInputAction.next,
        validador: _validarContrasena,
      ),
      _campoEtiquetado(
        etiqueta: 'Confirmar contraseña',
        controlador: _confirmarController,
        textoAyuda: 'Repite tu contraseña',
        icono: Icons.lock_outlined,
        oculto: _ocultarConfirmar,
        iconoSufijo: IconButton(
          icon: Icon(
            _ocultarConfirmar
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _ocultarConfirmar = !_ocultarConfirmar),
        ),
        accionTeclado: TextInputAction.next,
        validador: _validarConfirmacion,
      ),
    ];
  }

  List<Widget> _camposPaciente() {
    return [
      _campoEtiquetado(
        etiqueta: 'Nombre del paciente',
        controlador: _nombrePacienteController,
        textoAyuda: 'Nombre completo',
        icono: Icons.person_outline,
        accionTeclado: TextInputAction.next,
        validador: (v) =>
            _validarObligatorio(v, 'Ingresa el nombre del paciente'),
      ),
      _campoRut(),
      _campoEtiquetado(
        etiqueta: 'Edad',
        controlador: _edadController,
        textoAyuda: 'Años',
        icono: Icons.cake_outlined,
        tipoTeclado: TextInputType.number,
        accionTeclado: TextInputAction.next,
        validador: (v) {
          if (v == null || v.trim().isEmpty) return 'Ingresa la edad';
          final edad = int.tryParse(v.trim());
          if (edad == null || edad < 0 || edad > 120) return 'Edad no válida';
          return null;
        },
      ),
      _campoEtiquetado(
        etiqueta: 'Diagnóstico',
        controlador: _diagnosticoController,
        textoAyuda: 'Tipo de cáncer / diagnóstico',
        icono: Icons.medical_information_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) => _validarObligatorio(v, 'Ingresa el diagnóstico'),
      ),
      _dropdownEtiquetado(
        etiqueta: 'Fase de tratamiento',
        valor: _faseTratamiento,
        opciones: _fasesTratamiento,
        icono: Icons.healing_outlined,
        alCambiar: (v) => setState(() => _faseTratamiento = v),
        mensajeValidacion: 'Selecciona la fase',
      ),
      if (_faseTratamiento == 'Otro')
        _campoEtiquetado(
          etiqueta: 'Especifica la fase',
          controlador: _faseOtroController,
          textoAyuda: 'Ej: Terapia de mantención, Control',
          icono: Icons.healing_outlined,
          accionTeclado: TextInputAction.done,
          validador: (v) => _validarObligatorio(v, 'Especifica la fase'),
        ),
    ];
  }

  List<Widget> _camposApoyo() {
    return [
      _campoEtiquetado(
        etiqueta: 'Centro de salud',
        controlador: _centroNombreController,
        textoAyuda: 'Nombre del centro',
        icono: Icons.apartment_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) =>
            _validarObligatorio(v, 'Ingresa el nombre del centro'),
      ),
      _campoEtiquetado(
        etiqueta: 'Dirección del centro',
        controlador: _centroDireccionController,
        textoAyuda: 'Dirección del centro',
        icono: Icons.location_on_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) =>
            _validarObligatorio(v, 'Ingresa la dirección del centro'),
      ),
      _campoEtiquetado(
        etiqueta: 'Tel. contacto del centro',
        controlador: _centroTelefonoController,
        textoAyuda: '+56 2 0000 0000',
        icono: Icons.phone_outlined,
        tipoTeclado: TextInputType.phone,
        accionTeclado: TextInputAction.next,
        validador: (v) =>
            _validarObligatorio(v, 'Ingresa un teléfono del centro'),
      ),
      _campoEtiquetado(
        etiqueta: 'Contacto de emergencia',
        controlador: _contactoEmergenciaNombreController,
        textoAyuda: 'Nombre de la persona',
        icono: Icons.contact_emergency_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) =>
            _validarObligatorio(v, 'Ingresa un nombre de contacto'),
      ),
      _campoEtiquetado(
        etiqueta: 'Tel. de urgencia',
        controlador: _urgenciaTelefonoController,
        textoAyuda: '+56 2 0000 0000',
        icono: Icons.emergency_outlined,
        tipoTeclado: TextInputType.phone,
        accionTeclado: TextInputAction.done,
        validador: (v) =>
            _validarObligatorio(v, 'Ingresa un teléfono de urgencia'),
      ),
    ];
  }

  Widget _botonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Opacity(
        opacity: _cargando ? 0.6 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Paleta.doradoPrincipal, Paleta.doradoOscuro],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoPrincipal.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _cargando ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _cargando
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Guardar y continuar',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _enlaceIniciarSesion() {
    return Center(
      child: TextButton(
        onPressed: () => context.go('/iniciar-sesion'),
        child: Text.rich(
          TextSpan(
            text: '¿Ya tienes cuenta? ',
            style: GoogleFonts.nunito(
              color: Paleta.textoSecundario,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: 'Iniciar sesión',
                style: GoogleFonts.nunito(
                  color: Paleta.doradoOscuro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/bienvenida');
      },
      child: Scaffold(
        backgroundColor: Paleta.crema,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 100 + 8,
                  20,
                  24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TarjetaSeccion(
                        icono: Icons.person_rounded,
                        titulo: 'Datos del cuidador',
                        hijos: _camposCuidador(),
                      ),
                      const SizedBox(height: 16),
                      TarjetaSeccion(
                        icono: Icons.child_care_rounded,
                        titulo: 'Datos del paciente',
                        hijos: _camposPaciente(),
                      ),
                      const SizedBox(height: 16),
                      TarjetaSeccion(
                        icono: Icons.local_hospital_outlined,
                        titulo: 'Información de apoyo',
                        hijos: _camposApoyo(),
                      ),
                      const SizedBox(height: 28),
                      _botonGuardar(),
                      const SizedBox(height: 16),
                      _enlaceIniciarSesion(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EncabezadoGradiente(
                titulo: 'Crear tu perfil',
                subtitulo: 'Completa todos los datos',
                logo: AssetImage('assets/images/OnCuidar.png'),
                tamanoTitulo: 20,
                alto: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
