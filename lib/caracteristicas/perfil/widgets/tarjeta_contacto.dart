import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';
import 'tarjeta_mapa.dart';

class TarjetaContacto extends StatelessWidget {
  const TarjetaContacto({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.titulo,
    this.direccion,
    this.telefono,
    this.alLlamar,
    this.alAbrirMapa,
  });

  final IconData icono;
  final String etiqueta;
  final String titulo;
  final String? direccion;
  final String? telefono;
  final VoidCallback? alLlamar;
  final VoidCallback? alAbrirMapa;

  @override
  Widget build(BuildContext context) {
    final tieneDireccion = direccion != null && direccion!.isNotEmpty;
    final tieneTelefono =
        telefono != null && telefono!.isNotEmpty && alLlamar != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Paleta.tarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Paleta.doradoClaro),
          boxShadow: [
            BoxShadow(
              color: Paleta.doradoOscuro.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Paleta.doradoPrincipal, Paleta.doradoOscuro],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etiqueta,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Paleta.textoTerciario,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        titulo,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Paleta.textoPrincipal,
                        ),
                      ),
                      if (telefono != null && telefono!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          telefono!,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Paleta.textoSecundario,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (tieneTelefono) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: alLlamar,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Paleta.doradoPrincipal, Paleta.doradoOscuro],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Paleta.doradoOscuro.withValues(alpha: 0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Llamar',
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.phone_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (tieneDireccion) ...[
              const SizedBox(height: 10),
              TarjetaMapa(
                direccion: direccion!,
                onTap: alAbrirMapa ?? () {},
              ),
            ],
          ],
        ),
      ),
    );
  }
}