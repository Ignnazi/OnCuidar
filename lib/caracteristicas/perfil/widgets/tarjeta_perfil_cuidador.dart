import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/tema/paleta.dart';
import '../../../compartidos/widgets/chip_franja.dart';
import '../../../compartidos/widgets/tarjeta_dato.dart';

class TarjetaPerfilCuidador extends StatelessWidget {
  const TarjetaPerfilCuidador({
    super.key,
    required this.nombre,
    this.relacion,
    required this.direccion,
    required this.telefono,
    required this.correoPrincipal,
    this.correoRespaldo,
    required this.onEditarDatos,
    required this.onEditarCorreoPrincipal,
    required this.onEditarCorreoRespaldo,
  });

  final String nombre;
  final String? relacion;
  final String direccion;
  final String telefono;
  final String correoPrincipal;
  final String? correoRespaldo;
  final VoidCallback onEditarDatos;
  final VoidCallback onEditarCorreoPrincipal;
  final VoidCallback onEditarCorreoRespaldo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Paleta.tarjeta,
            borderRadius: const BorderRadius.vertical(
              top: Radius.zero,
              bottom: Radius.circular(24),
            ),
            border: Border.all(color: Paleta.bordeTarjeta),
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CabeceraCuidador(nombre: nombre, relacion: relacion),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TarjetaDatosCuidador(
                      direccion: direccion,
                      telefono: telefono,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _TarjetaAutenticacion(
                        correoPrincipal: correoPrincipal,
                        correoRespaldo: correoRespaldo,
                        onEditarPrincipal: onEditarCorreoPrincipal,
                        onEditarRespaldo: onEditarCorreoRespaldo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: PopupMenuButton<_AccionCuidador>(
            key: const Key('menuDatosPersonales'),
            onSelected: (accion) {
              if (accion == _AccionCuidador.editar) {
                onEditarDatos();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AccionCuidador.editar,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar mis datos'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert_rounded, color: Colors.white),
            ),
            color: Paleta.tarjeta,
          ),
        ),
      ],
    );
  }
}

class _CabeceraCuidador extends StatelessWidget {
  const _CabeceraCuidador({required this.nombre, this.relacion});

  final String nombre;
  final String? relacion;

  @override
  Widget build(BuildContext context) {
    final relacion = this.relacion;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 44, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Paleta.doradoOscuro,
            Paleta.doradoPrincipal,
            Paleta.doradoMedio,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MI PERFIL',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nombre.isEmpty ? 'Cuidador' : nombre,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (relacion != null && relacion.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChipFranja(
                          Icons.family_restroom_outlined,
                          'Parentesco: $relacion',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con dirección y teléfono del cuidador.
class _TarjetaDatosCuidador extends StatelessWidget {
  const _TarjetaDatosCuidador({
    required this.direccion,
    required this.telefono,
  });

  final String direccion;
  final String telefono;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          FilaDato(
            icono: Icons.location_on_outlined,
            etiqueta: 'Dirección',
            valor: (direccion.isNotEmpty) ? direccion : 'No registrado',
          ),
          const SizedBox(height: 12),
          FilaDato(
            icono: Icons.phone_outlined,
            etiqueta: 'Teléfono',
            valor: (telefono.isNotEmpty) ? telefono : 'No registrado',
          ),
        ],
      ),
    );
  }
}

class _TarjetaAutenticacion extends StatelessWidget {
  const _TarjetaAutenticacion({
    required this.correoPrincipal,
    this.correoRespaldo,
    required this.onEditarPrincipal,
    required this.onEditarRespaldo,
  });

  final String correoPrincipal;
  final String? correoRespaldo;
  final VoidCallback onEditarPrincipal;
  final VoidCallback onEditarRespaldo;

  @override
  Widget build(BuildContext context) {
    final respaldoConfigurado =
        correoRespaldo != null && correoRespaldo!.isNotEmpty;
    return Container(
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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilaCorreo(
                  icono: Icons.alternate_email,
                  etiqueta: 'Correo principal',
                  valor: correoPrincipal.isEmpty
                      ? 'No configurado'
                      : correoPrincipal,
                  valorAusente: correoPrincipal.isEmpty,
                ),
                const SizedBox(height: 10),
                _FilaCorreo(
                  icono: Icons.mark_email_read_outlined,
                  etiqueta: 'Correo de respaldo',
                  valor: respaldoConfigurado
                      ? correoRespaldo!
                      : 'No configurado',
                  valorAusente: !respaldoConfigurado,
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<_AccionCorreo>(
              key: const Key('menuAutenticacion'),
              tooltip: 'Editar correos',
              onSelected: (accion) {
                switch (accion) {
                  case _AccionCorreo.editarPrincipal:
                    onEditarPrincipal();
                  case _AccionCorreo.editarRespaldo:
                    onEditarRespaldo();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _AccionCorreo.editarPrincipal,
                  child: ListTile(
                    leading: Icon(Icons.alternate_email),
                    title: Text('Editar correo principal'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: _AccionCorreo.editarRespaldo,
                  child: ListTile(
                    leading: Icon(Icons.mark_email_read_outlined),
                    title: Text('Editar correo de respaldo'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Paleta.doradoPrincipal, Paleta.doradoOscuro],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              color: Paleta.tarjeta,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCorreo extends StatelessWidget {
  const _FilaCorreo({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.valorAusente,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final bool valorAusente;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 12),
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
              const SizedBox(height: 3),
              Text(
                valor,
                overflow: TextOverflow.ellipsis,
                style: valorAusente
                    ? GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Paleta.textoSecundario,
                      )
                    : GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Paleta.textoPrincipal,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _AccionCuidador { editar }

enum _AccionCorreo { editarPrincipal, editarRespaldo }