import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';

/// Campo para escribir la duda y botón de enviar.
class EntradaChat extends StatelessWidget {
  const EntradaChat({
    super.key,
    required this.controlador,
    required this.foco,
    required this.habilitada,
    required this.alEnviar,
  });

  final TextEditingController controlador;
  final FocusNode foco;
  final bool habilitada;
  final VoidCallback alEnviar;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Paleta.crema,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                decoration: BoxDecoration(
                  color: Paleta.tarjeta,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Paleta.bordeTarjeta),
                  boxShadow: [
                    BoxShadow(
                      color: Paleta.doradoOscuro.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  key: const Key('campoMensajeChat'),
                  controller: controlador,
                  focusNode: foco,
                  enabled: habilitada,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => alEnviar(),
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Paleta.textoPrincipal,
                    height: 1.4,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Escribe tu duda aquí…',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controlador,
              builder: (context, valor, _) {
                final tieneTexto = valor.text.trim().isNotEmpty;
                return GestureDetector(
                  key: const Key('enviarMensaje'),
                  onTap: alEnviar,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: Paleta.degradadoCabecera,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: tieneTexto ? 1 : 0.4,
                      child: Icon(
                        Icons.send_rounded,
                        color: Paleta.sobreDorado,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
