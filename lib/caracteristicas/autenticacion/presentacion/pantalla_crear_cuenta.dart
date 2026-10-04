import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/app/enrutador/destino_aviso.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/proveedores_autenticacion.dart';
import 'package:oncuidar/caracteristicas/autenticacion/datos/servicio_alta_cuenta.dart';
import 'package:oncuidar/caracteristicas/autenticacion/dominio/validaciones_registro.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/formulario_registro.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/widgets/botones_acceso.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/widgets/campos_registro.dart';
import 'package:oncuidar/compartido/widgets/campos_formulario.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';

class Registro extends ConsumerStatefulWidget {
  const Registro({super.key});

  @override
  ConsumerState<Registro> createState() => _RegistroState();
}

class _RegistroState extends ConsumerState<Registro> {
  final _formKey = GlobalKey<FormState>();
  final _formulario = FormularioRegistro();
  bool _ocultarContrasena = true;
  bool _ocultarConfirmar = true;
  bool _cargando = false;

  @override
  void dispose() {
    _formulario.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final resultado = await ref
        .read(servicioRegistroProvider)
        .registrar(_formulario.aDatos());

    switch (resultado) {
      case RegistroExitoso():
        if (mounted) {
          FocusManager.instance.primaryFocus?.unfocus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Cuenta creada exitosamente!'),
              backgroundColor: Paleta.doradoPrincipal,
            ),
          );
          context.go(EstadoArranque.consumirDestino());
        }
      case RegistroFallido(:final mensaje):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensaje), backgroundColor: Paleta.error),
          );
        }
    }

    if (mounted) setState(() => _cargando = false);
  }

  List<Widget> _camposCuidador() {
    final f = _formulario;
    return [
      CampoEtiquetado(
        etiqueta: 'Nombre completo',
        controlador: f.nombre,
        textoAyuda: 'Nombre completo',
        icono: Icons.badge_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) => validarObligatorio(v, 'Ingresa tu nombre'),
      ),
      DesplegableEtiquetado(
        etiqueta: 'Relación con el paciente',
        valor: f.relacion,
        opciones: relacionesCuidador,
        icono: Icons.family_restroom_outlined,
        alCambiar: (v) => setState(() => f.relacion = v),
        mensajeValidacion: 'Selecciona una relación',
      ),
      if (f.relacion == 'Otro')
        CampoEtiquetado(
          etiqueta: 'Especifica la relación',
          controlador: f.relacionOtro,
          textoAyuda: 'Ej: Madrastra, Abuelo(a), Hermano(a)',
          icono: Icons.edit_outlined,
          accionTeclado: TextInputAction.next,
          validador: (v) => validarObligatorio(v, 'Especifica la relación'),
        ),
      CampoEtiquetado(
        etiqueta: 'Teléfono',
        controlador: f.telefono,
        textoAyuda: '+56 9 0000 0000',
        icono: Icons.phone_outlined,
        tipoTeclado: TextInputType.phone,
        accionTeclado: TextInputAction.next,
        validador: (v) => validarObligatorio(v, 'Ingresa un teléfono'),
      ),
      CampoEtiquetado(
        etiqueta: 'Dirección',
        controlador: f.direccion,
        textoAyuda: 'Dirección del cuidador',
        icono: Icons.location_on_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) => validarObligatorio(v, 'Ingresa la dirección'),
      ),
      CampoEtiquetado(
        etiqueta: 'Correo electrónico',
        controlador: f.correo,
        textoAyuda: 'correo@ejemplo.com',
        icono: Icons.email_outlined,
        tipoTeclado: TextInputType.emailAddress,
        accionTeclado: TextInputAction.next,
        validador: validarCorreo,
      ),
      CampoEtiquetado(
        etiqueta: 'Correo de respaldo',
        controlador: f.correoRespaldo,
        textoAyuda: 'Para recuperar tu contraseña',
        icono: Icons.lock_reset_outlined,
        tipoTeclado: TextInputType.emailAddress,
        accionTeclado: TextInputAction.next,
        validador: validarCorreo,
      ),
      CampoEtiquetado(
        etiqueta: 'Contraseña',
        controlador: f.contrasena,
        textoAyuda: 'Mínimo 6 caracteres',
        icono: Icons.lock_outlined,
        oculto: _ocultarContrasena,
        iconoSufijo: BotonVerContrasena(
          oculta: _ocultarContrasena,
          alPulsar: () =>
              setState(() => _ocultarContrasena = !_ocultarContrasena),
        ),
        accionTeclado: TextInputAction.next,
        validador: validarContrasena,
      ),
      CampoEtiquetado(
        etiqueta: 'Confirmar contraseña',
        controlador: f.confirmar,
        textoAyuda: 'Repite tu contraseña',
        icono: Icons.lock_outlined,
        oculto: _ocultarConfirmar,
        iconoSufijo: BotonVerContrasena(
          oculta: _ocultarConfirmar,
          alPulsar: () =>
              setState(() => _ocultarConfirmar = !_ocultarConfirmar),
        ),
        accionTeclado: TextInputAction.next,
        validador: (v) => validarConfirmacion(v, f.contrasena.text),
      ),
    ];
  }

  List<Widget> _camposPaciente() {
    final f = _formulario;
    return [
      CampoEtiquetado(
        etiqueta: 'Nombre del paciente',
        controlador: f.nombrePaciente,
        textoAyuda: 'Nombre completo',
        icono: Icons.person_outline,
        accionTeclado: TextInputAction.next,
        validador: (v) =>
            validarObligatorio(v, 'Ingresa el nombre del paciente'),
      ),
      CampoRut(controlador: f.rut),
      CampoEtiquetado(
        etiqueta: 'Edad',
        controlador: f.edad,
        textoAyuda: 'Años',
        icono: Icons.cake_outlined,
        tipoTeclado: TextInputType.number,
        accionTeclado: TextInputAction.next,
        validador: validarEdad,
      ),
      CampoEtiquetado(
        etiqueta: 'Diagnóstico',
        controlador: f.diagnostico,
        textoAyuda: 'Tipo de cáncer / diagnóstico',
        icono: Icons.medical_information_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) => validarObligatorio(v, 'Ingresa el diagnóstico'),
      ),
      DesplegableEtiquetado(
        etiqueta: 'Fase de tratamiento',
        valor: f.faseTratamiento,
        opciones: fasesTratamiento,
        icono: Icons.healing_outlined,
        alCambiar: (v) => setState(() => f.faseTratamiento = v),
        mensajeValidacion: 'Selecciona la fase',
      ),
      if (f.faseTratamiento == 'Otro')
        CampoEtiquetado(
          etiqueta: 'Especifica la fase',
          controlador: f.faseOtro,
          textoAyuda: 'Ej: Terapia de mantención, Control',
          icono: Icons.healing_outlined,
          accionTeclado: TextInputAction.done,
          validador: (v) => validarObligatorio(v, 'Especifica la fase'),
        ),
    ];
  }

  List<Widget> _camposApoyo() {
    final f = _formulario;
    return [
      CampoEtiquetado(
        etiqueta: 'Centro de salud',
        controlador: f.centroNombre,
        textoAyuda: 'Nombre del centro',
        icono: Icons.apartment_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) => validarObligatorio(v, 'Ingresa el nombre del centro'),
      ),
      CampoEtiquetado(
        etiqueta: 'Dirección del centro',
        controlador: f.centroDireccion,
        textoAyuda: 'Dirección del centro',
        icono: Icons.location_on_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) =>
            validarObligatorio(v, 'Ingresa la dirección del centro'),
      ),
      CampoEtiquetado(
        etiqueta: 'Tel. contacto del centro',
        controlador: f.centroTelefono,
        textoAyuda: '+56 2 0000 0000',
        icono: Icons.phone_outlined,
        tipoTeclado: TextInputType.phone,
        accionTeclado: TextInputAction.next,
        validador: (v) =>
            validarObligatorio(v, 'Ingresa un teléfono del centro'),
      ),
      CampoEtiquetado(
        etiqueta: 'Contacto de emergencia',
        controlador: f.contactoEmergenciaNombre,
        textoAyuda: 'Nombre de la persona',
        icono: Icons.contact_emergency_outlined,
        accionTeclado: TextInputAction.next,
        validador: (v) =>
            validarObligatorio(v, 'Ingresa un nombre de contacto'),
      ),
      CampoEtiquetado(
        etiqueta: 'Tel. de urgencia',
        controlador: f.urgenciaTelefono,
        textoAyuda: '+56 2 0000 0000',
        icono: Icons.emergency_outlined,
        tipoTeclado: TextInputType.phone,
        accionTeclado: TextInputAction.done,
        validador: (v) =>
            validarObligatorio(v, 'Ingresa un teléfono de urgencia'),
      ),
    ];
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
                      BotonDegradado(
                        etiqueta: 'Guardar y continuar',
                        cargando: _cargando,
                        alPulsar: _guardar,
                      ),
                      const SizedBox(height: 16),
                      EnlaceAcceso(
                        pregunta: '¿Ya tienes cuenta? ',
                        accion: 'Iniciar sesión',
                        alPulsar: () => context.go('/iniciar-sesion'),
                      ),
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
