import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';

Future<int?> mostrarDialogoTope(
  BuildContext context, {
  required int valorInicial,
}) async {
  var valor = valorInicial;
  return showDialog<int>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: Paleta.tarjeta,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Configurar registro',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Paleta.textoPrincipal,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Máximo de registros programados por día',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                height: 1.4,
                color: Paleta.textoSecundario,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BotonStepper(
                  icono: Icons.remove,
                  habilitado: valor > 1,
                  alPulsar: () => setDialogState(() => valor--),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Paleta.fondoEntrada,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Paleta.doradoPrincipal,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '$valor',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Paleta.doradoOscuro,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                _BotonStepper(
                  icono: Icons.add,
                  habilitado: valor < 10,
                  alPulsar: () => setDialogState(() => valor++),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Paleta.textoSecundario,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(valor),
            style: ElevatedButton.styleFrom(
              backgroundColor: Paleta.doradoPrincipal,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

class _BotonStepper extends StatelessWidget {
  const _BotonStepper({
    required this.icono,
    required this.habilitado,
    required this.alPulsar,
  });

  final IconData icono;
  final bool habilitado;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: habilitado ? alPulsar : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: habilitado ? Paleta.doradoPrincipal : Paleta.bordeTarjeta,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icono,
          size: 20,
          color: habilitado ? Colors.white : Paleta.textoSecundario,
        ),
      ),
    );
  }
}