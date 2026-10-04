import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/buscador.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';

class CabeceraRegistro extends StatelessWidget {
  const CabeceraRegistro({
    super.key,
    required this.esEdicion,
    this.onVerHistorial,
  });

  final bool esEdicion;

  final VoidCallback? onVerHistorial;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: EncabezadoGradiente(
        titulo: esEdicion ? 'Editar registro' : 'Registro clínico',
        subtitulo: esEdicion
            ? 'Actualiza signos y síntomas'
            : 'Registra el cuidado',
        logo: const AssetImage('assets/images/OnCuidar.png'),
        tamanoTitulo: 20,
        alTocarLogo: () => context.go('/dashboard'),
        accionDerecha: !esEdicion
            ? BotonCircular(
                clave: const Key('botonVerHistorial'),
                tooltip: 'Ver historial',
                alTocar: onVerHistorial ?? () {},
                hijo: Icon(Icons.history, color: Paleta.doradoOscuro, size: 22),
              )
            : null,
      ),
    );
  }
}
