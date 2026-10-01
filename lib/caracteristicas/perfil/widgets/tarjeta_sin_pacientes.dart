import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';
import '../../../compartidos/widgets/boton_principal.dart';
import '../../../compartidos/widgets/campos_formulario.dart';

class TarjetaSinPacientes extends StatelessWidget {
  const TarjetaSinPacientes({super.key, required this.alAgregar});

  final VoidCallback alAgregar;

  @override
  Widget build(BuildContext context) {
    return TarjetaSeccion(
      icono: Icons.child_care_outlined,
      titulo: 'Pacientes',
      hijos: [
        const Icon(
          Icons.child_care_outlined,
          size: 44,
          color: Paleta.doradoMedio,
        ),
        const SizedBox(height: 12),
        Text(
          'Aún no tienes pacientes registrados.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Paleta.textoPrincipal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Agrega el primero para comenzar a registrar sus cuidados.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            height: 1.4,
            color: Paleta.textoSecundario,
          ),
        ),
        const SizedBox(height: 18),
        BotonPrincipal(etiqueta: 'Agregar paciente', alPulsar: alAgregar),
      ],
    );
  }
}
