import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../compartidos/widgets/dialogo_confirmacion.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/servicios/servicio_cifrado.dart';
import '../../core/servicios/servicio_notificaciones.dart';
import '../../core/tema/paleta.dart';
import '../../core/util/estilos.dart';
import '../../core/util/formato_fecha.dart';
import '../../modelos/recordatorio.dart';

const _todosLosDias = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];

enum _AccionRecordatorio { editar, eliminar }

({IconData icono, Color color}) _tipoRecordatorio(String tipo) {
  return switch (tipo) {
    'medicamento' => (
      icono: Icons.medication_rounded,
      color: const Color(0xFFF07830),
    ),
    'medicion' => (
      icono: Icons.monitor_heart_outlined,
      color: const Color(0xFF10B981),
    ),
    'cita' => (
      icono: Icons.event_available_rounded,
      color: const Color(0xFF4EC4D4),
    ),
    _ => (icono: Icons.lightbulb_rounded, color: const Color(0xFF8B5CF6)),
  };
}

String _etiquetaTipo(String tipo) => switch (tipo) {
  'medicamento' => 'Medicamento',
  'medicion' => 'Medición',
  'cita' => 'Cita médica',
  _ => 'Recordatorio',
};

String _diaCorto(String dia) => switch (dia) {
  'lun' => 'Lun',
  'mar' => 'Mar',
  'mie' => 'Mié',
  'jue' => 'Jue',
  'vie' => 'Vie',
  'sab' => 'Sáb',
  'dom' => 'Dom',
  _ => dia,
};

class RecordatoriosScreen extends ConsumerStatefulWidget {
  const RecordatoriosScreen({super.key, this.abrirNuevo = false});

  final bool abrirNuevo;

