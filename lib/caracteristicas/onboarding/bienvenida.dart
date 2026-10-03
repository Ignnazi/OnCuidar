import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../compartidos/widgets/boton_principal.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../compartidos/widgets/marca.dart';
import '../../core/tema/paleta.dart';

class Bienvenida extends StatefulWidget {
  const Bienvenida({
    super.key,
    required this.alIniciarSesion,
    required this.alCrearCuenta,
  });

  final VoidCallback alIniciarSesion;
  final VoidCallback alCrearCuenta;

  @override
  State<Bienvenida> createState() => _BienvenidaState();
}

class _BienvenidaState extends State<Bienvenida> {
  DateTime _ultimaPulsacion = DateTime.fromMillisecondsSinceEpoch(0);

  void _manejarAtras(bool didPop) {
    if (didPop) return;
    final ahora = DateTime.now();
    if (ahora.difference(_ultimaPulsacion) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _ultimaPulsacion = ahora;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Presiona atrás de nuevo para salir'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _manejarAtras(didPop),
      child: Scaffold(
        backgroundColor: Paleta.crema,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  28,
                  MediaQuery.of(context).padding.top + 160 + 8,
                  28,
                  24,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const Marca(tamano: 200),
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
                      alPulsar: widget.alIniciarSesion,
                    ),
                    const SizedBox(height: 14),
                    BotonPrincipal(
                      etiqueta: 'Crear Cuenta',
                      alPulsar: widget.alCrearCuenta,
                      destacado: false,
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),

            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EncabezadoGradiente(
                titulo: 'OnCuidar',
                alto: 160,
                tamanoTitulo: 42,
                tituloCentrado: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
