import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/configuracion/dominio/escala_texto.dart';
import 'package:oncuidar/caracteristicas/configuracion/dominio/modo_tema.dart';
import 'package:oncuidar/caracteristicas/configuracion/presentacion/proveedores_configuracion.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/controlador_recordatorios.dart';
import 'package:oncuidar/compartido/widgets/fondo_hoja.dart';

Future<void> mostrarHojaConfiguracion(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (contexto) => FondoHoja(
      radio: 24,
      child: SafeArea(
        key: const Key('hojaConfiguracion'),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(contexto).size.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Paleta.bordeTarjeta,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const _EncabezadoHoja(),
              const Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: SeccionConfiguracion(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EncabezadoHoja extends StatelessWidget {
  const _EncabezadoHoja();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Paleta.doradoPrincipal, Paleta.doradoRelleno],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.tune_rounded, color: Paleta.sobreDorado),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración de la app',
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Paleta.textoPrincipal,
                  ),
                ),
                Text(
                  'Ajusta OnCuidar a tu gusto',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    color: Paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('cerrarConfiguracion'),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: Paleta.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class SeccionConfiguracion extends ConsumerStatefulWidget {
  const SeccionConfiguracion({super.key});

  @override
  ConsumerState<SeccionConfiguracion> createState() =>
      _SeccionConfiguracionState();
}

class _SeccionConfiguracionState extends ConsumerState<SeccionConfiguracion> {
  bool _silenciadas = false;

  @override
  void initState() {
    super.initState();
    unawaited(_cargarSilencio());
  }

  Future<void> _cargarSilencio() async {
    final guardado = await ControladorRecordatorios.silencioGuardado();
    if (mounted) setState(() => _silenciadas = guardado);
  }

  Future<void> _alternarSilencio(bool silenciar) async {
    setState(() => _silenciadas = silenciar);
    await ref.read(controladorRecordatoriosProvider).fijarSilencio(silenciar);
  }

  static const _iconosModo = {
    ModoTema.sistema: Icons.brightness_auto_rounded,
    ModoTema.claro: Icons.light_mode_rounded,
    ModoTema.oscuro: Icons.dark_mode_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final escala = ref.watch(escalaTextoProvider);
    final modo = ref.watch(modoTemaProvider);
    return Column(
      key: const Key('seccionConfiguracion'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tarjeta(
          icono: Icons.palette_outlined,
          titulo: 'Apariencia',
          descripcion: 'Automático sigue el modo claro u oscuro del teléfono.',
          child: Row(
            children: [
              for (final opcion in ModoTema.values) ...[
                if (opcion != ModoTema.values.first) const SizedBox(width: 8),
                Expanded(
                  child: _Opcion(
                    clave: Key('modo_${opcion.name}'),
                    etiqueta: opcion.etiqueta,
                    activa: opcion == modo,
                    alPulsar: () => unawaited(
                      ref.read(modoTemaProvider.notifier).fijar(opcion),
                    ),
                    visual: (color) =>
                        Icon(_iconosModo[opcion], color: color, size: 24),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Tarjeta(
          icono: Icons.text_fields_rounded,
          titulo: 'Tamaño del texto',
          descripcion: 'Se aplica a toda la app y se suma al del teléfono.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (final (i, opcion) in EscalaTexto.values.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _Opcion(
                        clave: Key('escala_${opcion.name}'),
                        etiqueta: opcion.etiqueta,
                        activa: opcion == escala,
                        alPulsar: () => unawaited(
                          ref.read(escalaTextoProvider.notifier).fijar(opcion),
                        ),
                        visual: (color) => Text(
                          'A',
                          textScaler: TextScaler.noScaling,
                          style: GoogleFonts.nunito(
                            fontSize: 16 + i * 4.0,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Paleta.fondoEntrada,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Así se verá el texto en toda la app.',
                  key: const Key('vistaPreviaTexto'),
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Paleta.textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Tarjeta(
          icono: _silenciadas
              ? Icons.notifications_off_outlined
              : Icons.notifications_none_rounded,
          titulo: 'Notificaciones',
          child: SwitchListTile(
            key: const Key('interruptorSilencio'),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.white,
            activeTrackColor: Paleta.doradoPrincipal,
            title: Text(
              'Silenciar todos los avisos',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Paleta.textoPrincipal,
              ),
            ),
            subtitle: Text(
              'Ningún paciente te avisará, pero los recordatorios se conservan. '
              'Para silenciar a uno solo, usa la campana en Recordatorios.',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                color: Paleta.textoSecundario,
              ),
            ),
            value: _silenciadas,
            onChanged: (valor) => unawaited(_alternarSilencio(valor)),
          ),
        ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.icono,
    required this.titulo,
    required this.child,
    this.descripcion,
  });

  final IconData icono;
  final String titulo;
  final String? descripcion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final descripcion = this.descripcion;
    return Material(
      color: Paleta.tarjeta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Paleta.bordeTarjeta),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Paleta.doradoClaro,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, size: 18, color: Paleta.doradoOscuro),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Paleta.textoPrincipal,
                    ),
                  ),
                ),
              ],
            ),
            if (descripcion != null) ...[
              const SizedBox(height: 6),
              Text(
                descripcion,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  color: Paleta.textoSecundario,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.clave,
    required this.etiqueta,
    required this.activa,
    required this.alPulsar,
    required this.visual,
  });

  final Key clave;
  final String etiqueta;
  final bool activa;
  final VoidCallback alPulsar;
  final Widget Function(Color color) visual;

  static const _duracion = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final colorIcono = activa ? Paleta.sobreDorado : Paleta.doradoOscuro;
    return Semantics(
      button: true,
      selected: activa,
      label: etiqueta,
      child: AnimatedContainer(
        key: clave,
        duration: _duracion,
        curve: Curves.easeOutCubic,
        height: 74,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: activa
                ? [Paleta.doradoPrincipal, Paleta.doradoRelleno]
                : [Paleta.fondoEntrada, Paleta.fondoEntrada],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activa ? Colors.transparent : Paleta.bordeTarjeta,
          ),
          boxShadow: [
            BoxShadow(
              color: Paleta.doradoRelleno.withValues(
                alpha: activa ? 0.30 : 0.0,
              ),
              blurRadius: activa ? 8 : 0,
              offset: Offset(0, activa ? 3 : 0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: alPulsar,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 26,
                    child: Center(
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(end: colorIcono),
                        duration: _duracion,
                        curve: Curves.easeOutCubic,
                        builder: (_, color, _) => visual(color ?? colorIcono),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: _duracion,
                      curve: Curves.easeOutCubic,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: activa
                            ? Paleta.sobreDorado
                            : Paleta.textoPrincipal,
                      ),
                      child: Text(etiqueta, maxLines: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
