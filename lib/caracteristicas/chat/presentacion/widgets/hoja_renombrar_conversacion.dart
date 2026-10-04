import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/estilos.dart';
import 'package:oncuidar/compartido/widgets/boton_principal.dart';

class HojaRenombrarConversacion extends StatefulWidget {
  const HojaRenombrarConversacion({super.key, required this.controlador});

  final TextEditingController controlador;

  @override
  State<HojaRenombrarConversacion> createState() =>
      _HojaRenombrarConversacionState();
}

class _HojaRenombrarConversacionState extends State<HojaRenombrarConversacion> {
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _foco.requestFocus();
    });
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.42,
      minChildSize: 0.35,
      maxChildSize: 0.62,
      builder: (ctx, _) => Container(
        key: const Key('dialogoRenombrarConversacion'),
        decoration: BoxDecoration(
          color: Paleta.tarjeta,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Paleta.doradoPrincipal,
                              Paleta.doradoRelleno,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Paleta.sobreDorado,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Renombrar conversación',
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Paleta.textoPrincipal,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        icon: Icon(Icons.close, color: Paleta.textoSecundario),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    key: const Key('campoRenombrarConversacion'),
                    controller: widget.controlador,
                    focusNode: _foco,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Paleta.textoPrincipal,
                    ),
                    decoration: entradaDorada(
                      hintText: 'Nombre de la conversación',
                    ),
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: BotonPrincipal(
                          key: const Key('cancelarRenombrarConversacion'),
                          etiqueta: 'Cancelar',
                          alPulsar: () => Navigator.of(ctx).pop(false),
                          destacado: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: BotonPrincipal(
                          key: const Key('confirmarRenombrarConversacion'),
                          etiqueta: 'Guardar',
                          alPulsar: () => Navigator.of(ctx).pop(true),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
