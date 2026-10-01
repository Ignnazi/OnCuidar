import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../../compartidos/widgets/dialogo_confirmacion.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../core/configuracion/entrega_semana.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';
import '../../core/util/estilos.dart';
import '../../modelos/checklist_usuario.dart';
import '../../modelos/material_educativo.dart';
import 'categorias.dart';
import 'checklist_interactivo.dart';
import 'hoja_checklist_usuario.dart';
import 'hoja_editor_checklist.dart';
import 'pantalla_video.dart';
import 'parseo_contenido.dart';
import 'widgets/imagen_cacheada.dart';
import 'widgets/tarjeta_material.dart';

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
      if (!coincideFiltro(_filtro, material.category)) return false;
      if (_soloFavoritos && !favoritos.contains(material.id)) return false;
      if (termino.isNotEmpty &&
          !material.title.toLowerCase().contains(termino)) {
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
        final url = material.fileUrl;
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
    if (!habilitadaDesdeSemana(3) &&
        (material.esVideo || material.esChecklist)) {
      context.push('/proximamente?titulo=${material.title}');
      return;
    }
    if (material.esVideo) {
      await _reproducirVideo(material);
      return;
    }
    if (material.esChecklist) {
      _abrirChecklist(material);
      return;
    }
    final url = material.fileUrl;
    if (url != null && url.isNotEmpty) {
      await _abrirArchivo(material, url);
      return;
    }
    final imagen = material.imageUrl;
    if (imagen != null && imagen.isNotEmpty) {
      _mostrarInfografia(imagen, material.title);
      return;
    }
    if (context.mounted) context.push('/biblioteca/${material.id}');
  }

  void _mostrarInfografia(String url, String titulo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DialogoInfografia(url: url, titulo: titulo),
    );
  }

  Future<void> _reproducirVideo(MaterialEducativo material) async {
    final url = material.fileUrl;
    if (url == null || url.isEmpty) {
      if (context.mounted) context.push('/biblioteca/${material.id}');
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
            titulo: material.title,
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
          'Descargando ${material.title}…',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
      ),
    );
    try {
      final cache = ref.read(servicioCacheContenidoProvider);
      final archivo = await cache.descargar(url);
      ref.read(contenidosDescargadosProvider.notifier).marcarDescargado(url);
      if (!mounted) return;
      aviso.hideCurrentSnackBar();
      final resultado = await OpenFilex.open(archivo.path);
      if (resultado.type != ResultType.done && mounted) {
        _mostrarAviso(
          resultado.message.isNotEmpty
              ? resultado.message
              : 'No hay una aplicación para abrir este tipo de archivo.',
        );
      }
    } catch (e) {
      if (mounted) _mostrarAviso('Error al abrir el archivo: $e');
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
        titulo: material.title,
        items: parsearItemsChecklist(material.body),
        textoIntro: textoInformativoChecklist(material.body),
        enHoja: true,
      ),
    );
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: GoogleFonts.nunito(fontSize: 14)),
        backgroundColor: Paleta.error,
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
    final listasAsync = ref.watch(listasChecklistProvider);
    final favoritos = favoritosAsync.value ?? <String>[];

    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          EncabezadoGradiente(
            titulo: 'Biblioteca educativa',
            subtitulo: 'Aprende y prepárate',
            logo: AssetImage('assets/images/OnCuidar.png'),
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
              error: (e, _) => _EstadoVacio(
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
                      Expanded(
                        child: _lista(
                          filtrados,
                          descargados,
                          listasAsync.value ?? const [],
                        ),
                      ),
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
    return Tooltip(
      message: _buscando ? 'Cerrar búsqueda' : 'Buscar material',
      child: GestureDetector(
        key: const Key('alternarBusquedaBiblioteca'),
        onTap: _alternarBusqueda,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _buscando ? Icons.arrow_back : Icons.search,
            color: Paleta.doradoOscuro,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _botonFavoritos(int totalFavoritos) {
    return Tooltip(
      message: _soloFavoritos
          ? 'Ver todos los materiales'
          : 'Ver materiales guardados',
      child: GestureDetector(
        key: const Key('alternarFavoritos'),
        onTap: () => setState(() => _soloFavoritos = !_soloFavoritos),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
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
        ),
      ),
    );
  }

  Widget _campoBusqueda() {
    return TextField(
      key: const Key('campoBusquedaBiblioteca'),
      controller: _controladorBusqueda,
      autofocus: true,
      onChanged: (valor) => setState(() => _busqueda = valor),
      style: GoogleFonts.nunito(fontSize: 14, color: Paleta.textoPrincipal),
      decoration:
          entradaDorada(
            hintText: 'Buscar material...',
            prefixIcon: const Icon(
              Icons.search,
              color: Paleta.textoSecundario,
              size: 20,
            ),
          ).copyWith(
            suffixIcon: _busqueda.isNotEmpty
                ? GestureDetector(
                    key: const Key('borrarBusquedaBiblioteca'),
                    onTap: () {
                      _controladorBusqueda.clear();
                      setState(() => _busqueda = '');
                    },
                    child: const Icon(
                      Icons.cancel_rounded,
                      color: Paleta.textoSecundario,
                      size: 18,
                    ),
                  )
                : null,
          ),
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

  Widget _lista(
    List<MaterialEducativo> filtrados,
    Set<String> descargados,
    List<ChecklistUsuario> listas,
  ) {
    final mostrarSeccion =
        habilitadaDesdeSemana(3) &&
        (_filtro == 'Todos' || _filtro == 'Checklist') &&
        (filtrados.isNotEmpty || listas.isNotEmpty);
    if (filtrados.isEmpty && !mostrarSeccion) {
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
        if (mostrarSeccion) ...[
          const SizedBox(height: 4),
          _encabezadoMisChecklists(),
          const SizedBox(height: 8),
          for (final lista in listas) _tarjetaChecklist(lista),
        ],
      ],
    );
  }

  Widget _tarjetaMaterial(MaterialEducativo material, Set<String> descargados) {
    final url = material.fileUrl;
    return TarjetaMaterial(
      material: material,
      esFavorito:
          ref.read(idsFavoritosProvider).value?.contains(material.id) ?? false,
      descargado: url != null && descargados.contains(url),
      alTocar: () => _abrirMaterial(material),
      alAlternarFavorito: () {
        unawaited(_alternarFavorito(material.id));
      },
    );
  }

  Future<void> _alternarFavorito(String materialId) async {
    final base = ref.read(servicioBaseDatosProvider);
    final ids = ref.read(idsFavoritosProvider).value ?? const <String>[];
    final eraFavorito = ids.contains(materialId);
    try {
      await base.alternarFavorito(materialId);
      if (mounted) {
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
      if (mounted) {
        _mostrarAviso('No se pudo actualizar el favorito. Revisa tu conexión.');
      }
    }
  }

  Widget _encabezadoMisChecklists() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Mis Checklists',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Paleta.textoPrincipal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          key: const Key('agregarChecklist'),
          onTap: () => _abrirEditorChecklist(),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Paleta.doradoPrincipal,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 20),
                const SizedBox(width: 5),
                Text(
                  'Crear checklist',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaChecklist(ChecklistUsuario lista) {
    final progreso = lista.items.isEmpty
        ? 0.0
        : lista.indicesMarcados.length / lista.items.length;
    final completado = progreso >= 1.0;
    return GestureDetector(
      key: Key('checklist_${lista.id}'),
      onTap: () => _abrirChecklistUsuario(lista),
      onLongPress: () => _opcionesChecklist(lista),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Paleta.tarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Paleta.doradoPrincipal.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Paleta.doradoMedio, Paleta.doradoClaro],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lista.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Paleta.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: Paleta.doradoPrincipal.withValues(
                              alpha: 0.12,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completado
                                  ? Paleta.verdeExito
                                  : Paleta.doradoPrincipal,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${lista.indicesMarcados.length}/${lista.items.length}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: completado
                              ? Paleta.verdeExito
                              : Paleta.doradoOscuro,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<_AccionChecklist>(
              onSelected: (accion) {
                switch (accion) {
                  case _AccionChecklist.editar:
                    _abrirEditorChecklist(lista: lista);
                  case _AccionChecklist.eliminar:
                    _eliminarChecklist(lista);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _AccionChecklist.editar,
                  child: ListTile(
                    leading: const Icon(
                      Icons.edit_outlined,
                      color: Paleta.doradoOscuro,
                    ),
                    title: const Text(
                      'Editar',
                      style: TextStyle(
                        color: Paleta.doradoOscuro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: _AccionChecklist.eliminar,
                  child: ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Paleta.error,
                    ),
                    title: const Text(
                      'Eliminar',
                      style: TextStyle(
                        color: Paleta.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Paleta.doradoClaro.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Paleta.doradoOscuro,
                ),
              ),
              color: Paleta.tarjeta,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tooltip: 'Opciones del checklist',
            ),
          ],
        ),
      ),
    );
  }

  void _abrirChecklistUsuario(ChecklistUsuario lista) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HojaChecklistUsuario(checklist: lista),
    );
  }

  void _abrirEditorChecklist({ChecklistUsuario? lista}) {
    final pacienteAsync = ref.read(currentPatientProvider);
    final paciente = pacienteAsync.value;
    if (paciente == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HojaEditorChecklist(checklist: lista),
    );
  }

  void _opcionesChecklist(ChecklistUsuario lista) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Paleta.textoAyuda.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                lista.titulo,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Paleta.textoPrincipal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1, color: Paleta.bordeTarjeta),
            ListTile(
              leading: const Icon(Icons.edit, color: Paleta.doradoPrincipal),
              title: Text(
                'Editar',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Paleta.textoPrincipal,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _abrirEditorChecklist(lista: lista);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Paleta.error),
              title: Text(
                'Eliminar',
                style: GoogleFonts.nunito(fontSize: 14, color: Paleta.error),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _eliminarChecklist(lista);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarChecklist(ChecklistUsuario lista) async {
    final pacienteAsync = ref.read(currentPatientProvider);
    final paciente = pacienteAsync.value;
    if (paciente == null) return;
    final confirmado = await mostrarDialogoConfirmacion(
      context,
      icono: Icons.delete_outline,
      titulo: 'Eliminar checklist',
      mensaje: '¿Seguro que deseas eliminar "${lista.titulo}"?',
      textoConfirmar: 'Eliminar',
      colorConfirmar: Paleta.error,
    );
    if (confirmado != true) return;
    try {
      await ref
          .read(servicioBaseDatosProvider)
          .eliminarListaChecklist(paciente.id, lista.id);
    } catch (e) {
      if (mounted) _mostrarAviso('Error al eliminar el checklist: $e');
    }
  }
}

enum _AccionChecklist { editar, eliminar }

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

class DialogoInfografia extends StatelessWidget {
  const DialogoInfografia({super.key, required this.url, required this.titulo});

  final String url;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            maxScale: 5,
            child: AspectRatio(
              aspectRatio: 1,
              child: ImagenCacheada(
                url: url,
                ajuste: BoxFit.contain,
                reemplazo: const _ImagenIndisponible(),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 48,
            child: Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagenIndisponible extends StatelessWidget {
  const _ImagenIndisponible();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white70, size: 40),
    );
  }
}
