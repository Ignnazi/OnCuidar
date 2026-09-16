import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 100 + 24,
                24,
                24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Marca(tamano: 120),
                  const SizedBox(height: 18),
                  Text(
                    '¡Bienvenido a OnCuidar!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Paleta.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu espacio para registrar y acompañar los cuidados '
                    'de tu ser querido.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      height: 1.4,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _filaAccesosRapidos(context),
                  const SizedBox(height: 24),
                  _pieSeguridad(),
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
              subtitulo: 'Tu espacio de cuidado',
              logo: AssetImage('assets/images/OnCuidar.png'),
              alto: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaAccesosRapidos(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _tarjetaDorada(
            context: context,
            icono: Icons.assignment_rounded,
            etiqueta: 'Registro',
            subtitulo: 'Registrar datos',
            alTocar: () => context.push('/registro-clinico'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _tarjetaBlanca(
            context: context,
            icono: Icons.history_rounded,
            color: const Color(0xFF8B5CF6),
            etiqueta: 'Historial',
            subtitulo: 'Registros pasados',
            alTocar: () => context.push(
              '/historial',
              extra: {'filtroFecha': _inicioDeHoy()},
            ),
          ),
        ),
      ],
    );
  }

  DateTime _inicioDeHoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  Widget _tarjetaDorada({
    required BuildContext context,
    required IconData icono,
    required String etiqueta,
    required String subtitulo,
    required VoidCallback alTocar,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Paleta.doradoMedio, Paleta.doradoOscuro],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icono, size: 26, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  etiqueta,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjetaBlanca({
    required BuildContext context,
    required IconData icono,
    required Color color,
    required String etiqueta,
    required String subtitulo,
    required VoidCallback alTocar,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Paleta.tarjeta,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icono, size: 26, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  etiqueta,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Paleta.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    color: Paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pieSeguridad() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: Paleta.textoSecundario.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Tus datos se guardan cifrados en tu dispositivo',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Paleta.textoSecundario.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}