import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/categorias.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_pdf.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/compartido/widgets/aviso_app.dart';
import 'package:oncuidar/compartido/widgets/aviso_sin_conexion.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:open_filex/open_filex.dart';

/// Aviso de error de la biblioteca.
void mostrarAvisoBiblioteca(BuildContext context, String mensaje) {
  AvisoApp.alerta(context, mensaje);
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
    final archivo = await cache.descargar(
      url,
      tamanoBytes: material.tamanoBytes,
    );
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
  } catch (_) {
    if (!context.mounted) return;
    if (await ref.read(servicioConectividadProvider).estaEnLinea()) {
      if (!context.mounted) return;
      mostrarAvisoBiblioteca(context, 'No se pudo abrir el archivo.');
    } else if (context.mounted) {
      mostrarAvisoSinConexion(context, TextosSinConexion.archivo);
    }
  }
}

String mensajeFavorito(String? categoria, {required bool agregado}) {
  final tipo = categoria == null ? 'Material' : etiquetaCategoria(categoria);
  final masculino = tipo == 'Video' || tipo == 'Material';
  final accion = agregado
      ? (masculino ? 'añadido a' : 'añadida a')
      : (masculino ? 'quitado de' : 'quitada de');
  return '$tipo $accion tus favoritos';
}

Future<void> alternarFavoritoMaterial(
  WidgetRef ref,
  BuildContext context,
  String materialId, {
  String? categoria,
}) async {
  final repositorio = ref.read(repositorioBibliotecaProvider);
  final ids = ref.read(idsFavoritosProvider).value ?? const <String>[];
  final eraFavorito = ids.contains(materialId);
  try {
    await repositorio.fijarFavorito(materialId, favorito: !eraFavorito);
    if (context.mounted) {
      AvisoApp.info(
        context,
        mensajeFavorito(categoria, agregado: !eraFavorito),
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
