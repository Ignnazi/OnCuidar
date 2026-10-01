import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../compartidos/widgets/dialogo_confirmacion.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/config_alerta.dart';
import '../../core/tema/paleta.dart';
import '../../core/util/formato_fecha.dart';
import '../../modelos/registro_clinico.dart';
import 'exportadores/exportador_excel.dart';
import 'exportadores/exportador_pdf.dart';
import 'widgets/boton_cargar_mas.dart';
import 'widgets/cabecera_registro.dart';
import 'widgets/chip_estado.dart';
import 'widgets/dialogo_rango_fechas.dart';
import 'widgets/estado_vacio.dart';
import 'widgets/tarjeta_registro.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key, this.filtroFechaInicial});

  final DateTime? filtroFechaInicial;

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  static const _tamanoPagina = 50;
  final List<RegistroClinico> _cargados = [];
  String? _estadoFiltro;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _noHayMas = false;
  bool _cargandoMas = false;
  bool _exportando = false;
  String? _expandidoId;

  @override
  void initState() {
    super.initState();
    _fechaInicio = widget.filtroFechaInicial;
  }

  bool _coincideFecha(DateTime fecha) {
    final inicio = _fechaInicio;
    final fin = _fechaFin;
    if (inicio == null && fin == null) return true;
    if (inicio != null && fin == null) return mismoDia(fecha, inicio);
    if (inicio == null && fin != null) {
      final hasta = DateTime(fin.year, fin.month, fin.day, 23, 59, 59, 999);
      return !fecha.isAfter(hasta);
    }
    final desde = DateTime(inicio!.year, inicio.month, inicio.day);
    final hasta = DateTime(
      fin!.year,
      fin.month,
      fin.day,
    ).add(const Duration(days: 1));
    return !fecha.isBefore(desde) && fecha.isBefore(hasta);
  }

  List<RegistroClinico> _visibles(List<RegistroClinico> base) {
    final porId = <String, RegistroClinico>{};
    for (final r in _cargados) {
      porId[r.id] = r;
    }
    for (final r in base) {
      porId[r.id] = r;
    }
    final lista = porId.values.toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return lista;
  }

  Future<void> _cargarMas(List<RegistroClinico> visibles) async {
    final paciente = ref.read(currentPatientProvider).value;
    final base = ref.read(servicioBaseDatosProvider);
    if (paciente == null || visibles.isEmpty) return;
    setState(() => _cargandoMas = true);
    try {
      final siguiente = await base.cargarMasRegistrosClinicos(
        paciente.id,
        visibles.last.creadoEn,
      );
      if (!mounted) return;
      setState(() {
        _cargados.addAll(siguiente);
        if (siguiente.length < _tamanoPagina) _noHayMas = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar registros: $e'),
          backgroundColor: Paleta.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final altoBarra = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _regresar();
      },
      child: Scaffold(
        backgroundColor: Paleta.crema,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, altoBarra + 100 + 20, 20, 24),
                child: _contenido(),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EncabezadoGradiente(
                titulo: 'Historial',
                subtitulo: 'Tus registros clínicos',
                logo: const AssetImage('assets/images/OnCuidar.png'),
                tamanoTitulo: 20,
                reservaDerecha: 140,
                alTocarLogo: () => context.go('/dashboard'),
                accionDerecha: Tooltip(
                  message: 'Nuevo registro',
                  child: GestureDetector(
                    key: const Key('botonNuevoRegistro'),
                    onTap: () => context.push('/registro-clinico'),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Paleta.doradoOscuro.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: Paleta.doradoOscuro,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nuevo registro',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Paleta.doradoOscuro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _regresar() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/dashboard');
    }
  }

  Widget _contenido() {
    final async = ref.watch(registrosClinicosProvider);
    final base = async.value ?? const <RegistroClinico>[];
    final visibles = _visibles(base);
    final filtrados = [
      for (final r in visibles)
        if (r.nivelAlerta.name == _estadoFiltro || _estadoFiltro == null)
          if (_coincideFecha(r.fecha)) r,
    ];
    final hayFiltros =
        _estadoFiltro != null || _fechaInicio != null || _fechaFin != null;

    if (async.isLoading && visibles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: CircularProgressIndicator(color: Paleta.doradoPrincipal),
        ),
      );
    }

    if (async.hasError) {
      return EstadoVacio(
        Icons.error_outline,
        'Error al cargar registros',
        subtitulo: '${async.error}',
      );
    }

    if (visibles.isEmpty) {
      return EstadoVacio(
        Icons.history,
        'No hay registros aún',
        subtitulo: 'Crea el primer registro desde el botón de abajo.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filaFiltros(filtrados.isNotEmpty || _hayMas(base)),
        const SizedBox(height: 16),
        if (filtrados.isEmpty)
          EstadoVacio(
            hayFiltros ? Icons.filter_alt_off : Icons.history,
            hayFiltros
                ? 'No hay registros para este filtro.'
                : 'No hay registros aún',
            subtitulo: hayFiltros
                ? null
                : 'Crea el primer registro desde el botón de abajo.',
          )
        else
          for (final registro in filtrados)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TarjetaRegistro(
                registro: registro,
                etiqueta: _etiquetaRegistro(registro, visibles),
                expandido: _expandidoId == registro.id,
                onToggle: () => setState(() {
                  _expandidoId = _expandidoId == registro.id
                      ? null
                      : registro.id;
                }),
                onEditar: () => _editarRegistro(registro),
                onEliminar: () => _eliminarRegistro(registro),
              ),
            ),
        if (_hayMas(base))
          BotonCargarMas(
            cargando: _cargandoMas,
            alPulsar: () => _cargarMas(visibles),
          ),
      ],
    );
  }

  bool _hayMas(List<RegistroClinico> base) {
    if (_noHayMas) return false;
    if (_cargados.isEmpty) return base.length >= _tamanoPagina;
    return true;
  }

  Widget _filaFiltros(bool exportable) {
    final hayRango = _fechaInicio != null || _fechaFin != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChipEstado(
                etiqueta: 'Todos',
                activo: _estadoFiltro == null,
                onTap: () => setState(() => _estadoFiltro = null),
              ),
              const SizedBox(width: 8),
              for (final nivel in NivelAlerta.values) ...[
                ChipEstado(
                  etiqueta: configAlerta(nivel).label,
                  activo: _estadoFiltro == nivel.name,
                  onTap: () => setState(() => _estadoFiltro = nivel.name),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _botonRango(),
                    if (hayRango) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Limpiar filtro de fecha',
                        onPressed: _limpiarRango,
                        style: IconButton.styleFrom(
                          backgroundColor: Paleta.doradoClaro.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _botonExportarPdf(exportable),
            const SizedBox(width: 8),
            _botonExportarExcel(exportable),
          ],
        ),
      ],
    );
  }

  Widget _botonExportarPdf(bool habilitado) {
    return _botonExportar(
      titulo: 'PDF',
      tooltip: 'Exportar PDF',
      icono: Icons.picture_as_pdf,
      colores: const [Paleta.doradoPrincipal, Paleta.doradoOscuro],
      habilitado: habilitado && !_exportando,
      onPulsar: () => _exportarPdf(),
    );
  }

  Widget _botonExportarExcel(bool habilitado) {
    return _botonExportar(
      titulo: 'Excel',
      tooltip: 'Exportar Excel',
      icono: Icons.table_chart,
      colores: const [Color(0xFF217346), Color(0xFF14401F)],
      habilitado: habilitado && !_exportando,
      onPulsar: () => _exportarExcel(),
    );
  }

  Widget _botonExportar({
    required String titulo,
    required String tooltip,
    required IconData icono,
    required List<Color> colores,
    required VoidCallback onPulsar,
    required bool habilitado,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: habilitado ? onPulsar : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: habilitado ? LinearGradient(colors: colores) : null,
              color: habilitado ? null : const Color(0xFFEDE3D2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icono,
                  size: 16,
                  color: habilitado ? Colors.white : Paleta.textoSecundario,
                ),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: habilitado ? Colors.white : Paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<RegistroClinico> _filtradosActuales() {
    final async = ref.read(registrosClinicosProvider);
    final base = async.value ?? const <RegistroClinico>[];
    final visibles = _visibles(base);
    return [
      for (final r in visibles)
        if (r.nivelAlerta.name == _estadoFiltro || _estadoFiltro == null)
          if (_coincideFecha(r.fecha)) r,
    ];
  }

  Future<void> _exportarPdf() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final paciente = ref.read(currentPatientProvider).value;
      final bytes = await generarPdfHistorial(
        registros: await _registrosParaExportar(),
        paciente: paciente,
        nombreCuidador: await _nombreCuidador(),
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        generadoEn: DateTime.now(),
      );
      if (!mounted) return;
      await _ofrecerArchivo(bytes, 'pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el PDF: $e'),
          backgroundColor: Paleta.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarExcel() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final paciente = ref.read(currentPatientProvider).value;
      final bytes = generarExcelHistorial(
        registros: await _registrosParaExportar(),
        paciente: paciente,
        nombreCuidador: await _nombreCuidador(),
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        generadoEn: DateTime.now(),
      );
      if (!mounted) return;
      await _ofrecerArchivo(bytes, 'xlsx');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el Excel: $e'),
          backgroundColor: Paleta.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  (DateTime?, DateTime?) _limitesRango() {
    DateTime inicioDia(DateTime f) => DateTime(f.year, f.month, f.day);
    DateTime diaSiguiente(DateTime f) => DateTime(f.year, f.month, f.day + 1);
    final inicio = _fechaInicio;
    final fin = _fechaFin;
    if (inicio == null && fin == null) return (null, null);
    if (fin == null) return (inicioDia(inicio!), diaSiguiente(inicio));
    return (inicio == null ? null : inicioDia(inicio), diaSiguiente(fin));
  }

  Future<List<RegistroClinico>> _registrosParaExportar() async {
    final paciente = ref.read(currentPatientProvider).value;
    if (paciente == null) return _filtradosActuales();
    final (desde, hasta) = _limitesRango();
    try {
      final todos = await ref
          .read(servicioBaseDatosProvider)
          .registrosClinicosEnRango(paciente.id, desde: desde, hasta: hasta);
      return [
        for (final r in todos)
          if (_estadoFiltro == null || r.nivelAlerta.name == _estadoFiltro)
            if (_coincideFecha(r.fecha)) r,
      ];
    } catch (_) {
      return _filtradosActuales();
    }
  }

  Future<void> _ofrecerArchivo(Uint8List bytes, String extension) async {
    final accion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Paleta.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (contexto) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('botonAbrirExportacion'),
              leading: const Icon(
                Icons.open_in_new_rounded,
                color: Paleta.doradoOscuro,
              ),
              title: const Text('Abrir archivo'),
              onTap: () => Navigator.of(contexto).pop('abrir'),
            ),
            ListTile(
              key: const Key('botonCompartirExportacion'),
              leading: const Icon(
                Icons.share_rounded,
                color: Paleta.doradoOscuro,
              ),
              title: const Text('Compartir'),
              onTap: () => Navigator.of(contexto).pop('compartir'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || accion == null) return;
    if (accion == 'compartir') {
      await _compartirArchivo(bytes, extension);
    } else {
      await _abrirArchivo(bytes, extension);
    }
  }

  Future<String> _nombreCuidador() async {
    try {
      final cuidador = await ref.read(cuidadorProvider.future);
      return (cuidador?['nombre'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _abrirArchivo(Uint8List bytes, String extension) async {
    final dir = await getTemporaryDirectory();
    final archivo = File(
      '${dir.path}${Platform.pathSeparator}${_nombreArchivo(extension)}',
    );
    await archivo.writeAsBytes(bytes, flush: true);
    final resultado = await OpenFilex.open(archivo.path);
    if (resultado.type == ResultType.noAppToOpen) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay una app para abrir el archivo; se abre el menú de compartir',
          ),
          backgroundColor: Paleta.doradoOscuro,
        ),
      );
      await _compartirArchivo(bytes, extension);
    } else if (resultado.type != ResultType.done) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el archivo: ${resultado.message}'),
          backgroundColor: Paleta.error,
        ),
      );
    }
  }

  Future<void> _compartirArchivo(Uint8List bytes, String extension) async {
    final dir = await getTemporaryDirectory();
    final archivo = File(
      '${dir.path}${Platform.pathSeparator}${_nombreArchivo(extension)}',
    );
    await archivo.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(archivo.path)],
        subject: 'Historial clínico OnCuidar',
        text: 'Historial clínico OnCuidar',
      ),
    );
  }

  String _nombreArchivo(String extension) {
    final ahora = DateTime.now();
    final mes = ahora.month.toString().padLeft(2, '0');
    final dia = ahora.day.toString().padLeft(2, '0');
    final fecha = '${ahora.year}-$mes-$dia';
    final hora =
        '${ahora.hour.toString().padLeft(2, '0')}${ahora.minute.toString().padLeft(2, '0')}';
    return 'historial_oncuidar_${fecha}_$hora.$extension';
  }

  Widget _botonRango() {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: _elegirRango,
        icon: const Icon(
          Icons.calendar_month_outlined,
          size: 18,
          color: Paleta.doradoOscuro,
        ),
        label: Text(
          _etiquetaRango(),
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Paleta.doradoOscuro,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Paleta.doradoOscuro,
          side: const BorderSide(color: Paleta.bordeTarjeta),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  String _etiquetaRango() {
    final inicio = _fechaInicio;
    final fin = _fechaFin;
    final ahora = DateTime.now();
    if (inicio != null && fin != null) {
      if (mismoDia(inicio, fin) && mismoDia(inicio, ahora)) return 'Hoy';
      if (mismoDia(inicio, fin)) return fechacorta(inicio);
      return '${fechacorta(inicio)} - ${fechacorta(fin)}';
    }
    if (inicio != null) {
      if (mismoDia(inicio, ahora)) return 'Hoy';
      return 'Inicio · ${fechacorta(inicio)}';
    }
    if (fin != null) return 'Hasta · ${fechacorta(fin)}';
    return 'Filtrar fecha';
  }

  Future<void> _elegirRango() async {
    final resultado = await mostrarDialogoRangoFechas(
      context,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _fechaInicio = resultado.inicio;
      _fechaFin = resultado.fin;
    });
  }

  void _limpiarRango() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
    });
  }

  Future<void> _editarRegistro(RegistroClinico registro) async {
    if (!esEditableHoy(registro)) return;
    ref.read(registroEnEdicionProvider.notifier).state = registro;
    await context.push('/registro-clinico');
    if (!mounted) return;
    if (_cargados.any((r) => r.id == registro.id)) {
      setState(() {
        _cargados.clear();
        _noHayMas = false;
      });
    }
  }

  Future<void> _eliminarRegistro(RegistroClinico registro) async {
    final paciente = ref.read(currentPatientProvider).value;
    if (paciente == null || !esEditableHoy(registro)) return;
    final confirmar = await mostrarDialogoConfirmacion(
      context,
      icono: Icons.delete_outline,
      titulo: 'Eliminar registro',
      mensaje:
          '¿Eliminar este registro definitivamente? Esta acción no se puede '
          'deshacer.',
      textoConfirmar: 'Eliminar',
      colorConfirmar: Paleta.error,
      iconoConfirmar: Icons.delete_forever_outlined,
    );
    if (confirmar != true || !mounted) return;
    try {
      await ref
          .read(servicioBaseDatosProvider)
          .eliminarRegistroClinico(paciente.id, registro.id);
      if (mounted) {
        setState(() => _cargados.removeWhere((r) => r.id == registro.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registro eliminado'),
            backgroundColor: Paleta.doradoPrincipal,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar. Intenta de nuevo.'),
            backgroundColor: Paleta.error,
          ),
        );
      }
    }
  }

  String _etiquetaRegistro(
    RegistroClinico registro,
    List<RegistroClinico> todos,
  ) {
    final tope =
        ref.read(currentPatientProvider).value?.maximoRegistrosDia ?? 3;
    if (registro.tipoRegistro == 'extra') return 'Registro extra';
    final delDia = [
      for (final r in todos)
        if (r.tipoRegistro == 'programado' && mismoDia(r.fecha, registro.fecha))
          r,
    ]..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    final posicion = delDia.indexWhere((r) => r.id == registro.id);
    if (posicion == -1) return 'Registro 1/$tope';
    final numero = posicion + 1;
    return numero <= tope ? 'Registro $numero/$tope' : 'Registro extra';
  }
}
