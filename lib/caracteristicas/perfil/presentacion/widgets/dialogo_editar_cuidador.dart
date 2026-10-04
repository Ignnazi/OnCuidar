import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/boton_principal.dart';
import 'package:oncuidar/compartido/widgets/campos_formulario.dart';
import 'package:oncuidar/compartido/widgets/hoja_dialogo.dart';
import 'package:oncuidar/compartido/widgets/titulo_seccion.dart';

Future<void> mostrarDialogoEditarCuidador(
  BuildContext context, {
  required Map<String, dynamic> cuidador,
  required Future<void> Function({
    required String nombre,
    required String telefono,
    required String relacion,
    required String direccion,
  })
  alGuardar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _DialogoEditarCuidador(cuidador: cuidador, alGuardar: alGuardar),
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
  })
  alGuardar;

  @override
  State<_DialogoEditarCuidador> createState() => _DialogoEditarCuidadorState();
}

class _DialogoEditarCuidadorState extends State<_DialogoEditarCuidador> {
  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _relacionController;
  late final TextEditingController _direccionController;
  final _formKey = GlobalKey<FormState>();

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
    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();
    final relacion = _relacionController.text.trim();
    final direccion = _direccionController.text.trim();
    final alGuardar = widget.alGuardar;
    nav.pop();
    unawaited(
      _guardarEnBackground(
        messenger,
        alGuardar,
        nombre: nombre,
        telefono: telefono,
        relacion: relacion,
        direccion: direccion,
      ),
    );
  }

  Future<void> _guardarEnBackground(
    ScaffoldMessengerState messenger,
    Future<void> Function({
      required String nombre,
      required String telefono,
      required String relacion,
      required String direccion,
    })
    alGuardar, {
    required String nombre,
    required String telefono,
    required String relacion,
    required String direccion,
  }) async {
    try {
      await alGuardar(
        nombre: nombre,
        telefono: telefono,
        relacion: relacion,
        direccion: direccion,
      );
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Datos actualizados'),
          backgroundColor: Paleta.doradoPrincipal,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_mensajeErrorGuardado(e)),
          backgroundColor: Paleta.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: HojaDialogo(
        icono: Icons.edit_outlined,
        titulo: 'Editar mis datos',
        tamanoInicial: 0.62,
        tamanoMinimo: 0.45,
        tamanoMaximo: 0.85,
        cuerpo: (ctx, scrollController) => [
          FormularioDeHoja(
            formKey: _formKey,
            controlador: scrollController,
            hijos: [
              const TituloSeccion(Icons.person_outline, 'Datos personales'),
              const SizedBox(height: 10),
              CampoFormulario(
                controlador: _nombreController,
                textoAyuda: 'Nombre completo *',
                icono: Icons.badge_outlined,
                validador: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa tu nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              CampoFormulario(
                controlador: _relacionController,
                textoAyuda: 'Parentesco (madre, padre, tía…) *',
                icono: Icons.family_restroom_outlined,
                validador: (v) => (v == null || v.trim().isEmpty)
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
                validador: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa el teléfono'
                    : null,
              ),
              const SizedBox(height: 12),
              CampoFormulario(
                controlador: _direccionController,
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
                      etiqueta: 'Guardar cambios',
                      alPulsar: _guardar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
