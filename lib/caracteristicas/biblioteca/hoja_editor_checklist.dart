import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/servicios/servicio_base_datos.dart';
import '../../core/tema/paleta.dart';
import '../../core/util/estilos.dart';
import '../../modelos/checklist_usuario.dart';

class HojaEditorChecklist extends ConsumerStatefulWidget {
  const HojaEditorChecklist({super.key, this.checklist});

  final ChecklistUsuario? checklist;

  @override
  ConsumerState<HojaEditorChecklist> createState() =>
      _HojaEditorChecklistState();
}

class _HojaEditorChecklistState extends ConsumerState<HojaEditorChecklist> {
  late final TextEditingController _tituloController;
  late final List<TextEditingController> _controlesItems;
  final _formKey = GlobalKey<FormState>();

  bool get _esEdicion => widget.checklist != null;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(
      text: widget.checklist?.titulo ?? '',
    );
    _controlesItems = widget.checklist != null
        ? widget.checklist!.items
            .map((item) => TextEditingController(text: item))
            .toList()
        : [TextEditingController(), TextEditingController()];
  }

  @override
  void dispose() {
    _tituloController.dispose();
    for (final control in _controlesItems) {
      control.dispose();
    }
    super.dispose();
  }

  void _agregarItem() {
    setState(() {
      _controlesItems.add(TextEditingController());
    });
  }

  void _quitarItem(int indice) {
    if (_controlesItems.length <= 1) return;
    setState(() {
      _controlesItems[indice].dispose();
      _controlesItems.removeAt(indice);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final titulo = _tituloController.text.trim();
    final items = _controlesItems
        .map((control) => control.text.trim())
        .where((texto) => texto.isNotEmpty)
        .toList();

    if (items.isEmpty) return;

    final paciente = ref.read(currentPatientProvider).value;
    if (paciente == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final base = ref.read(servicioBaseDatosProvider);
    final esEdicion = _esEdicion;
    final idEdicion = widget.checklist?.id;
    Navigator.of(context).pop();
    unawaited(_guardarEnBackground(
      messenger,
      base,
      pacienteId: paciente.id,
      titulo: titulo,
      items: items,
      esEdicion: esEdicion,
      idEdicion: idEdicion,
    ));
  }

  Future<void> _guardarEnBackground(
    ScaffoldMessengerState messenger,
    ServicioBaseDatos base, {
    required String pacienteId,
    required String titulo,
    required List<String> items,
    required bool esEdicion,
    required String? idEdicion,
  }) async {
    try {
      if (esEdicion && idEdicion != null) {
        await base.actualizarListaChecklist(
          pacienteId,
          idEdicion,
          titulo: titulo,
          items: items,
        );
      } else {
        await base.crearListaChecklist(
          pacienteId,
          titulo: titulo,
          items: items,
        );
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            esEdicion ? 'Checklist actualizado' : 'Checklist creado',
            style: GoogleFonts.nunito(fontSize: 14),
          ),
          backgroundColor: Paleta.doradoPrincipal,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar el checklist: $e',
            style: GoogleFonts.nunito(fontSize: 14),
          ),
          backgroundColor: Paleta.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fondo = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Paleta.crema,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _manija(),
              _cabecera(cerrar: () => Navigator.of(ctx).pop()),
              Divider(height: 1, color: Paleta.bordeTarjeta),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      fondo + 24,
                    ),
                    children: [
                      Text(
                        'Título',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('tituloChecklist'),
                        controller: _tituloController,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Paleta.textoPrincipal,
                        ),
                        decoration: entradaDorada(
                          hintText: 'Nombre del checklist',
                        ),
                        validator: (valor) =>
                            valor == null || valor.trim().isEmpty
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Ítems',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Paleta.textoSecundario,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _agregarItem,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Paleta.doradoPrincipal,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Agregar',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_controlesItems.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: Key('itemChecklist_$i'),
                                  controller: _controlesItems[i],
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: Paleta.textoPrincipal,
                                  ),
                                  decoration: entradaDorada(
                                    hintText: 'Ítem ${i + 1}',
                                    counterText: '',
                                  ),
                                ),
                              ),
                              if (_controlesItems.length > 1) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _quitarItem(i),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Paleta.error.withValues(
                                        alpha: 0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Paleta.error,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          key: const Key('guardarChecklist'),
                          onPressed: _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Paleta.doradoPrincipal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _esEdicion
                                ? 'Guardar cambios'
                                : 'Crear checklist',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _manija() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Paleta.textoAyuda.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _cabecera({required VoidCallback cerrar}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Paleta.doradoMedio, Paleta.doradoPrincipal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _esEdicion ? Icons.edit : Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _esEdicion ? 'Editar checklist' : 'Nuevo checklist',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Paleta.textoPrincipal,
              ),
            ),
          ),
          GestureDetector(
            onTap: cerrar,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Paleta.textoPrincipal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 18,
                color: Paleta.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}