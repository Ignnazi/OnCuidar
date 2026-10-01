import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';

const duracionAvisoSinConexion = Duration(seconds: 3);

class BannerConexion extends ConsumerStatefulWidget {
  const BannerConexion({super.key, this.duracion = duracionAvisoSinConexion});

  final Duration duracion;

  @override
  ConsumerState<BannerConexion> createState() => _EstadoBannerConexion();
}

class _EstadoBannerConexion extends ConsumerState<BannerConexion>
    with WidgetsBindingObserver {
  Timer? _temporizador;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _mostrarUnRato();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizador?.cancel();
    super.dispose();
  }

  bool get _sinConexion => ref.read(estadoConexionProvider).value == false;

  void _mostrarUnRato() {
    if (!mounted || !_sinConexion) return;
    _temporizador?.cancel();
    setState(() => _visible = true);
    _temporizador = Timer(widget.duracion, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _ocultar() {
    _temporizador?.cancel();
    if (_visible) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(estadoConexionProvider, (previo, actual) {
      if (actual.value == false && previo?.value != false) _mostrarUnRato();
      if (actual.value == true) _ocultar();
    });
    final sinConexion = ref.watch(estadoConexionProvider).value == false;
    if (!_visible || !sinConexion) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('banner_conexion'),
        width: double.infinity,
        color: Paleta.doradoBannerOscuro,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 18, color: Paleta.textoTerciario),
            const SizedBox(width: 8),
            Text(
              'Sin conexión',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Paleta.textoTerciario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
