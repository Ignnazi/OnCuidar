import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_visor_pdf.dart';
import 'package:oncuidar/caracteristicas/historial/datos/archivo_exportacion.dart';
import 'package:oncuidar/caracteristicas/historial/dominio/filtro_historial.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/controlador_historial.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/pantalla_vista_excel.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/boton_cargar_mas.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/cabecera_tarjeta_registro.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/dialogo_rango_fechas.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/estado_vacio.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/filtros_historial.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/hoja_exportacion.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/widgets/tarjeta_registro.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/proveedores_perfil.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/conteo_registros.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/proveedores_registro_clinico.dart';
import 'package:oncuidar/compartido/widgets/dialogo_confirmacion.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key, this.filtroFechaInicial});

  final DateTime? filtroFechaInicial;

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  final List<RegistroClinico> _cargados = [];
  late FiltroHistorial _filtro;
  bool _noHayMas = false;
  bool _cargandoMas = false;
  bool _exportando = false;
  String? _expandidoId;

  ControladorHistorial get _controlador =>
      ref.read(controladorHistorialProvider);

  @override
  void initState() {
    super.initState();
    _filtro = FiltroHistorial(inicio: widget.filtroFechaInicial);
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

  List<RegistroClinico> _filtradosActuales() {
    final base = ref.read(registrosClinicosProvider).value ?? const [];
    return [
      for (final r in _visibles(base))
        if (_filtro.admite(r)) r,
    ];
  }

  bool _hayMas(List<RegistroClinico> base) {
    if (_noHayMas) return false;
    if (_cargados.isEmpty) {
      return base.length >= ControladorHistorial.tamanoPagina;
    }
    return true;
  }

  Future<void> _cargarMas(List<RegistroClinico> visibles) async {
    final paciente = ref.read(pacienteActivoProvider).value;
    if (paciente == null || visibles.isEmpty) return;
    setState(() => _cargandoMas = true);
    try {
      final siguiente = await _controlador.cargarMas(
        paciente.id,
        visibles.last.creadoEn,
      );
      if (!mounted) return;
      setState(() {
        _cargados.addAll(siguiente);
        if (siguiente.length < ControladorHistorial.tamanoPagina) {
          _noHayMas = true;
        }
      });
    } catch (e) {
      if (mounted) _snack('Error al cargar registros: $e', Paleta.error);
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaConEncabezado(
      alRegresar: _regresar,
      encabezado: EncabezadoGradiente(
        titulo: 'Historial',
        subtitulo: 'Tus registros clínicos',
        logo: const AssetImage('assets/images/OnCuidar.png'),
        tamanoTitulo: 20,
        alTocarLogo: () => context.go('/dashboard'),
        accionDerecha: BotonNuevoRegistro(
          alPulsar: () => context.push('/registro-clinico'),
        ),
      ),
      contenido: _contenido(),
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
        if (_filtro.admite(r)) r,
    ];

    if (async.isLoading && visibles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
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
      return const EstadoVacio(
        Icons.history,
        'No hay registros aún',
        subtitulo: 'Crea el primer registro desde el botón de abajo.',
      );
    }

    final hayFiltros = _filtro.hayFiltros;
    final tope =
        ref.read(pacienteActivoProvider).value?.maximoRegistrosDia ?? 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FiltrosHistorial(
          filtro: _filtro,
          exportable: (filtrados.isNotEmpty || _hayMas(base)) && !_exportando,
          alCambiarEstado: (estado) =>
              setState(() => _filtro = _filtro.conEstado(estado)),
          alElegirRango: _elegirRango,
          alLimpiarRango: () =>
              setState(() => _filtro = _filtro.conRango(null, null)),
          alExportar: _exportar,
        ),
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
                etiqueta: etiquetaNumeroRegistro(registro, visibles, tope),
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

  void _snack(String mensaje, Color fondo) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: fondo));
  }

  Future<void> _exportar(FormatoExportacion formato) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final paciente = ref.read(pacienteActivoProvider).value;
      final registros = await _controlador.registrosParaExportar(
        paciente,
        _filtro,
        _filtradosActuales,
      );
      final nombreCuidador = await _nombreCuidador();
      final generadoEn = DateTime.now();
      final bytes = await _controlador.generar(
        formato,
        registros: registros,
        paciente: paciente,
        nombreCuidador: nombreCuidador,
        filtro: _filtro,
        generadoEn: generadoEn,
      );
      if (!mounted) return;
      await _ofrecerArchivo(
        bytes,
        formato,
        DatosHojaExcel(
          registros: registros,
          paciente: paciente,
          nombreCuidador: nombreCuidador,
          fechaInicio: _filtro.inicio,
          fechaFin: _filtro.fin,
          generadoEn: generadoEn,
        ),
      );
    } catch (e) {
      if (mounted) {
        _snack('No se pudo generar el ${formato.nombre}: $e', Paleta.error);
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
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

  Future<void> _ofrecerArchivo(
    Uint8List bytes,
    FormatoExportacion formato,
    DatosHojaExcel hoja,
  ) async {
    final accion = await mostrarHojaExportacion(context);
    if (!mounted || accion == null) return;
    Future<void> compartir() =>
        compartirArchivoExportado(bytes, formato.extension);
    if (accion == AccionExportacion.compartir) {
      await compartir();
      return;
    }
    await _abrirDentroDeLaApp(bytes, formato, hoja, compartir);
  }

  Future<void> _abrirDentroDeLaApp(
    Uint8List bytes,
    FormatoExportacion formato,
    DatosHojaExcel hoja,
    Future<void> Function() compartir,
  ) async {
    try {
      switch (formato) {
        case FormatoExportacion.pdf:
          final archivo = await escribirArchivoTemporal(bytes, 'pdf');
          if (!mounted) return;
          await abrirVisorPdf(
            context,
            ruta: archivo.path,
            titulo: 'Historial clínico',
            alCompartir: () => unawaited(compartir()),
          );
        case FormatoExportacion.excel:
          await abrirVistaExcel(
            context,
            datos: hoja,
            alCompartir: () => unawaited(compartir()),
          );
      }
    } catch (e) {
      if (mounted) {
        _snack('No se pudo abrir el archivo: $e', Paleta.error);
      }
    }
  }

  Future<void> _elegirRango() async {
    final resultado = await mostrarDialogoRangoFechas(
      context,
      fechaInicio: _filtro.inicio,
      fechaFin: _filtro.fin,
    );
    if (resultado == null || !mounted) return;
    setState(() => _filtro = _filtro.conRango(resultado.inicio, resultado.fin));
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
    final paciente = ref.read(pacienteActivoProvider).value;
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
      await _controlador.eliminar(paciente.id, registro.id);
      if (mounted) {
        setState(() => _cargados.removeWhere((r) => r.id == registro.id));
        _snack('Registro eliminado', Paleta.doradoPrincipal);
      }
    } catch (_) {
      if (mounted) {
        _snack('No se pudo eliminar. Intenta de nuevo.', Paleta.error);
      }
    }
  }
}
