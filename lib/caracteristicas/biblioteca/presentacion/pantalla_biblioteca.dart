import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/categorias.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/parseo_contenido.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/acciones_material.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_video.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/checklist_interactivo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/dialogo_imagen_ampliable.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/tarjeta_material.dart';
import 'package:oncuidar/compartido/widgets/buscador.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';

class BibliotecaScreen extends ConsumerStatefulWidget {
  const BibliotecaScreen({super.key});

  @override
  ConsumerState<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends ConsumerState<BibliotecaScreen> {
  String _busqueda = '';
  String _filtro = 'Todos';
  bool _soloFavoritos = false;
  bool _buscando = false;
  final Set<String> _urlsVerificadas = {};
  final Set<String> _urlsDescargando = {};
  final _controladorBusqueda = TextEditingController();

  List<MaterialEducativo> _filtrar(
    List<MaterialEducativo> items,
    Set<String> favoritos,
  ) {
    final termino = _busqueda.trim().toLowerCase();
    return items.where((material) {
      if (!coincideFiltro(_filtro, material.categoria)) return false;
      if (_soloFavoritos && !favoritos.contains(material.id)) return false;
      if (termino.isNotEmpty &&
          !material.titulo.toLowerCase().contains(termino)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _alternarBusqueda() {
    setState(() {
      _buscando = !_buscando;
      if (!_buscando) {
        _busqueda = '';
        _controladorBusqueda.clear();
      }
    });
  }

  Future<void> _verificarDescargas(List<MaterialEducativo> items) async {
    try {
      final cache = ref.read(servicioCacheContenidoProvider);
      for (final material in items) {
        final url = material.urlArchivo;
        if (url == null || url.isEmpty || _urlsVerificadas.contains(url)) {
          continue;
        }
        _urlsVerificadas.add(url);
        final descargado = await cache.archivoDescargado(url);
        if (descargado) {
          ref
              .read(contenidosDescargadosProvider.notifier)
              .marcarDescargado(url);
        }
      }
    } catch (_) {}
  }

  Future<void> _abrirMaterial(MaterialEducativo material) async {
    if (material.esVideo) {
      await _reproducirVideo(material);
      return;
    }
    if (material.esChecklist) {
      _abrirChecklist(material);
      return;
    }
    final url = material.urlArchivo;
    if (url != null && url.isNotEmpty) {
      await _abrirArchivo(material, url);
      return;
    }
    final imagen = material.urlImagen;
    if (imagen != null && imagen.isNotEmpty) {
      _mostrarInfografia(imagen, material.titulo);
      return;
    }
    if (context.mounted) unawaited(context.push('/biblioteca/${material.id}'));
  }

  void _mostrarInfografia(String url, String titulo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DialogoImagenAmpliable(url: url, titulo: titulo),
    );
  }

  Future<void> _reproducirVideo(MaterialEducativo material) async {
    final url = material.urlArchivo;
    if (url == null || url.isEmpty) {
      if (context.mounted) {
        unawaited(context.push('/biblioteca/${material.id}'));
      }
      return;
    }
    if (_urlsDescargando.contains(url)) return;
    setState(() => _urlsDescargando.add(url));
    try {
      final cache = ref.read(servicioCacheContenidoProvider);
      final archivo = await cache.descargar(url);
      ref.read(contenidosDescargadosProvider.notifier).marcarDescargado(url);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaVideo(
            archivo: archivo,
            titulo: material.titulo,
            idContenido: material.id,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo preparar el video: $e',
              style: GoogleFonts.nunito(fontSize: 14),
            ),
            backgroundColor: Paleta.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _urlsDescargando.remove(url));
    }
  }

  Future<void> _abrirArchivo(MaterialEducativo material, String url) async {
    if (_urlsDescargando.contains(url)) return;
    setState(() => _urlsDescargando.add(url));
    final aviso = ScaffoldMessenger.of(context);
    aviso.showSnackBar(
      SnackBar(
        content: Text(
          'Descargando ${material.titulo}…',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
      ),
    );
    try {
      await abrirArchivoMaterial(
        ref,
        context,
        url,
        alDescargar: aviso.hideCurrentSnackBar,
      );
    } finally {
      if (mounted) setState(() => _urlsDescargando.remove(url));
    }
  }

  void _abrirChecklist(MaterialEducativo material) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChecklistInteractivo(
        titulo: material.titulo,
        items: parsearItemsChecklist(material.cuerpo),
        textoIntro: textoInformativoChecklist(material.cuerpo),
        enHoja: true,
      ),
    );
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contenidosAsync = ref.watch(contenidosEducativosProvider);
    final favoritosAsync = ref.watch(idsFavoritosProvider);
    final descargados = ref.watch(contenidosDescargadosProvider);
    final favoritos = favoritosAsync.value ?? <String>[];

    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          EncabezadoGradiente(
            titulo: 'Biblioteca educativa',
            subtitulo: 'Aprende y prepárate',
            logo: const AssetImage('assets/images/OnCuidar.png'),
            tamanoTitulo: 20,
            alto: 100,
            reservaDerecha: 104,
            alTocarLogo: () => context.go('/dashboard'),
            accionDerecha: Row(
              children: [
                _botonBusqueda(),
                const SizedBox(width: 8),
                _botonFavoritos(favoritos.length),
              ],
            ),
          ),
          Expanded(
            child: contenidosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const _EstadoVacio(
                mensaje: 'No se pudieron cargar los materiales.',
              ),
              data: (items) {
                _verificarDescargas(items);
                final filtrados = _filtrar(items, favoritos.toSet());
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_buscando) _campoBusqueda(),
                      const SizedBox(height: 10),
                      _filaFiltros(),
                      const SizedBox(height: 6),
                      Expanded(child: _lista(filtrados, descargados)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonBusqueda() {
    return BotonCircular(
      clave: const Key('alternarBusquedaBiblioteca'),
      tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar material',
      alTocar: _alternarBusqueda,
      hijo: Icon(
        _buscando ? Icons.arrow_back : Icons.search,
        color: Paleta.doradoOscuro,
        size: 22,
      ),
    );
  }

  Widget _botonFavoritos(int totalFavoritos) {
    return BotonCircular(
      clave: const Key('alternarFavoritos'),
      tooltip: _soloFavoritos
          ? 'Ver todos los materiales'
          : 'Ver materiales guardados',
      alTocar: () => setState(() => _soloFavoritos = !_soloFavoritos),
      hijo: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.bookmark,
            color: _soloFavoritos
                ? Paleta.doradoOscuro
                : Paleta.textoSecundario,
            size: 22,
          ),
          if (totalFavoritos > 0 && !_soloFavoritos)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Paleta.doradoOscuro,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$totalFavoritos',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _campoBusqueda() {
    return CampoBusqueda(
      claveCampo: const Key('campoBusquedaBiblioteca'),
      claveBorrar: const Key('borrarBusquedaBiblioteca'),
      controlador: _controladorBusqueda,
      pista: 'Buscar material...',
      alCambiar: (valor) => setState(() => _busqueda = valor),
      mostrarBorrar: _busqueda.isNotEmpty,
    );
  }

  Widget _filaFiltros() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: etiquetasFiltro.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final etiqueta = etiquetasFiltro[i];
          final seleccionado = _filtro == etiqueta;
          return GestureDetector(
            onTap: () => setState(() => _filtro = etiqueta),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: seleccionado ? Paleta.doradoMedio : Paleta.doradoClaro,
                borderRadius: BorderRadius.circular(20),
                boxShadow: seleccionado
                    ? [
                        BoxShadow(
                          color: Paleta.doradoOscuro.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                etiqueta,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: seleccionado ? Colors.white : const Color(0xFF7A6030),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _lista(List<MaterialEducativo> filtrados, Set<String> descargados) {
    if (filtrados.isEmpty) {
      return _EstadoVacio(
        mensaje: _soloFavoritos
            ? 'No tienes materiales guardados todavía.'
            : 'No se encontraron materiales.',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(top: 4),
      children: [
        for (final material in filtrados)
          _tarjetaMaterial(material, descargados),
      ],
    );
  }

  Widget _tarjetaMaterial(MaterialEducativo material, Set<String> descargados) {
    final url = material.urlArchivo;
    return TarjetaMaterial(
      material: material,
      esFavorito:
          ref.read(idsFavoritosProvider).value?.contains(material.id) ?? false,
      descargado: url != null && descargados.contains(url),
      alTocar: () => _abrirMaterial(material),
      alAlternarFavorito: () {
        unawaited(alternarFavoritoMaterial(ref, context, material.id));
      },
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: Paleta.textoSecundario,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Paleta.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
