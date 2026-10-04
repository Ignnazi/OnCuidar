import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/controlador_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/formato_recordatorio.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/proveedores_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/widgets/acceso_rapido_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/widgets/dialogo_recordatorio.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/widgets/tarjeta_recordatorio.dart';
import 'package:oncuidar/compartido/widgets/buscador.dart';
import 'package:oncuidar/compartido/widgets/dialogo_confirmacion.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';
import 'package:oncuidar/nucleo/cifrado/servicio_cifrado.dart';

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
    final silenciadas = await ControladorRecordatorios.silencioGuardado();
    if (mounted && silenciadas != _silenciadas) {
      setState(() => _silenciadas = silenciadas);
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
    return PantallaConEncabezado(
      alRegresar: _regresar,
      encabezado: EncabezadoGradiente(
        titulo: 'Recordatorios',
        subtitulo: 'Programa avisos para el cuidado',
        logo: const AssetImage('assets/images/OnCuidar.png'),
        tamanoTitulo: 20,
        alTocarLogo: () => context.go('/dashboard'),
        accionDerecha: BotonCircular(
          clave: const Key('campanitaSilencio'),
          tooltip: _silenciadas
              ? 'Activar notificaciones'
              : 'Silenciar notificaciones',
          alTocar: _alternarSilencio,
          hijo: Icon(
            _silenciadas ? Icons.notifications_off : Icons.notifications_active,
            color: _silenciadas ? Paleta.textoSecundario : Paleta.doradoOscuro,
            size: 22,
          ),
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
    final async = ref.watch(recordatoriosProvider);
    if (async.isLoading && !async.hasValue) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
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
        const EtiquetaSeccionRecordatorio('Agregar recordatorio'),
        const SizedBox(height: 6),
        AccesoRapidoRecordatorios(
          alElegirTipo: (tipo) => _dialogoRecordatorio(tipoInicial: tipo),
        ),
        const SizedBox(height: 24),
        const EtiquetaSeccionRecordatorio('Mis recordatorios'),
        const SizedBox(height: 10),
        if (recordatorios.isEmpty)
          const _EstadoVacio()
        else
          for (final r in recordatorios)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TarjetaRecordatorio(
                recordatorio: r,
                nombrePaciente: r.esParaCuidador
                    ? 'Cuidador'
                    : ref.read(pacienteActivoProvider).value?.nombreCompleto ??
                          '',
                silenciadas: _silenciadas,
                alAlternarActivo: () => _alternarActivo(r),
                alEditar: () => _dialogoRecordatorio(existente: r),
                alEliminar: () => _eliminar(r),
              ),
            ),
      ],
    );
  }

  ControladorRecordatorios get _controlador =>
      ref.read(controladorRecordatoriosProvider);

  Future<void> _alternarActivo(Recordatorio r) async {
    final paciente = ref.read(pacienteActivoProvider).value;
    if (paciente == null) return;
    try {
      await _controlador.alternarActivo(paciente, r);
    } catch (_) {
      if (mounted) _snackError('No se pudo actualizar el recordatorio.');
    }
  }

  Future<void> _eliminar(Recordatorio r) async {
    final paciente = ref.read(pacienteActivoProvider).value;
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
      await _controlador.eliminar(paciente.id, r.id);
      if (mounted) _snackExito('Recordatorio eliminado');
    } catch (_) {
      if (mounted) _snackError('No se pudo eliminar. Intenta de nuevo.');
    }
  }

  void _snackExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        backgroundColor: Paleta.doradoPrincipal,
      ),
    );
  }

  void _snackError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Paleta.error),
    );
  }

  Future<void> _alternarSilencio() async {
    final silenciar = !_silenciadas;
    setState(() => _silenciadas = silenciar);
    await _controlador.fijarSilencio(silenciar);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            silenciar
                ? 'Notificaciones silenciadas'
                : 'Notificaciones reactivadas',
          ),
        ),
      );
    }
  }

  Future<void> _dialogoRecordatorio({
    String? tipoInicial,
    Recordatorio? existente,
  }) async {
    final tituloCtrl = TextEditingController(text: existente?.titulo ?? '');
    final descCtrl = TextEditingController(text: existente?.descripcion ?? '');
    _controladoresAbiertos.add(tituloCtrl);
    _controladoresAbiertos.add(descCtrl);
    final datos = await mostrarDialogoRecordatorio(
      context,
      tituloCtrl: tituloCtrl,
      descCtrl: descCtrl,
      tipoInicial: tipoInicial,
      existente: existente,
    );
    if (datos == null) return;

    final paciente = ref.read(pacienteActivoProvider).value;
    if (paciente == null) return;

    try {
      await _controlador.guardar(paciente, datos, existente: existente);
      if (mounted) {
        _snackExito(
          existente == null
              ? 'Recordatorio agregado'
              : 'Recordatorio actualizado',
        );
      }
    } on ClaveNoDisponibleSinConexion catch (e) {
      if (mounted) _snackError(e.toString());
    } catch (_) {
      if (mounted) _snackError('No se pudo guardar el recordatorio.');
    }
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.alarm_off, size: 48, color: Paleta.textoAyuda),
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
}
