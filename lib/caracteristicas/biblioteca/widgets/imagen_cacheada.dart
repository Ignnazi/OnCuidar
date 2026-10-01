import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/proveedores/proveedores.dart';

class ImagenCacheada extends ConsumerStatefulWidget {
  const ImagenCacheada({
    super.key,
    required this.url,
    required this.ajuste,
    this.reemplazo,
  });

  final String url;
  final BoxFit ajuste;
  final Widget? reemplazo;

  @override
  ConsumerState<ImagenCacheada> createState() => _ImagenCacheadaState();
}

class _ImagenCacheadaState extends ConsumerState<ImagenCacheada> {
  Future<File>? _futuro;

  @override
  void didUpdateWidget(ImagenCacheada widgetAnterior) {
    super.didUpdateWidget(widgetAnterior);
    if (widgetAnterior.url != widget.url) _futuro = null;
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: widget.ajuste,
        errorBuilder: (_, _, _) => widget.reemplazo ?? const SizedBox.shrink(),
      );
    }
    _futuro ??= ref.read(servicioCacheContenidoProvider).descargar(url);
    return FutureBuilder<File>(
      future: _futuro,
      builder: (context, estado) {
        final archivo = estado.data;
        if (archivo != null) {
          return Image.file(
            archivo,
            fit: widget.ajuste,
            errorBuilder: (_, _, _) =>
                widget.reemplazo ?? const SizedBox.shrink(),
          );
        }
        return widget.reemplazo ?? const SizedBox.shrink();
      },
    );
  }
}
