import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/servicios/servicio_base_datos.dart';
import '../../core/tema/paleta.dart';
import '../../core/utilidades/validacion_correo.dart';
import '../../compartidos/widgets/boton_principal.dart';
import '../../compartidos/widgets/campos_formulario.dart';
import '../../compartidos/widgets/chip_franja.dart';
import '../../compartidos/widgets/titulo_seccion.dart';

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
    setState(() {
      _cargando = true;
      _error = false;
    });
    try {
      final base = ref.read(servicioBaseDatosProvider);
      final datos = await base.obtenerCuidador();
      await _confirmarCambioCorreoConfirmado(base, datos);
      final datosActualizados = await base.obtenerCuidador();
      if (!mounted) return;
      setState(() => _cuidador = datosActualizados);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Si el usuario ya confirmó el nuevo correo principal desde el enlace de
  /// verificación, el email de Auth ya cambió: sincronizamos el doc del
  /// cuidador y limpiamos el marcador de cambio pendiente.
  Future<void> _confirmarCambioCorreoConfirmado(
    ServicioBaseDatos base,
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
      await base.sincronizarCorreoPrincipal(correoPendiente);
      await base.limpiarCambioCorreoPendiente();
    }
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
          _mensajeError()
        else ...[
          _tarjetaPerfil(),
        ],
      ],
    );
  }

  // ── Tarjeta del cuidador (mismo lenguaje visual que paciente activo) ──

  Widget _tarjetaPerfil() {
    final nombre = (_cuidador?['nombre'] as String?) ?? '';
    final correoRespaldo = (_cuidador?['correoRespaldo'] as String?)?.trim();
    final telefono = (_cuidador?['telefono'] as String?)?.trim();
    final relacion = (_cuidador?['relacion'] as String?)?.trim();
    final direccion = (_cuidador?['direccion'] as String?)?.trim();
    final emailAuth =
        ref.read(firebaseAuthProvider).currentUser?.email?.trim() ?? '';
    final correoPrincipal =
        ((_cuidador?['email'] as String?)?.trim() ?? emailAuth);

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
              // ── Cabecera dorada ──
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
                        Icons.person_rounded,
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
                            'MI PERFIL',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nombre.isEmpty ? 'Cuidador' : nombre,
                            style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (relacion != null && relacion.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  ChipFranja(
                                    Icons.family_restroom_outlined,
                                    'Parentesco: $relacion',
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
              // ── Datos personales y correos ──
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _filaDatoPerfil(
                        icono: Icons.location_on_outlined,
                        etiqueta: 'Dirección',
                        valor: (direccion != null && direccion.isNotEmpty)
                            ? direccion
                            : 'No registrado',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _filaDatoPerfil(
                        icono: Icons.phone_outlined,
                        etiqueta: 'Teléfono',
                        valor: (telefono != null && telefono.isNotEmpty)
                            ? telefono
                            : 'No registrado',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _tarjetaAutenticacion(
                        correoPrincipal: correoPrincipal,
                        correoRespaldo:
                            (correoRespaldo != null &&
                                correoRespaldo.isNotEmpty)
                            ? correoRespaldo
                            : null,
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Paleta.doradoClaro,
                    ),
                    _botonCerrarSesion(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: PopupMenuButton<_AccionCuidador>(
            key: const Key('menuDatosPersonales'),
            onSelected: (accion) {
              if (accion == _AccionCuidador.editar) {
                _dialogoEditarCuidador();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AccionCuidador.editar,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar mis datos'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: Paleta.tarjeta,
          ),
        ),
      ],
    );
  }

  /// Tarjeta de Autenticación edge-to-edge: su menú edita el correo
  /// principal o el de respaldo.
  Widget _tarjetaAutenticacion({
    required String correoPrincipal,
    String? correoRespaldo,
  }) {
    final respaldoConfigurado =
        correoRespaldo != null && correoRespaldo.isNotEmpty;
    return Container(
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
              Expanded(
                child: Text(
                  'Autenticación',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Paleta.textoTerciario,
                  ),
                ),
              ),
              PopupMenuButton<_AccionCorreo>(
                key: const Key('menuAutenticacion'),
                tooltip: 'Editar correos',
                onSelected: (accion) {
                  switch (accion) {
                    case _AccionCorreo.editarPrincipal:
                      _dialogoCorreos(editarPrincipal: true);
                    case _AccionCorreo.editarRespaldo:
                      _dialogoCorreos(editarRespaldo: true);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _AccionCorreo.editarPrincipal,
                    child: ListTile(
                      leading: Icon(Icons.alternate_email),
                      title: Text('Editar correo principal'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: _AccionCorreo.editarRespaldo,
                    child: ListTile(
                      leading: Icon(Icons.mark_email_read_outlined),
                      title: Text('Editar correo de respaldo'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Paleta.doradoClaro.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: Paleta.doradoOscuro,
                    size: 20,
                  ),
                ),
                color: Paleta.tarjeta,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _filaCorreo(
            icono: Icons.alternate_email,
            etiqueta: 'Correo principal',
            valor: correoPrincipal.isEmpty ? 'No configurado' : correoPrincipal,
            valorAusente: correoPrincipal.isEmpty,
          ),
          const SizedBox(height: 10),
          _filaCorreo(
            icono: Icons.mark_email_read_outlined,
            etiqueta: 'Correo de respaldo',
            valor: respaldoConfigurado ? correoRespaldo : 'No configurado',
            valorAusente: !respaldoConfigurado,
          ),
        ],
      ),
    );
  }

  /// Fila interna de la tarjeta de Autenticación: icono + etiqueta + valor.
  Widget _filaCorreo({
    required IconData icono,
    required String etiqueta,
    required String valor,
    required bool valorAusente,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Paleta.doradoClaro.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, size: 15, color: Paleta.doradoOscuro),
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
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: valorAusente
                      ? Paleta.textoSecundario
                      : Paleta.textoPrincipal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Editar datos personales (sin correos) ──

  Future<void> _dialogoEditarCuidador() async {
    final cuidador = _cuidador ?? {};
    final nombreController = TextEditingController(
      text: (cuidador['nombre'] as String?) ?? '',
    );
    final telefonoController = TextEditingController(
      text: (cuidador['telefono'] as String?) ?? '',
    );
    final relacionController = TextEditingController(
      text: (cuidador['relacion'] as String?) ?? '',
    );
    final direccionController = TextEditingController(
      text: (cuidador['direccion'] as String?) ?? '',
    );
    final formKey = GlobalKey<FormState>();
    var cargando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Los datos escritos nunca se pierden al arrastrar, al tocar fuera ni
      // con el gesto "atrás" (se cierra solo con la X o Cancelar).
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (ctx, setBuilderState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.62,
              minChildSize: 0.45,
              maxChildSize: 0.85,
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
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Editar mis datos',
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
                            8,
                            20,
                            24 + MediaQuery.of(ctx).viewInsets.bottom,
                          ),
                          children: [
                            TituloSeccion(
                              Icons.person_outline,
                              'Datos personales',
                            ),
                            const SizedBox(height: 10),
                            CampoFormulario(
                              controlador: nombreController,
                              textoAyuda: 'Nombre completo *',
                              icono: Icons.badge_outlined,
                              validador: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Ingresa tu nombre'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            CampoFormulario(
                              controlador: relacionController,
                              textoAyuda: 'Parentesco (madre, padre, tía…) *',
                              icono: Icons.family_restroom_outlined,
                              validador: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Ingresa el parentesco'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            CampoFormulario(
                              controlador: telefonoController,
                              textoAyuda: 'Teléfono *',
                              icono: Icons.phone_outlined,
                              tipoTeclado: TextInputType.phone,
                              accionTeclado: TextInputAction.next,
                              validador: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Ingresa el teléfono'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            CampoFormulario(
                              controlador: direccionController,
                              textoAyuda: 'Dirección *',
                              icono: Icons.location_on_outlined,
                              accionTeclado: TextInputAction.done,
                              validador: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Ingresa la dirección'
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
                                        : 'Guardar cambios',
                                    alPulsar: cargando
                                        ? () {}
                                        : () async {
                                            if (!formKey.currentState!
                                                .validate()) {
                                              return;
                                            }
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final nav = Navigator.of(ctx);
                                            final servicio = ref.read(
                                              servicioBaseDatosProvider,
                                            );
                                            setBuilderState(
                                              () => cargando = true,
                                            );
                                            try {
                                              await servicio.actualizarCuidador(
                                                nombre: nombreController.text
                                                    .trim(),
                                                telefono: telefonoController
                                                    .text
                                                    .trim(),
                                                relacion: relacionController
                                                    .text
                                                    .trim(),
                                                direccion: direccionController
                                                    .text
                                                    .trim(),
                                              );
                                            } catch (e) {
                                              if (!mounted) return;
                                              setBuilderState(
                                                () => cargando = false,
                                              );
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    _mensajeErrorGuardado(e),
                                                  ),
                                                  backgroundColor: Paleta.error,
                                                ),
                                              );
                                              return;
                                            }
                                            await _cargar();
                                            if (!mounted) return;
                                            nav.pop();
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Datos actualizados',
                                                ),
                                                backgroundColor:
                                                    Paleta.doradoPrincipal,
                                              ),
                                            );
                                          },
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
          },
        ),
      ),
    );
  }

  // ── Editar correos (principal / respaldo / ambos) ──

  /// Diálogo dedicado a correos. [editarPrincipal]/[editarRespaldo] indican
  /// qué campo(s) se muestran; al menos uno debe ser true. El correo de
  /// respaldo es opcional: puede dejarse sin configurar.
  Future<void> _dialogoCorreos({
    bool editarPrincipal = false,
    bool editarRespaldo = false,
  }) async {
    final cuidador = _cuidador ?? {};
    final correoPrincipalOriginal =
        (cuidador['email'] as String?)?.trim() ?? '';
    final correoRespaldoOriginal =
        (cuidador['correoRespaldo'] as String?)?.trim() ?? '';

    final principalController = TextEditingController(
      text: correoPrincipalOriginal,
    );
    final respaldoController = TextEditingController(
      text: correoRespaldoOriginal,
    );
    final contrasenaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var ocultarContrasena = true;
    var cargando = false;

    bool hayCambioPrincipal() =>
        principalController.text.trim().toLowerCase() !=
        correoPrincipalOriginal.toLowerCase();
    bool hayCambioRespaldo() =>
        respaldoController.text.trim().toLowerCase() !=
        correoRespaldoOriginal.toLowerCase();
    bool hayCambios() => hayCambioPrincipal() || hayCambioRespaldo();

    String? validarCorreo(
      String? valor, {
      required String original,
      required String otro,
    }) {
      final normalizado = (valor ?? '').trim();
      if (normalizado.toLowerCase() == original.toLowerCase()) return null;
      if (normalizado.isEmpty || !regexCorreo.hasMatch(normalizado)) {
        return 'Ingresa un correo válido';
      }
      if (normalizado.toLowerCase() == otro.toLowerCase()) {
        return 'Ese correo ya está en uso';
      }
      return null;
    }

    final titulo = editarPrincipal && editarRespaldo
        ? 'Editar correos'
        : editarPrincipal
        ? 'Editar correo principal'
        : (correoRespaldoOriginal.isEmpty
              ? 'Configurar correo de respaldo'
              : 'Editar correo de respaldo');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (ctx, setBuilderState) {
            final correosEditados = hayCambios();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.66,
              minChildSize: 0.48,
              maxChildSize: 0.88,
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
                              Icons.mark_email_unread_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              titulo,
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
                            8,
                            20,
                            24 + MediaQuery.of(ctx).viewInsets.bottom,
                          ),
                          children: [
                            TituloSeccion(
                              Icons.mark_email_unread_outlined,
                              'Correos',
                            ),
                            const SizedBox(height: 10),
                            if (editarPrincipal) ...[
                              CampoFormulario(
                                controlador: principalController,
                                textoAyuda:
                                    'Correo principal (cuenta de acceso)',
                                icono: Icons.alternate_email,
                                tipoTeclado: TextInputType.emailAddress,
                                accionTeclado: TextInputAction.next,
                                alCambiar: (_) => setBuilderState(() {}),
                                validador: (v) => validarCorreo(
                                  v,
                                  original: correoPrincipalOriginal,
                                  otro: respaldoController.text,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Al cambiarlo te enviaremos un enlace de '
                                'verificación al nuevo correo.',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Paleta.textoSecundario,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (editarRespaldo) ...[
                              CampoFormulario(
                                controlador: respaldoController,
                                textoAyuda: 'Correo de respaldo',
                                icono: Icons.mark_email_read_outlined,
                                tipoTeclado: TextInputType.emailAddress,
                                accionTeclado: TextInputAction.done,
                                alCambiar: (_) => setBuilderState(() {}),
                                validador: (v) => validarCorreo(
                                  v,
                                  original: correoRespaldoOriginal,
                                  otro: principalController.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Opcional: sirve para recuperar tu cuenta si '
                                'pierdes el acceso al correo principal.',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Paleta.textoSecundario,
                                ),
                              ),
                            ],
                            if (correosEditados) ...[
                              const SizedBox(height: 20),
                              TituloSeccion(
                                Icons.lock_outline,
                                'Confirmar cambios de correo',
                              ),
                              const SizedBox(height: 10),
                              CampoFormulario(
                                controlador: contrasenaController,
                                textoAyuda: 'Contraseña actual',
                                icono: Icons.lock_outlined,
                                oculto: ocultarContrasena,
                                iconoSufijo: IconButton(
                                  icon: Icon(
                                    ocultarContrasena
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setBuilderState(
                                    () =>
                                        ocultarContrasena = !ocultarContrasena,
                                  ),
                                ),
                                accionTeclado: TextInputAction.done,
                                validador: (v) => (v == null || v.isEmpty)
                                    ? 'Ingresa tu contraseña'
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Confirmamos tu identidad antes de '
                                'cualquier cambio de correo.',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Paleta.textoSecundario,
                                ),
                              ),
                            ],
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
                                        : 'Guardar cambios',
                                    alPulsar: cargando
                                        ? () {}
                                        : () async {
                                            if (!formKey.currentState!
                                                .validate()) {
                                              return;
                                            }
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final nav = Navigator.of(ctx);
                                            final servicio = ref.read(
                                              servicioBaseDatosProvider,
                                            );
                                            setBuilderState(
                                              () => cargando = true,
                                            );
                                            String? errorCorreo;
                                            var respaldoConfirmado = true;
                                            var cambiadoPrincipal = false;
                                            String? principalEnviado;

                                            if (hayCambioRespaldo()) {
                                              try {
                                                respaldoConfirmado =
                                                    await servicio
                                                        .cambiarCorreoRespaldo(
                                                          contrasena:
                                                              contrasenaController
                                                                  .text,
                                                          nuevoCorreo:
                                                              respaldoController
                                                                  .text
                                                                  .trim(),
                                                        );
                                              } on FirebaseAuthException catch (
                                                e
                                              ) {
                                                errorCorreo ??=
                                                    _mensajeErrorCambioCorreo(
                                                      e,
                                                    );
                                              } catch (_) {
                                                errorCorreo ??=
                                                    'El correo de respaldo '
                                                    'no se pudo actualizar.';
                                              }
                                            }
                                            if (hayCambioPrincipal()) {
                                              cambiadoPrincipal = true;
                                              principalEnviado =
                                                  principalController.text
                                                      .trim();
                                              try {
                                                await servicio
                                                    .cambiarCorreoPrincipal(
                                                      contrasena:
                                                          contrasenaController
                                                              .text,
                                                      nuevoCorreo:
                                                          principalEnviado,
                                                    );
                                              } on FirebaseAuthException catch (
                                                e
                                              ) {
                                                errorCorreo ??=
                                                    _mensajeErrorCambioCorreo(
                                                      e,
                                                    );
                                              } catch (_) {
                                                errorCorreo ??=
                                                    'El correo principal no se '
                                                    'pudo actualizar.';
                                              }
                                            }
                                            await _cargar();
                                            if (!mounted) return;
                                            nav.pop();
                                            if (errorCorreo != null) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(errorCorreo),
                                                  backgroundColor: Paleta.error,
                                                ),
                                              );
                                            } else if (cambiadoPrincipal) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Te enviamos un correo a '
                                                    '$principalEnviado. '
                                                    'Confírmalo para completar '
                                                    'el cambio.',
                                                  ),
                                                  backgroundColor:
                                                      Paleta.doradoPrincipal,
                                                ),
                                              );
                                            } else {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    respaldoConfirmado
                                                        ? 'Correo de respaldo '
                                                              'actualizado'
                                                        : 'Correo de respaldo '
                                                              'guardado '
                                                              '(pendiente de '
                                                              'confirmar en el '
                                                              'servidor)',
                                                  ),
                                                  backgroundColor:
                                                      Paleta.doradoPrincipal,
                                                ),
                                              );
                                            }
                                          },
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
          },
        ),
      ),
    );
  }

  // ── Fila de dato estilo pacientes: icono + etiqueta + valor ──

  Widget _filaDatoPerfil({
    required IconData icono,
    required String etiqueta,
    required String valor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Paleta.doradoClaro.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, size: 19, color: Paleta.doradoOscuro),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Paleta.textoTerciario,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                valor,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Paleta.textoPrincipal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _mensajeErrorCambioCorreo(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Contraseña incorrecta. Intenta de nuevo.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'Ya existe una cuenta con ese correo electrónico.';
      case 'requires-recent-login':
        return 'Por seguridad, inicia sesión de nuevo e intenta otra vez.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
      default:
        return 'No se pudo actualizar. Intenta de nuevo.';
    }
  }

  /// Traduce un fallo al guardar datos personales a un mensaje accionable.
  String _mensajeErrorGuardado(Object e) {
    if (e is FirebaseException && e.code == 'network-request-failed') {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    return 'No se pudieron guardar los datos.';
  }

  // ── Cerrar sesión ──

  void _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _cerrandoSesion = true);
    await ref.read(selectedPatientIdProvider.notifier).select(null);
    ref.read(servicioCifradoProvider).bloquear();
    ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(false);
    try {
      await ref.read(firebaseAuthProvider).signOut();
    } catch (_) {
      // El estado de sesion se resuelve con el listener de autenticacion.
    }
    if (mounted && context.mounted) context.go('/bienvenida');
  }

  Widget _botonCerrarSesion() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: TextButton.icon(
        onPressed: _cerrandoSesion ? null : _cerrarSesion,
        icon: _cerrandoSesion
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Paleta.doradoOscuro,
                ),
              )
            : const Icon(Icons.logout_rounded, size: 19),
        label: const Text('Cerrar sesión'),
        style: TextButton.styleFrom(
          foregroundColor: Paleta.doradoOscuro,
          backgroundColor: Paleta.doradoClaro.withValues(alpha: 0.45),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ── Utilidades ──

  Widget _mensajeError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Paleta.bordeTarjeta),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Paleta.error),
          const SizedBox(height: 12),
          Text(
            'No se pudieron cargar tus datos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Paleta.textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _cargar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

enum _AccionCuidador { editar }

enum _AccionCorreo { editarPrincipal, editarRespaldo }
