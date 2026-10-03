import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/proveedores_biblioteca.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/catalogo_preguntas.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/pregunta_base.dart';
import 'package:oncuidar/compartido/widgets/buscador.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _controladorBusqueda = TextEditingController();
  bool _buscando = false;
  String _terminoBusqueda = '';
  String _categoriaActiva = 'Todas';
  String? _preguntaAbierta;

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  List<String> get _categorias => ['Todas', ...categoriasDePreguntas()];

  List<PreguntaBase> get _preguntasFiltradas {
    final termino = normalizarTexto(_terminoBusqueda);
    return preguntasFrecuentes.where((pregunta) {
      if (_categoriaActiva != 'Todas' &&
          pregunta.categoria != _categoriaActiva) {
        return false;
      }
      if (termino.isEmpty) {
        return true;
      }
      return normalizarTexto(pregunta.pregunta).contains(termino) ||
          normalizarTexto(pregunta.respuesta).contains(termino) ||
          normalizarTexto(pregunta.categoria).contains(termino);
    }).toList();
  }

  void _actualizarBusqueda(String valor) {
    setState(() {
      _terminoBusqueda = valor;
      if (_preguntaAbierta != null &&
          !_preguntasFiltradas.any((p) => p.id == _preguntaAbierta)) {
        _preguntaAbierta = null;
      }
    });
  }

  void _seleccionarCategoria(String categoria) {
    setState(() => _categoriaActiva = categoria);
  }

  void _alternarPregunta(PreguntaBase pregunta) {
    setState(() {
      _preguntaAbierta = _preguntaAbierta == pregunta.id ? null : pregunta.id;
    });
  }

  void _alternarBusqueda() {
    setState(() {
      _buscando = !_buscando;
      if (!_buscando) {
        _controladorBusqueda.clear();
        _terminoBusqueda = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _preguntasFiltradas;
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          EncabezadoGradiente(
            titulo: 'Preguntas frecuentes',
            subtitulo: 'Resuelve tus dudas de cuidado',
            logo: const AssetImage('assets/images/OnCuidar.png'),
            tamanoTitulo: 20,
            alto: 100,
            reservaDerecha: 64,
            alTocarLogo: () => context.go('/dashboard'),
            accionDerecha: _botonBusqueda(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_buscando) _campoBusqueda(),
                  const SizedBox(height: 10),
                  _filaCategorias(),
                  const SizedBox(height: 6),
                  Expanded(
                    child: filtradas.isEmpty
                        ? _estadoSinResultados()
                        : ListView.separated(
                            padding: const EdgeInsets.only(top: 4),
                            itemCount: filtradas.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, indice) =>
                                _tarjetaPregunta(filtradas[indice]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonBusqueda() {
    return BotonCircular(
      clave: const Key('alternarBusquedaFaq'),
      tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar una pregunta',
      alTocar: _alternarBusqueda,
      hijo: Icon(
        _buscando ? Icons.arrow_back : Icons.search,
        color: Paleta.doradoOscuro,
        size: 22,
      ),
    );
  }

  Widget _campoBusqueda() {
    return CampoBusqueda(
      claveCampo: const Key('campoBusquedaFaq'),
      claveBorrar: const Key('borrarBusquedaFaq'),
      controlador: _controladorBusqueda,
      pista: 'Buscar pregunta…',
      alCambiar: _actualizarBusqueda,
      mostrarBorrar: _terminoBusqueda.isNotEmpty,
    );
  }

  Widget _filaCategorias() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categorias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, indice) {
          final etiqueta = _categorias[indice];
          final activo = _categoriaActiva == etiqueta;
          return AnimatedContainer(
            key: Key('chipCategoriaFaq_$etiqueta'),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 40,
            decoration: BoxDecoration(
              gradient: activo
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Paleta.doradoMedio, Paleta.doradoOscuro],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Paleta.tarjeta, Paleta.tarjeta],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: activo ? Colors.transparent : Paleta.doradoClaro,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Paleta.doradoOscuro.withValues(
                    alpha: activo ? 0.30 : 0.0,
                  ),
                  blurRadius: activo ? 6 : 0,
                  offset: Offset(0, activo ? 2 : 0),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _seleccionarCategoria(etiqueta),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: activo ? Colors.white : Paleta.doradoOscuro,
                      ),
                      child: Text(
                        etiqueta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaPregunta(PreguntaBase pregunta) {
    final abierta = _preguntaAbierta == pregunta.id;
    return Container(
      decoration: BoxDecoration(
        color: Paleta.tarjeta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Paleta.bordeTarjeta),
        boxShadow: [
          BoxShadow(
            color: Paleta.doradoOscuro.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            key: Key('faq_${pregunta.id}'),
            onTap: () => _alternarPregunta(pregunta),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pregunta.categoria,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Paleta.doradoOscuro,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pregunta.pregunta,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Paleta.textoPrincipal,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: abierta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Paleta.textoSecundario,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: abierta
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Paleta.bordeTarjeta),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pregunta.respuesta,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Paleta.textoTerciario,
                            height: 1.6,
                          ),
                        ),
                        if (pregunta.contenidoRelacionadoId != null)
                          _EnlaceMaterialRelacionado(pregunta: pregunta),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _estadoSinResultados() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 44,
              color: Paleta.textoSecundario,
            ),
            const SizedBox(height: 10),
            Text(
              'No se encontraron preguntas que coincidan con tu búsqueda.',
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

class _EnlaceMaterialRelacionado extends ConsumerWidget {
  const _EnlaceMaterialRelacionado({required this.pregunta});

  final PreguntaBase pregunta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogo = ref.watch(contenidosEducativosProvider).value ?? const [];
    final material = materialRelacionado(pregunta, catalogo);
    if (material == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton.icon(
        key: Key('verMaterial_${pregunta.id}'),
        onPressed: () => context.push('/biblioteca/${material.id}'),
        icon: const Icon(Icons.menu_book_rounded, size: 18),
        label: const Text('Ver material relacionado'),
        style: TextButton.styleFrom(
          foregroundColor: Paleta.doradoOscuro,
          padding: EdgeInsets.zero,
          textStyle: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
