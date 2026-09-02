import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../compartidos/widgets/marca.dart';
import '../../compartidos/widgets/boton_principal.dart';

class Bienvenida extends StatelessWidget {
  const Bienvenida({
    super.key,
    required this.alIniciarSesion,
    required this.alCrearCuenta,
  });

  final VoidCallback alIniciarSesion;
  final VoidCallback alCrearCuenta;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Paleta.crema,
        body: Column(
          children: [
            const EncabezadoGradiente(
              titulo: 'OnCuidar',
              alto: 200,
              tamanoTitulo: 28,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const Marca(tamano: 170),
                    const SizedBox(height: 18),
                    Text(
                      'Te damos la bienvenida',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Paleta.textoPrincipal,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Una herramienta de apoyo para el cuidado domiciliario '
                        'de pacientes oncológicos pediátricos.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Paleta.textoSecundario,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    BotonPrincipal(
                      etiqueta: 'Iniciar Sesión',
                      alPulsar: alIniciarSesion,
                    ),
                    const SizedBox(height: 14),
                    BotonPrincipal(
                      etiqueta: 'Crear Cuenta',
                      alPulsar: alCrearCuenta,
                      destacado: false,
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}