  @override
  ConsumerState<RecordatoriosScreen> createState() =>
      _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends ConsumerState<RecordatoriosScreen> {
  final List<TextEditingController> _controladoresAbiertos = [];
  bool _silenciadas = false;

  @override
  void initState() {
    super.initState();
    _cargarEstadoSilencio();
    if (widget.abrirNuevo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dialogoRecordatorio();
      });
    }
  }

  Future<void> _cargarEstadoSilencio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final silenciadas = prefs.getBool('notificaciones_silenciadas') ?? false;
      if (mounted && silenciadas != _silenciadas) {
        setState(() => _silenciadas = silenciadas);
      }
    } catch (_) {
      // Si falla, se sigue igual.
    }
  }

  @override
  void dispose() {
    for (final controlador in _controladoresAbiertos) {
      controlador.dispose();
    }
    super.dispose();
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
                titulo: 'Recordatorios',
                subtitulo: 'Programa avisos para el cuidado',
                logo: const AssetImage('assets/images/OnCuidar.png'),
                tamanoTitulo: 20,
                reservaDerecha: 64,
                alTocarLogo: () => context.go('/dashboard'),
                accionDerecha: Tooltip(
                  message: _silenciadas
                      ? 'Activar notificaciones'
                      : 'Silenciar notificaciones',
                  child: GestureDetector(
                    key: const Key('campanitaSilencio'),
                    onTap: _alternarSilencio,
                    child: Container(
                      width: 44,
                      height: 44,
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
                        _silenciadas
                            ? Icons.notifications_off
                            : Icons.notifications_active,
                        color: _silenciadas
                            ? Paleta.textoSecundario
                            : Paleta.doradoOscuro,
                        size: 22,
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
    final async = ref.watch(recordatoriosProvider);
    if (async.isLoading && !async.hasValue) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: CircularProgressIndicator(color: Paleta.doradoPrincipal),
        ),
      );
    }
    if (async.hasError) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            'Error al cargar recordatorios.',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Paleta.textoSecundario,
            ),
          ),
        ),
      );
    }
    final recordatorios = async.value ?? const <Recordatorio>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiquetaSeccion('Agregar recordatorio'),
        const SizedBox(height: 6),
        _accesoRapido(),
        const SizedBox(height: 24),
        _etiquetaSeccion('Mis recordatorios'),
        const SizedBox(height: 10),
        if (recordatorios.isEmpty)
          _estadoVacio()
        else
          for (final r in recordatorios)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _tarjetaRecordatorio(r),
            ),
      ],
    );
  }

  Widget _etiquetaSeccion(String texto) {
    return Text(
      texto,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Paleta.textoTerciario,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _estadoVacio() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.alarm_off, size: 48, color: Paleta.textoAyuda),
            const SizedBox(height: 10),
            Text(
              'No tienes recordatorios.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Paleta.textoSecundario,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Usa las tarjetas de arriba para crear uno.',
              style: GoogleFonts.nunito(fontSize: 13, color: Paleta.textoAyuda),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accesoRapido() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _botonAccesoRapido(
          'medicamento',
          _tipoRecordatorio('medicamento').icono,
          'Medicamento',
          colorIcono: _tipoRecordatorio('medicamento').color,
        ),
        _botonAccesoRapido(
          'medicion',
          _tipoRecordatorio('medicion').icono,
          'Medición',
          colorIcono: _tipoRecordatorio('medicion').color,
        ),
        _botonAccesoRapido(
          'cita',
          _tipoRecordatorio('cita').icono,
          'Cita médica',
          colorIcono: _tipoRecordatorio('cita').color,
        ),
        _botonIconoAccesoRapido(
          'otro',
          Icons.add,
          colorIcono: Paleta.doradoPrincipal,
        ),
      ],
    );
  }

  Widget _botonIconoAccesoRapido(
    String tipoInicial,
    IconData icono, {
    required Color colorIcono,
  }) {
    return GestureDetector(
      key: Key('tarjetaRapida_$tipoInicial'),
      onTap: () => _dialogoRecordatorio(tipoInicial: tipoInicial),
      child: Container(
        width: 36,
        height: 35,
        decoration: BoxDecoration(
          color: Paleta.doradoClaro,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.30),
          ),
        ),
        child: Icon(icono, size: 18, color: colorIcono),
      ),
    );
  }

  Widget _botonAccesoRapido(
    String tipoInicial,
    IconData icono,
    String etiqueta, {
    required Color colorIcono,
  }) {
    return GestureDetector(
      key: Key('tarjetaRapida_$tipoInicial'),
      onTap: () => _dialogoRecordatorio(tipoInicial: tipoInicial),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Paleta.tarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 15, color: colorIcono),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Paleta.textoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipDiaTarjeta(String texto, bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: activo ? Paleta.doradoClaro : const Color(0xFFF0EDE8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: activo ? Paleta.doradoOscuro : Paleta.textoSecundario,
        ),
      ),
    );
  }

  Widget _tarjetaRecordatorio(Recordatorio r) {
    final (:icono, :color) = _tipoRecordatorio(r.tipo);
    final dias = r.diasRepeticion.map(_diaCorto).toList();
    final nombrePaciente = r.esParaCuidador
        ? 'Cuidador'
        : ref.read(currentPatientProvider).value?.fullName ?? '';
    return Opacity(
      opacity: _silenciadas ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Paleta.tarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: Paleta.doradoOscuro.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: r.activo ? Paleta.doradoClaro : const Color(0xFFF0EDE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                color: r.activo ? color : const Color(0xFFB0A08A),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.titulo,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: r.activo
                          ? Paleta.textoPrincipal
                          : Paleta.textoSecundario,
                    ),
                  ),
                  if (r.descripcion != null && r.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      r.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Paleta.textoSecundario,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (nombrePaciente.isNotEmpty) ...[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Paleta.doradoClaro,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              nombrePaciente,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Paleta.textoSecundario,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Paleta.textoSecundario,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        r.esRecurrente
                            ? hora12(r.fechaHora)
                            : '${fechacorta(r.fechaHora)} · ${hora12(r.fechaHora)}',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Paleta.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                  if (r.esMensual) ...[
                    const SizedBox(height: 6),
                    _chipDiaTarjeta(
                      'Cada mes el día ${r.fechaHora.day}',
                      r.activo,
                    ),
                  ],
                  if (dias.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    if (dias.length == 7) ...[
                      _chipDiaTarjeta('Toda la semana', r.activo),
                    ] else ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final dia in dias)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _chipDiaTarjeta(dia, r.activo),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            _switcherActivo(r),
            const SizedBox(width: 6),
            _menuRecordatorio(r),
          ],
        ),
      ),
    );
  }

  Widget _menuRecordatorio(Recordatorio r) {
    return PopupMenuButton<_AccionRecordatorio>(
      key: Key('menuRecordatorio_${r.id}'),
      tooltip: 'Opciones del recordatorio',
      onSelected: (accion) {
        switch (accion) {
          case _AccionRecordatorio.editar:
            _dialogoRecordatorio(existente: r);
            break;
          case _AccionRecordatorio.eliminar:
            _eliminar(r);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AccionRecordatorio.editar,
          child: ListTile(
            key: Key('accionEditar_${r.id}'),
            leading: const Icon(
              Icons.edit_outlined,
              color: Paleta.doradoOscuro,
            ),
            title: Text(
              'Editar',
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Paleta.doradoOscuro,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _AccionRecordatorio.eliminar,
          child: ListTile(
            key: Key('accionEliminar_${r.id}'),
            leading: const Icon(Icons.delete_outline, color: Paleta.error),
            title: Text(
              'Eliminar',
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Paleta.error,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
      color: Paleta.tarjeta,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Paleta.doradoClaro.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: Paleta.doradoOscuro,
        ),
      ),
    );
  }

  Widget _switcherActivo(Recordatorio r) {
    return GestureDetector(
      key: Key('switchActivo_${r.id}'),
      onTap: () => _alternarActivo(r),
      child: Container(
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          color: r.activo ? Paleta.doradoPrincipal : const Color(0xFFD8D0C8),
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: r.activo ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _programarAviso(
    ServicioNotificaciones notif,
    String nombrePaciente,
    Recordatorio r,
  ) {
    return notif.programar(
      id: ServicioNotificaciones.idSeguro(r.id),
      titulo: r.tituloAviso(nombrePaciente, _etiquetaTipo(r.tipo)),
      cuerpo: r.cuerpoAviso,
      fechaHora: r.fechaHora,
      diasRepeticion: r.diasRepeticion,
      mensual: r.esMensual,
    );
  }

  Future<void> _alternarActivo(Recordatorio r) async {
    final paciente = ref.read(currentPatientProvider).value;
    if (paciente == null) return;
    final nuevoActivo = !r.activo;
    try {
      await ref
          .read(servicioBaseDatosProvider)
          .actualizarRecordatorio(paciente.id, r.id, activo: nuevoActivo);
      final notif = ref.read(servicioNotificacionesProvider);
      if (nuevoActivo) {
        await notif.solicitarPermiso();
        await _programarAviso(notif, paciente.fullName, r);
      } else {
        await notif.cancelar(ServicioNotificaciones.idSeguro(r.id));
      }
    } catch (_) {
      if (mounted) _snackError('No se pudo actualizar el recordatorio.');
    }
  }

  Future<void> _eliminar(Recordatorio r) async {
    final paciente = ref.read(currentPatientProvider).value;
    if (paciente == null) return;
    final confirmar = await mostrarDialogoConfirmacion(
      context,
      icono: Icons.delete_outline,
      titulo: '¿Eliminar este recordatorio?',
      mensaje: r.titulo,
      textoConfirmar: 'Eliminar',
      colorConfirmar: Paleta.error,
      iconoConfirmar: Icons.delete_forever_outlined,
    );
    if (confirmar != true || !mounted) return;
    try {
      await ref
          .read(servicioBaseDatosProvider)
          .eliminarRecordatorio(paciente.id, r.id);
      await ref
          .read(servicioNotificacionesProvider)
          .cancelar(ServicioNotificaciones.idSeguro(r.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recordatorio eliminado',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Paleta.doradoPrincipal,
          ),
        );
      }
    } catch (_) {
      if (mounted) _snackError('No se pudo eliminar. Intenta de nuevo.');
    }
  }

  void _snackError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Paleta.error),
    );
  }

  Future<void> _alternarSilencio() async {
    final silenciar = !_silenciadas;
    setState(() => _silenciadas = silenciar);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificaciones_silenciadas', silenciar);
    } catch (_) {
      // Si falla, se sigue igual.
    }
    final notif = ref.read(servicioNotificacionesProvider);
    if (silenciar) {
      await notif.cancelarTodas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificaciones silenciadas')),
        );
      }
    } else {
      final base = ref.read(servicioBaseDatosProvider);
      await base.reagendarNotificaciones(notif);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificaciones reactivadas')),
        );
      }
    }
  }

  Future<void> _dialogoRecordatorio({
    String? tipoInicial,
    Recordatorio? existente,
  }) async {
    final esNuevo = existente == null;
    final tituloCtrl = TextEditingController(text: existente?.titulo ?? '');
    final descCtrl = TextEditingController(text: existente?.descripcion ?? '');
    _controladoresAbiertos.add(tituloCtrl);
    _controladoresAbiertos.add(descCtrl);
    var tipo = existente?.tipo ?? tipoInicial ?? 'medicamento';
    var hora = TimeOfDay(
      hour: existente?.fechaHora.hour ?? 9,
      minute: existente?.fechaHora.minute ?? 0,
    );
    final dias = List<String>.from(existente?.diasRepeticion ?? _todosLosDias);
    var modoRepeticion = existente?.recurrencia == 'mensual'
        ? 'mensual'
        : (dias.isEmpty ? 'unavez' : 'semanal');
    var asignadoA = existente?.asignadoA ?? Recordatorio.asignadoAPaciente;
    final ahoraDialogo = DateTime.now();
    final hoyDia = DateTime(
      ahoraDialogo.year,
      ahoraDialogo.month,
      ahoraDialogo.day,
    );
    var fecha = existente == null
        ? hoyDia
        : DateTime(
            existente.fechaHora.year,
            existente.fechaHora.month,
            existente.fechaHora.day,
          );

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Paleta.tarjeta,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esNuevo ? 'Nuevo recordatorio' : 'Editar recordatorio',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Paleta.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final opcion in const [
                      ('medicamento', 'Medicamento'),
                      ('medicion', 'Medición'),
                      ('cita', 'Cita médica'),
                      ('otro', 'Otro'),
                    ])
                      _chipTipo(
                        opcion.$1,
                        opcion.$2,
                        activo: tipo == opcion.$1,
                        alPulsar: () => setDialogState(() => tipo = opcion.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('campoTituloRecordatorio'),
                  controller: tituloCtrl,
                  maxLines: 1,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Paleta.textoPrincipal,
                  ),
                  decoration: entradaDorada(
                    hintText: 'Título del recordatorio',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Paleta.textoAyuda,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('campoDescripcionRecordatorio'),
                  controller: descCtrl,
                  minLines: 1,
                  maxLines: 2,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Paleta.textoPrincipal,
                  ),
                  decoration: entradaDorada(
                    hintText: 'Descripción (opcional)',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Paleta.textoAyuda,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _etiquetaSeccion('Dirigido a'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipModoRepeticion(
                      Recordatorio.asignadoAPaciente,
                      'Paciente',
                      asignadoA == Recordatorio.asignadoAPaciente,
                      () => setDialogState(
                        () => asignadoA = Recordatorio.asignadoAPaciente,
                      ),
                      clave: const Key('asignado_paciente'),
                    ),
                    _chipModoRepeticion(
                      Recordatorio.asignadoACuidador,
                      'Cuidador',
                      asignadoA == Recordatorio.asignadoACuidador,
                      () => setDialogState(
                        () => asignadoA = Recordatorio.asignadoACuidador,
                      ),
                      clave: const Key('asignado_cuidador'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _etiquetaSeccion('Hora'),
                const SizedBox(height: 6),
                _selectorHora(ctx, hora, (h) => setDialogState(() => hora = h)),
                const SizedBox(height: 14),
                _etiquetaSeccion('Repetición'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipModoRepeticion(
                      'unavez',
                      'Una vez',
                      modoRepeticion == 'unavez',
                      () => setDialogState(() {
                        modoRepeticion = 'unavez';
                        if (fecha.isBefore(hoyDia)) fecha = hoyDia;
                      }),
                    ),
                    _chipModoRepeticion(
                      'semanal',
                      'Cada semana',
                      modoRepeticion == 'semanal',
                      () => setDialogState(() => modoRepeticion = 'semanal'),
                    ),
                    _chipModoRepeticion(
                      'mensual',
                      'Cada mes',
                      modoRepeticion == 'mensual',
                      () => setDialogState(() => modoRepeticion = 'mensual'),
                    ),
                  ],
                ),
                if (modoRepeticion == 'semanal') ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final dia in _todosLosDias)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _chipDia(dia, dias.contains(dia), () {
                              setDialogState(() {
                                if (dias.contains(dia)) {
                                  dias.remove(dia);
                                } else {
                                  dias.add(dia);
                                }
                              });
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
                if (modoRepeticion != 'semanal') ...[
                  const SizedBox(height: 12),
                  _etiquetaSeccion(
                    modoRepeticion == 'mensual' ? 'Día del mes' : 'Fecha',
                  ),
                  const SizedBox(height: 6),
                  _selectorFecha(
                    ctx,
                    fecha,
                    hoyDia,
                    (f) => setDialogState(() => fecha = f),
                  ),
                ],
                if (modoRepeticion == 'mensual') ...[
                  const SizedBox(height: 10),
                  Text(
                    'Se recordará cada mes el día ${fecha.day} a la hora indicada.',
                    key: const Key('textoDiaMensual'),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Paleta.textoSecundario,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _botonDialogoAccion(
                        key: const Key('cancelarRecordatorio'),
                        etiqueta: 'Cancelar',
                        icono: Icons.close_rounded,
                        colorFondo: Paleta.doradoClaro,
                        colorTexto: Paleta.textoSecundario,
                        alPulsar: () => Navigator.pop(ctx, false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _botonDialogoAccion(
                        key: const Key('confirmarRecordatorio'),
                        etiqueta: esNuevo ? 'Guardar' : 'Actualizar',
                        icono: esNuevo
                            ? Icons.check_rounded
                            : Icons.save_rounded,
                        gradiente: const [
                          Paleta.doradoMedio,
                          Paleta.doradoOscuro,
                        ],
                        colorTexto: Colors.white,
                        alPulsar: () {
                          if (tituloCtrl.text.trim().isNotEmpty) {
                            Navigator.pop(ctx, true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (guardado != true) return;

    final paciente = ref.read(currentPatientProvider).value;
    if (paciente == null) return;

    final fechaHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
    final base = ref.read(servicioBaseDatosProvider);
    final notif = ref.read(servicioNotificacionesProvider);
    final mensual = modoRepeticion == 'mensual';
    final diasGuardar = mensual || modoRepeticion == 'unavez'
        ? const <String>[]
        : List<String>.from(dias);
    final titulo = tituloCtrl.text.trim();
    final descripcion = descCtrl.text.trim().isEmpty
        ? null
        : descCtrl.text.trim();

    try {
      if (esNuevo) {
        final r = Recordatorio(
          id: '',
          pacienteId: paciente.id,
          tipo: tipo,
          titulo: titulo,
          descripcion: descripcion,
          fechaHora: fechaHora,
          diasRepeticion: diasGuardar,
          recurrencia: mensual ? 'mensual' : null,
          asignadoA: asignadoA,
          activo: true,
          creadoEn: DateTime.now(),
        );
        final docId = await base.agregarRecordatorio(paciente.id, r);
        await notif.solicitarPermiso();
        await _programarAviso(
          notif,
          paciente.fullName,
          Recordatorio(
            id: docId,
            pacienteId: r.pacienteId,
            tipo: r.tipo,
            titulo: r.titulo,
            descripcion: r.descripcion,
            fechaHora: r.fechaHora,
            diasRepeticion: r.diasRepeticion,
            recurrencia: r.recurrencia,
            asignadoA: r.asignadoA,
            creadoEn: r.creadoEn,
          ),
        );
      } else {
        await base.actualizarRecordatorio(
          paciente.id,
          existente.id,
          tipo: tipo,
          titulo: titulo,
          descripcion: descCtrl.text.trim(),
          fechaHora: fechaHora,
          diasRepeticion: diasGuardar,
          recurrencia: mensual ? 'mensual' : '',
          asignadoA: asignadoA,
        );
        final actualizado = Recordatorio(
          id: existente.id,
          pacienteId: paciente.id,
          tipo: tipo,
          titulo: titulo,
          descripcion: descripcion,
          fechaHora: fechaHora,
          diasRepeticion: diasGuardar,
          recurrencia: mensual ? 'mensual' : null,
          asignadoA: asignadoA,
          creadoEn: existente.creadoEn,
        );
        await notif.cancelar(ServicioNotificaciones.idSeguro(existente.id));
        if (existente.activo) {
          await _programarAviso(notif, paciente.fullName, actualizado);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esNuevo ? 'Recordatorio agregado' : 'Recordatorio actualizado',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Paleta.doradoPrincipal,
          ),
        );
      }
    } on ClaveNoDisponibleSinConexion catch (e) {
      if (mounted) _snackError(e.toString());
    } catch (_) {
      if (mounted) _snackError('No se pudo guardar el recordatorio.');
    }
  }

  Widget _chipModoRepeticion(
    String modo,
    String etiqueta,
    bool activo,
    VoidCallback alPulsar, {
    Key? clave,
  }) {
    return GestureDetector(
      key: clave ?? Key('modoRepeticion_$modo'),
      onTap: alPulsar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Paleta.doradoPrincipal : Paleta.doradoClaro,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activo ? Paleta.doradoOscuro : Paleta.doradoClaro,
            width: 1,
          ),
        ),
        child: Text(
          etiqueta,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: activo ? Colors.white : Paleta.doradoOscuro,
          ),
        ),
      ),
    );
  }

  Widget _chipDia(String dia, bool seleccionado, VoidCallback alPulsar) {
    return GestureDetector(
      onTap: alPulsar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: seleccionado
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Paleta.doradoMedio, Paleta.doradoOscuro],
                )
              : null,
          color: seleccionado ? null : Paleta.tarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? Colors.transparent : Paleta.doradoClaro,
          ),
        ),
        child: Text(
          _diaCorto(dia),
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: seleccionado ? Colors.white : Paleta.doradoOscuro,
          ),
        ),
      ),
    );
  }

  Widget _selectorHora(
    BuildContext ctx,
    TimeOfDay hora,
    ValueChanged<TimeOfDay> alElegir,
  ) {
    return GestureDetector(
      key: const Key('campoHoraRecordatorio'),
      onTap: () => _abrirSelectorHora(ctx, hora, alElegir),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Paleta.fondoEntrada,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 18,
              color: Paleta.textoSecundario,
            ),
            const SizedBox(width: 10),
            Text(
              MaterialLocalizations.of(ctx).formatTimeOfDay(hora),
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Paleta.textoPrincipal,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Paleta.textoSecundario,
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorFecha(
    BuildContext ctx,
    DateTime fecha,
    DateTime hoy,
    ValueChanged<DateTime> alElegir,
  ) {
    return GestureDetector(
      key: const Key('campoFechaRecordatorio'),
      onTap: () async {
        final elegida = await showDatePicker(
          context: ctx,
          initialDate: fecha,
          firstDate: fecha.isBefore(hoy) ? fecha : hoy,
          lastDate: DateTime(hoy.year + 5, hoy.month, hoy.day),
        );
        if (elegida != null) alElegir(elegida);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Paleta.fondoEntrada,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_rounded,
              size: 18,
              color: Paleta.textoSecundario,
            ),
            const SizedBox(width: 10),
            Text(
              fechalarga(fecha),
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Paleta.textoPrincipal,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Paleta.textoSecundario,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipTipo(
    String valor,
    String etiqueta, {
    required bool activo,
    required VoidCallback alPulsar,
  }) {
    final (:icono, :color) = _tipoRecordatorio(valor);
    return GestureDetector(
      onTap: alPulsar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Paleta.doradoPrincipal : Paleta.tarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activo ? Paleta.doradoPrincipal : Paleta.doradoPrincipal,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: activo
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icono,
                size: 15,
                color: activo ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              etiqueta,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: activo ? Colors.white : Paleta.textoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirSelectorHora(
    BuildContext ctx,
    TimeOfDay actual,
    ValueChanged<TimeOfDay> alElegir,
  ) async {
    final hora = await showTimePicker(
      context: ctx,
      initialTime: actual,
      builder: (pickerContext, child) {
        final usar24h = MediaQuery.of(ctx).alwaysUse24HourFormat;
        return MediaQuery(
          data: MediaQuery.of(
            pickerContext,
          ).copyWith(alwaysUse24HourFormat: usar24h),
          child: child!,
        );
      },
    );
    if (hora != null) alElegir(hora);
  }

  Widget _botonDialogoAccion({
    required Key key,
    required String etiqueta,
    required IconData icono,
    required VoidCallback alPulsar,
    required Color colorTexto,
    Color? colorFondo,
    List<Color>? gradiente,
  }) {
    return GestureDetector(
      key: key,
      onTap: alPulsar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: colorFondo,
          gradient: gradiente != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradiente,
                )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 17, color: colorTexto),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
