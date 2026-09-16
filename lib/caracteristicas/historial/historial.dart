import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../compartidos/widgets/dialogo_confirmacion.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/config_alerta.dart';
import '../../core/tema/paleta.dart';
import '../../core/util/formato_fecha.dart';
import '../../modelos/registro_clinico.dart';
import 'widgets/boton_cargar_mas.dart';
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
  final List<RegistroClinico> _cargados = [];
  String? _estadoFiltro;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _noHayMas = false;
  bool _cargandoMas = false;
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
        if (siguiente.length < 50) _noHayMas = true;
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
        _filaFiltros(),
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
        else ...[
          for (final registro in filtrados)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TarjetaRegistro(
                registro: registro,
                etiqueta: _etiquetaRegistro(registro, visibles),
                expandido: _expandidoId == registro.id,
                onToggle: () => setState(() {
                  _expandidoId =
                      _expandidoId == registro.id ? null : registro.id;
                }),
                onEditar: () => _editarRegistro(registro),
                onEliminar: () => _eliminarRegistro(registro),
              ),
            ),
          if (!_noHayMas && !_cargandoMas && visibles.length % 50 == 0)
            BotonCargarMas(
              cargando: _cargandoMas,
              alPulsar: () => _cargarMas(visibles),
            ),
        ],
      ],
    );
  }

  Widget _filaFiltros() {
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
            _botonRango(),
            if (hayRango) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Limpiar filtro de fecha',
                onPressed: _limpiarRango,
                style: IconButton.styleFrom(
                  backgroundColor: Paleta.doradoClaro.withValues(alpha: 0.6),
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
      ],
    );
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

  void _editarRegistro(RegistroClinico registro) {
    ref.read(registroEnEdicionProvider.notifier).state = registro;
    context.push('/registro-clinico');
  }

  Future<void> _eliminarRegistro(RegistroClinico registro) async {
    final paciente = ref.read(currentPatientProvider).value;
    if (paciente == null) return;
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
    final delDia = [
      for (final r in todos)
        if (mismoDia(r.fecha, registro.fecha)) r,
    ]..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    final posicion = delDia.indexWhere((r) => r.id == registro.id);
    if (posicion == -1) {
      return registro.tipoRegistro == 'extra'
          ? 'Registro extra'
          : 'Registro 1/$tope';
    }
    final numero = posicion + 1;
    return numero <= tope ? 'Registro $numero/$tope' : 'Registro extra';
  }
}
