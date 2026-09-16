import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';
import '../../../compartidos/widgets/boton_principal.dart';
import '../../../compartidos/widgets/campos_formulario.dart';
import '../../../compartidos/widgets/titulo_seccion.dart';

Future<void> mostrarDialogoEditarCuidador(
  BuildContext context, {
  required Map<String, dynamic> cuidador,
  required Future<void> Function({
    required String nombre,
    required String telefono,
    required String relacion,
    required String direccion,
  }) alGuardar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _DialogoEditarCuidador(
      cuidador: cuidador,
      alGuardar: alGuardar,
    ),
  );
}

class _DialogoEditarCuidador extends StatefulWidget {
  const _DialogoEditarCuidador({
    required this.cuidador,
    required this.alGuardar,
  });

  final Map<String, dynamic> cuidador;
  final Future<void> Function({
    required String nombre,
    required String telefono,
    required String relacion,
    required String direccion,
  }) alGuardar;

  @override
  State<_DialogoEditarCuidador> createState() => _DialogoEditarCuidadorState();
}

class _DialogoEditarCuidadorState extends State<_DialogoEditarCuidador> {
  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _relacionController;
  late final TextEditingController _direccionController;
  final _formKey = GlobalKey<FormState>();
  var _cargando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: (widget.cuidador['nombre'] as String?) ?? '',
    );
    _telefonoController = TextEditingController(
      text: (widget.cuidador['telefono'] as String?) ?? '',
    );
    _relacionController = TextEditingController(
      text: (widget.cuidador['relacion'] as String?) ?? '',
    );
    _direccionController = TextEditingController(
      text: (widget.cuidador['direccion'] as String?) ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _relacionController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _cargando = true);
    try {
      await widget.alGuardar(
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        relacion: _relacionController.text.trim(),
        direccion: _direccionController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_mensajeErrorGuardado(e)),
          backgroundColor: Paleta.error,
        ),
      );
      return;
    }
    if (!mounted) return;
    nav.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Datos actualizados'),
        backgroundColor: Paleta.doradoPrincipal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: DraggableScrollableSheet(
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
                  key: _formKey,
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
                        controlador: _nombreController,
                        textoAyuda: 'Nombre completo *',
                        icono: Icons.badge_outlined,
                        validador: (v) =>
                            (v == null || v.trim().isEmpty)
                            ? 'Ingresa tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      CampoFormulario(
                        controlador: _relacionController,
                        textoAyuda: 'Parentesco (madre, padre, tía…) *',
                        icono: Icons.family_restroom_outlined,
                        validador: (v) =>
                            (v == null || v.trim().isEmpty)
                            ? 'Ingresa el parentesco'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      CampoFormulario(
                        controlador: _telefonoController,
                        textoAyuda: 'Teléfono *',
                        icono: Icons.phone_outlined,
                        tipoTeclado: TextInputType.phone,
                        accionTeclado: TextInputAction.next,
                        validador: (v) =>
                            (v == null || v.trim().isEmpty)
                            ? 'Ingresa el teléfono'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      CampoFormulario(
                        controlador: _direccionController,
                        textoAyuda: 'Dirección *',
                        icono: Icons.location_on_outlined,
                        accionTeclado: TextInputAction.done,
                        validador: (v) =>
                            (v == null || v.trim().isEmpty)
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
                              etiqueta: _cargando
                                  ? 'Guardando…'
                                  : 'Guardar cambios',
                              alPulsar: _cargando ? () {} : _guardar,
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
    );
  }
}

String _mensajeErrorGuardado(Object e) {
  if (e is FirebaseException && e.code == 'network-request-failed') {
    return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
  }
  return 'No se pudieron guardar los datos.';
}