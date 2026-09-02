import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../compartidos/widgets/marca.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          const EncabezadoGradiente(
            titulo: 'Oncuidar',
            subtitulo: 'Tu espacio de cuidado',
            alto: 130,
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Marca(tamano: 110),
                    const SizedBox(height: 20),
                    Text(
                      '¡Bienvenido a Oncuidar!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Paleta.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu panel de control estará listo en la próxima actualización.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        height: 1.4,
                        color: Paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}