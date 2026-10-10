import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/chip_franja.dart';
import 'package:oncuidar/compartido/widgets/tarjeta_dato.dart';
import 'package:oncuidar/compartido/widgets/tarjeta_perfil.dart';

class TarjetaPerfilCuidador extends StatelessWidget {
  const TarjetaPerfilCuidador({
    super.key,
    required this.nombre,
    this.relacion,
    required this.direccion,
    required this.telefono,
    required this.correoPrincipal,
    this.correoRespaldo,
    this.respaldoPendiente = false,
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
  final bool respaldoPendiente;
  final VoidCallback onEditarDatos;
  final VoidCallback onEditarCorreoPrincipal;
  final VoidCallback onEditarCorreoRespaldo;

  @override
  Widget build(BuildContext context) {
    return MarcoTarjetaPerfil(
      hijos: [
        _CabeceraCuidador(nombre: nombre, relacion: relacion),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TarjetaDatosCuidador(direccion: direccion, telefono: telefono),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _TarjetaAutenticacion(
                  correoPrincipal: correoPrincipal,
                  correoRespaldo: correoRespaldo,
                  respaldoPendiente: respaldoPendiente,
                  onEditarPrincipal: onEditarCorreoPrincipal,
                  onEditarRespaldo: onEditarCorreoRespaldo,
                ),
              ),
            ],
          ),
        ),
      ],
      menu: PopupMenuButton<_AccionCuidador>(
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
          child: Icon(Icons.more_vert_rounded, color: Paleta.sobreDorado),
        ),
        color: Paleta.tarjeta,
      ),
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
    return CabeceraDorada(
      icono: Icons.person_rounded,
      etiqueta: 'MI PERFIL',
      nombre: nombre.isEmpty ? 'Cuidador' : nombre,
      franjas: [
        if (relacion != null && relacion.isNotEmpty)
          ChipFranja(Icons.family_restroom_outlined, 'Parentesco: $relacion'),
      ],
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
    return TarjetaDorada(
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
    this.respaldoPendiente = false,
    required this.onEditarPrincipal,
    required this.onEditarRespaldo,
  });

  final String correoPrincipal;
  final String? correoRespaldo;
  final bool respaldoPendiente;
  final VoidCallback onEditarPrincipal;
  final VoidCallback onEditarRespaldo;

  @override
  Widget build(BuildContext context) {
    final respaldoConfigurado =
        correoRespaldo != null && correoRespaldo!.isNotEmpty;
    return TarjetaDorada(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilaDato(
                  recortar: true,
                  icono: Icons.alternate_email,
                  etiqueta: 'Correo principal',
                  valor: correoPrincipal.isEmpty
                      ? 'No configurado'
                      : correoPrincipal,
                  valorAusente: correoPrincipal.isEmpty,
                ),
                const SizedBox(height: 10),
                FilaDato(
                  recortar: true,
                  icono: Icons.mark_email_read_outlined,
                  etiqueta: 'Correo de respaldo',
                  valor: respaldoConfigurado
                      ? correoRespaldo!
                      : 'No configurado',
                  valorAusente: !respaldoConfigurado,
                ),
                if (respaldoPendiente && respaldoConfigurado)
                  _AvisoPendiente(
                    key: const Key('pendienteRespaldo'),
                    texto: 'Pendiente de confirmar: $correoRespaldo',
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Paleta.doradoPrincipal, Paleta.doradoRelleno],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: Paleta.sobreDorado,
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

class _AvisoPendiente extends StatelessWidget {
  const _AvisoPendiente({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 4),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 14, color: Paleta.doradoOscuro),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              texto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Paleta.doradoOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AccionCuidador { editar }

enum _AccionCorreo { editarPrincipal, editarRespaldo }
