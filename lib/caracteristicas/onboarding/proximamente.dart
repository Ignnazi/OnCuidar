import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../core/tema/paleta.dart';

class Proximamente extends StatelessWidget {
  const Proximamente({super.key, required this.titulo});

  final String titulo;

  String get _subtitulo {
    switch (titulo) {
      case 'Chat':
        return 'Conecta con tu equipo';
      case 'Aprende':
        return 'Aprende sobre cuidados';
      default:
        return 'Próximamente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 100 + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      size: 64,
                      color: Paleta.doradoMedio,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Próximamente',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Paleta.textoPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: EncabezadoGradiente(
              titulo: titulo,
              subtitulo: _subtitulo,
              logo: const AssetImage('assets/images/OnCuidar.png'),
              tamanoTitulo: 20,
              alto: 100,
            ),
          ),
        ],
      ),
    );
  }
}