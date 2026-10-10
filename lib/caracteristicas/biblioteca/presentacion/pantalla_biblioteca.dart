import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/datos/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/categorias.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/secciones_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/dominio/temas_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/acciones_material.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_video.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_imagen.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/encabezado_seccion.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/etiqueta_tema.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/widgets/tarjeta_material.dart';
import 'package:oncuidar/compartido/widgets/buscador.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';
import 'package:oncuidar/compartido/widgets/insignia_conteo.dart';

class BibliotecaScreen extends ConsumerStatefulWidget {
  const BibliotecaScreen({super.key, this.abrirId});

  final String? abrirId;

  @override
  ConsumerState<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends ConsumerState<BibliotecaScreen> {
  String _busqueda = '';
  String _filtro = 'Todos';
  bool _soloFavoritos = false;
  bool _buscando = false;
  final Set<String> _urlsDescargando = {};
  final _controladorBusqueda = TextEditingController();
  late bool _abrirPendiente = widget.abrirId != null;

  void _abrirSolicitado(List<MaterialEducativo> items) {
    if (!_abrirPendiente) return;
    _abrirPendiente = false;
    final material = items.where((m) => m.id == widget.abrirId).firstOrNull;
    if (material == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_abrirMaterial(material));
    });
  }

  List<MaterialEducativo> _filtrar(
    List<MaterialEducativo> items,
    Set<String> favoritos,
    String tema,
  ) {
    final termino = _busqueda.trim().toLowerCase();
    final filtrados = items.where((material) {
      if (!coincideFiltro(_filtro, material.categoria)) return false;
      if (!coincideTema(tema, material.tema)) return false;
      if (_soloFavoritos && !favoritos.contains(material.id)) return false;
      if (termino.isNotEmpty &&
          !material.titulo.toLowerCase().contains(termino)) {
        return false;
      }
      return true;
    });
    return ordenarPorTemaYTitulo(filtrados);
  }

  bool _hayFiltros(String tema) =>
      _filtro != 'Todos' ||
      tema != temaTodas ||
      _soloFavoritos ||
      _busqueda.trim().isNotEmpty;

  void _quitarFiltros() {
    ref.read(temaSeleccionadoProvider.notifier).seleccionar(temaTodas);
    setState(() {
      _filtro = 'Todos';
      _soloFavoritos = false;
      _busqueda = '';
      _controladorBusqueda.clear();
    });
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

  Future<void> _abrirMaterial(MaterialEducativo material) async {
    if (material.esVideo) {
      await _reproducirVideo(material);
      return;
    }
    final url = material.urlArchivo;
    if (url != null && url.isNotEmpty) {
      await _abrirArchivo(material, url);
      return;
    }
    final imagen = material.urlImagen;
    if (imagen != null && imagen.isNotEmpty) {
      unawaited(
        abrirVisorImagen(
          context,
          url: imagen,
          titulo: material.titulo,
          idMaterial: material.id,
        ),
      );
      return;
    }
    if (context.mounted) unawaited(context.push('/biblioteca/${material.id}'));
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
        material,
        alDescargar: aviso.hideCurrentSnackBar,
      );
    } finally {
      if (mounted) setState(() => _urlsDescargando.remove(url));
    }
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
                _abrirSolicitado(items);
                final temas = temasDistintos(items);
                final seleccionado = ref.watch(temaSeleccionadoProvider);
                final tema = temaVigente(seleccionado, temas);
                if (tema != seleccionado) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ref
                          .read(temaSeleccionadoProvider.notifier)
                          .reiniciarSiNoExiste(temas);
                    }
                  });
                }
                final filtrados = _filtrar(items, favoritos.toSet(), tema);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_buscando) _campoBusqueda(),
                      const SizedBox(height: 10),
                      _filaFiltros(temas, tema),
                      _contador(filtrados.length, tema),
                      Expanded(child: _lista(filtrados, tema)),
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
        clipBehavior: Clip.none,
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
            InsigniaConteo.enEsquina(
              totalFavoritos,
              clave: const Key('insigniaFavoritos'),
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

  Widget _filaFiltros(List<String> temas, String tema) {
    final escala = MediaQuery.textScalerOf(context).scale(12);
    final alto = (escala * 1.4 + 22).clamp(40.0, 96.0);
    final hayTemas = temas.isNotEmpty;
    return SizedBox(
      height: alto,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: etiquetasFiltro.length + (hayTemas ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (i == etiquetasFiltro.length) return _chipTemas(temas, tema);
          final etiqueta = etiquetasFiltro[i];
          final seleccionado = _filtro == etiqueta;
          return Center(
            child: GestureDetector(
              key: Key('filtro_$etiqueta'),
              onTap: () => setState(() => _filtro = etiqueta),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: _decoracionChip(seleccionado),
                child: Text(
                  etiqueta,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: seleccionado
                        ? Paleta.sobreDorado
                        : Paleta.textoTerciario,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _decoracionChip(bool seleccionado) {
    return BoxDecoration(
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
    );
  }

  Widget _chipTemas(List<String> temas, String tema) {
    final activo = tema != temaTodas;
    final acento = activo ? acentoDelTema(tema) : null;
    final colorTexto = acento?.texto ?? Paleta.textoTerciario;
    return Center(
      child: Semantics(
        button: true,
        label: 'Temas',
        value: activo ? tema : 'Todos los temas',
        excludeSemantics: true,
        child: PopupMenuButton<String>(
          key: const Key('chipTemas'),
          tooltip: 'Filtrar por tema',
          padding: EdgeInsets.zero,
          position: PopupMenuPosition.under,
          color: Paleta.crema,
          onSelected: (valor) =>
              ref.read(temaSeleccionadoProvider.notifier).seleccionar(valor),
          itemBuilder: (_) => [
            for (final etiqueta in [temaTodas, ...temas])
              PopupMenuItem<String>(
                key: Key('tema_$etiqueta'),
                value: etiqueta,
                child: Row(
                  children: [
                    if (etiqueta != temaTodas) ...[
                      PuntoTema(tema: etiqueta),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        etiqueta == temaTodas ? 'Todos los temas' : etiqueta,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: etiqueta == tema
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: etiqueta == tema
                              ? Paleta.doradoOscuro
                              : Paleta.textoSecundario,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.only(left: 14, right: activo ? 4 : 8),
                constraints: const BoxConstraints(minHeight: 34),
                decoration: acento == null
                    ? _decoracionChip(false)
                    : BoxDecoration(
                        color: acento.fondo,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: acento.acento),
                      ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        activo ? tema : 'Temas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorTexto,
                        ),
                      ),
                    ),
                    if (activo)
                      GestureDetector(
                        key: const Key('quitarTema'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ref
                            .read(temaSeleccionadoProvider.notifier)
                            .seleccionar(temaTodas),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.close, size: 16, color: colorTexto),
                        ),
                      )
                    else
                      Icon(Icons.arrow_drop_down, size: 20, color: colorTexto),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contador(int total, String tema) {
    return Row(
      children: [
        Expanded(
          child: Text(
            total == 1 ? '1 resultado' : '$total resultados',
            key: const Key('contadorResultadosBiblioteca'),
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Paleta.textoSecundario,
            ),
          ),
        ),
        if (_hayFiltros(tema))
          TextButton(
            key: const Key('quitarFiltrosBiblioteca'),
            onPressed: _quitarFiltros,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'Quitar filtros',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Paleta.doradoOscuro,
              ),
            ),
          ),
      ],
    );
  }

  Widget _lista(List<MaterialEducativo> filtrados, String tema) {
    if (filtrados.isEmpty) {
      return _EstadoVacio(
        mensaje: _soloFavoritos
            ? 'No tienes materiales guardados todavía.'
            : 'No se encontraron materiales.',
        alQuitarFiltros: _hayFiltros(tema) ? _quitarFiltros : null,
      );
    }
    final secciones = _filtro == 'Todos'
        ? agruparPorSeccion(filtrados)
        : [SeccionBiblioteca(titulo: '', materiales: filtrados)];
    return ListView(
      padding: const EdgeInsets.only(top: 4),
      children: [
        for (final seccion in secciones) ...[
          if (seccion.titulo.isNotEmpty)
            EncabezadoSeccion(
              titulo: seccion.titulo,
              cantidad: seccion.materiales.length,
            ),
          for (final material in seccion.materiales) _tarjetaMaterial(material),
        ],
      ],
    );
  }

  Widget _tarjetaMaterial(MaterialEducativo material) {
    return TarjetaMaterial(
      material: material,
      esFavorito:
          ref.read(idsFavoritosProvider).value?.contains(material.id) ?? false,
      alTocar: () => _abrirMaterial(material),
      alAlternarFavorito: () {
        unawaited(alternarFavoritoMaterial(ref, context, material.id));
      },
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.mensaje, this.alQuitarFiltros});

  final String mensaje;
  final VoidCallback? alQuitarFiltros;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
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
            if (alQuitarFiltros != null)
              TextButton(
                key: const Key('quitarFiltrosVacioBiblioteca'),
                onPressed: alQuitarFiltros,
                child: Text(
                  'Quitar filtros',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: Paleta.doradoOscuro,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
