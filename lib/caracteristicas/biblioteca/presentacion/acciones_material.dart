import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_pdf.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:open_filex/open_filex.dart';

/// Aviso de error de la biblioteca.
void mostrarAvisoBiblioteca(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje, style: GoogleFonts.nunito(fontSize: 14)),
      backgroundColor: Paleta.error,
    ),
  );
}

Future<void> abrirArchivoMaterial(
  WidgetRef ref,
  BuildContext context,
  MaterialEducativo material, {
  VoidCallback? alDescargar,
}) async {
  final url = material.urlArchivo;
  if (url == null || url.isEmpty) return;
  try {
    final cache = ref.read(servicioCacheContenidoProvider);
    final archivo = await cache.descargar(url);
    ref.read(contenidosDescargadosProvider.notifier).marcarDescargado(url);
    if (!context.mounted) return;
    alDescargar?.call();
    if (material.esPdf) {
      unawaited(
        abrirVisorPdf(context, ruta: archivo.path, titulo: material.titulo),
      );
      return;
    }
    final resultado = await OpenFilex.open(archivo.path);
    if (resultado.type != ResultType.done && context.mounted) {
      mostrarAvisoBiblioteca(
        context,
        resultado.message.isNotEmpty
            ? resultado.message
            : 'No hay una aplicación para abrir este tipo de archivo.',
      );
    }
  } catch (e) {
    if (context.mounted) {
      mostrarAvisoBiblioteca(context, 'Error al abrir el archivo: $e');
    }
  }
}

Future<void> alternarFavoritoMaterial(
  WidgetRef ref,
  BuildContext context,
  String materialId,
) async {
  final repositorio = ref.read(repositorioBibliotecaProvider);
  final ids = ref.read(idsFavoritosProvider).value ?? const <String>[];
  final eraFavorito = ids.contains(materialId);
  try {
    await repositorio.fijarFavorito(materialId, favorito: !eraFavorito);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            eraFavorito ? 'Quitado de favoritos' : 'Añadido a favoritos',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Paleta.doradoPrincipal,
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      mostrarAvisoBiblioteca(
        context,
        'No se pudo actualizar el favorito. Revisa tu conexión.',
      );
    }
  }
}
