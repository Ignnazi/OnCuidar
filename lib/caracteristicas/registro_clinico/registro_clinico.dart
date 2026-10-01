import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/catalogos/catalogo_sintomas.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/servicios/motor_reglas_clinicas.dart';
import '../../core/servicios/rangos_signos.dart';
import '../../core/servicios/servicio_cifrado.dart';
import '../../core/tema/paleta.dart';
import '../../core/util/formato_fecha.dart';
import '../../modelos/paciente.dart';
import '../../modelos/registro_clinico.dart';
import 'widgets/boton_guardar.dart';
import 'widgets/cabecera_registro.dart';
import 'widgets/campo_observaciones.dart';
import 'widgets/dialogo_tope.dart';
import 'widgets/indicador_alerta.dart';
import 'widgets/seccion_signos_vitales.dart';
import 'widgets/seccion_sintomas.dart';
import 'widgets/seccion_tipo_registro.dart';
import 'widgets/titulo_seccion.dart';

class RegistroClinicoScreen extends ConsumerStatefulWidget {
  const RegistroClinicoScreen({super.key, this.registroInicial});

  final RegistroClinico? registroInicial;

  @override
  ConsumerState<RegistroClinicoScreen> createState() =>
      _RegistroClinicoScreenState();
}

class _RegistroClinicoScreenState extends ConsumerState<RegistroClinicoScreen> {
  final Map<String, SintomaSeleccionable> _catalogoUnificadoPorNombre = {
    for (final item in catalogoUnificado) item.nombre: item,
  };

  final _tempController = TextEditingController();
  final _frecCardiacaController = TextEditingController();
  final _o2Controller = TextEditingController();
  final _frecRespiratoriaController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _otroProblemaController = TextEditingController();

  late final List<TextEditingController> _controladoresSignos = [
    _tempController,
    _frecCardiacaController,
    _o2Controller,
    _frecRespiratoriaController,
  ];

  String _tipoRegistro = 'programado';
  final List<EntradaSintoma> _sintomas = [];
  final LinkedHashSet<String> _seleccionados = LinkedHashSet<String>();
  final Map<String, int> _intensidades = {};
  final Map<String, String> _otroTexto = {};
  RegistroClinico? _registroEdicion;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    for (final controlador in _controladoresSignos) {
      controlador.addListener(_recalcularAlerta);
    }
    final registroInicial =
        widget.registroInicial ?? ref.read(registroEnEdicionProvider);
    ref.read(registroEnEdicionProvider.notifier).state = null;
    if (registroInicial != null) {
      _registroEdicion = registroInicial;
      _tipoRegistro = registroInicial.tipoRegistro;
      final signos = registroInicial.signosVitales;
      if (signos != null) {
        if (signos.temperature != null) {
          _tempController.text = signos.temperature!.toStringAsFixed(1);
        }
        if (signos.heartRate != null) {
          _frecCardiacaController.text = signos.heartRate.toString();
        }
        if (signos.oxygenSaturation != null) {
          _o2Controller.text = signos.oxygenSaturation.toString();
        }
        if (signos.respiratoryRate != null) {
          _frecRespiratoriaController.text = signos.respiratoryRate.toString();
        }
      }
      if (registroInicial.observaciones != null) {
        _observacionesController.text = registroInicial.observaciones!;
      }
      _sintomas.addAll(registroInicial.sintomas);
      for (final sintoma in registroInicial.sintomas) {
        _seleccionados.add(sintoma.name);
        _intensidades[sintoma.name] = sintoma.intensity;
        if (sintoma.name == 'Otro problema') {
          final notas = sintoma.notes;
          if (notas != null && notas.isNotEmpty) {
            _otroProblemaController.text = notas;
            _otroTexto['Otro problema'] = notas;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controlador in _controladoresSignos) {
      controlador.dispose();
    }
    _observacionesController.dispose();
    _otroProblemaController.dispose();
    super.dispose();
  }

  void _recalcularAlerta() {
    if (mounted) setState(() {});
  }

  SignosVitales? _signosActuales() {
    final temperatura = double.tryParse(_tempController.text.trim());
    final frecuenciaCardiaca = int.tryParse(
      _frecCardiacaController.text.trim(),
    );
    final o2 = int.tryParse(_o2Controller.text.trim());
    final frecuenciaRespiratoria = int.tryParse(
      _frecRespiratoriaController.text.trim(),
    );
    if (temperatura == null &&
        frecuenciaCardiaca == null &&
        o2 == null &&
        frecuenciaRespiratoria == null) {
      return null;
    }
    return SignosVitales(
      temperature: temperatura,
      heartRate: frecuenciaCardiaca,
      oxygenSaturation: o2,
      respiratoryRate: frecuenciaRespiratoria,
    );
  }

  EvaluacionAlerta _evaluarAlerta() =>
      MotorReglasClinicas.evaluar(_signosActuales(), _sintomas);

  int _registrosHoy(List<RegistroClinico> registros) {
    final ahora = DateTime.now();
    var contador = 0;
    for (final r in registros) {
      if (r.tipoRegistro == 'programado' && mismoDia(r.fecha, ahora)) {
        contador++;
      }
    }
    return contador;
  }

  String _tipoEfectivo(int registrosHoy, int tope) {
    if (_tipoRegistro == 'programado' && registrosHoy >= tope) {
      return 'extra';
    }
    return _tipoRegistro;
  }

  void _fijarIntensidad(String nombre, int valor) {
    setState(() {
      _intensidades[nombre] = valor;
      _upsertEnSintomas(nombre, valor);
    });
  }

  void _alternarSeleccion(String nombre) {
    setState(() {
      if (_seleccionados.contains(nombre)) {
        _seleccionados.remove(nombre);
        _intensidades.remove(nombre);
        _sintomas.removeWhere((s) => s.name == nombre);
        if (nombre == 'Otro problema') {
          _otroProblemaController.clear();
          _otroTexto.remove(nombre);
        }
      } else {
        _seleccionados.add(nombre);
        _intensidades[nombre] = 0;
        if (nombre == 'Otro problema') {
          _otroTexto[nombre] = '';
          _sincronizarOtroProblema();
        } else {
          _upsertEnSintomas(nombre, 0);
        }
      }
    });
  }

  void _upsertEnSintomas(String nombre, int valor) {
    final entrada = EntradaSintoma(name: nombre, intensity: valor);
    final indice = _sintomas.indexWhere((s) => s.name == nombre);
    if (indice != -1) {
      _sintomas[indice] = entrada;
    } else {
      _sintomas.add(entrada);
    }
  }

  void _sincronizarOtroProblema() {
    final texto = _otroProblemaController.text.trim();
    final intensidad = _intensidades['Otro problema'] ?? 0;
    if (_seleccionados.contains('Otro problema') && texto.isNotEmpty) {
      _otroTexto['Otro problema'] = texto;
      final entrada = EntradaSintoma(
        name: 'Otro problema',
        intensity: intensidad,
        notes: texto,
      );
      final indice = _sintomas.indexWhere((s) => s.name == 'Otro problema');
      if (indice != -1) {
        _sintomas[indice] = entrada;
      } else {
        _sintomas.add(entrada);
      }
    } else {
      _otroTexto.remove('Otro problema');
      _sintomas.removeWhere((s) => s.name == 'Otro problema');
    }
  }

  Future<void> _configurarTope(Paciente paciente) async {
    final valor = await mostrarDialogoTope(
      context,
      valorInicial: paciente.maximoRegistrosDia,
    );
    if (valor == null || !mounted) return;
    await ref.read(servicioBaseDatosProvider).actualizarPaciente(paciente.id, {
      'maximo_registros_dia': valor,
    });
    if (mounted) {
      _mostrarSnack(
        'Tope actualizado a $valor',
        color: Paleta.doradoPrincipal,
        icono: Icons.check,
      );
    }
  }

  String? _errorRango() {
    final temperatura = double.tryParse(_tempController.text.trim());
    if (temperatura != null &&
        (temperatura > rangoTemperatura.max ||
            temperatura < rangoTemperatura.min)) {
      return rangoTemperatura.mensaje;
    }
    final frecuenciaCardiaca = int.tryParse(
      _frecCardiacaController.text.trim(),
    );
    if (frecuenciaCardiaca != null &&
        (frecuenciaCardiaca > rangoFrecuenciaCardiaca.max ||
            frecuenciaCardiaca < rangoFrecuenciaCardiaca.min)) {
      return rangoFrecuenciaCardiaca.mensaje;
    }
    final o2 = int.tryParse(_o2Controller.text.trim());
    if (o2 != null && (o2 > rangoSaturacion.max || o2 < rangoSaturacion.min)) {
      return rangoSaturacion.mensaje;
    }
    final frecuenciaRespiratoria = int.tryParse(
      _frecRespiratoriaController.text.trim(),
    );
    if (frecuenciaRespiratoria != null &&
        (frecuenciaRespiratoria > rangoFrecuenciaRespiratoria.max ||
            frecuenciaRespiratoria < rangoFrecuenciaRespiratoria.min)) {
      return rangoFrecuenciaRespiratoria.mensaje;
    }
    return null;
  }

  Future<void> _guardar() async {
    final paciente = ref.read(currentPatientProvider).value;
    if (paciente == null) {
      _mostrarSnack(
        'No hay paciente seleccionado',
        color: Paleta.error,
        icono: Icons.error_outline,
      );
      return;
    }
    final errorRango = _errorRango();
    if (errorRango != null) {
      _mostrarSnack(
        errorRango,
        color: Paleta.error,
        icono: Icons.error_outline,
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final esEdicion = _registroEdicion != null;
    final registros =
        ref.read(registrosClinicosProvider).value ?? const <RegistroClinico>[];
    final tope = paciente.maximoRegistrosDia;
    _sincronizarOtroProblema();
    final alerta = _evaluarAlerta();
    final ahora = DateTime.now();
    final registro = RegistroClinico(
      id: _registroEdicion?.id ?? const Uuid().v4(),
      pacienteId: paciente.id,
      fecha: _registroEdicion?.fecha ?? ahora,
      creadoEn: _registroEdicion?.creadoEn ?? ahora,
      tipoRegistro: _registroEdicion != null
          ? _registroEdicion!.tipoRegistro
          : _tipoEfectivo(_registrosHoy(registros), tope),
      signosVitales: _signosActuales(),
      sintomas: List.of(_sintomas),
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
      nivelAlerta: alerta.nivel,
      mensajeAlerta: alerta.mensajes.isEmpty ? null : alerta.mensajes.join(' '),
    );
    if (_guardando) return;
    setState(() => _guardando = true);
    try {
      final base = ref.read(servicioBaseDatosProvider);
      try {
        await base.guardarRegistroClinico(paciente.id, registro);
      } on ClaveNoDisponibleSinConexion catch (e) {
        _mostrarSnack(
          e.toString(),
          color: Paleta.error,
          icono: Icons.lock_outline,
        );
        return;
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: Paleta.error,
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No se pudo guardar. Tu registro sigue en el formulario.',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }
      final enLinea = ref.read(estadoConexionProvider).value ?? true;
      _snackCon(
        messenger,
        enLinea
            ? (esEdicion ? 'Registro actualizado' : 'Guardado correctamente')
            : 'Guardado en este dispositivo. Se enviará al recuperar la red.',
        color: Paleta.doradoPrincipal,
        icono: Icons.check_circle,
      );
      _reiniciarFormulario();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _reiniciarFormulario() {
    setState(() {
      _tempController.clear();
      _frecCardiacaController.clear();
      _o2Controller.clear();
      _frecRespiratoriaController.clear();
      _observacionesController.clear();
      _otroProblemaController.clear();
      _sintomas.clear();
      _seleccionados.clear();
      _intensidades.clear();
      _otroTexto.clear();
      _registroEdicion = null;
      _tipoRegistro = 'programado';
    });
    FocusScope.of(context).unfocus();
  }

  void _alRetroceder() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/dashboard');
    }
  }

  void _mostrarSnack(String texto, {required Color color, IconData? icono}) {
    if (!mounted) return;
    _snackCon(ScaffoldMessenger.of(context), texto, color: color, icono: icono);
  }

  void _snackCon(
    ScaffoldMessengerState messenger,
    String texto, {
    required Color color,
    IconData? icono,
  }) {
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: color,
        content: Row(
          children: [
            if (icono != null) ...[
              Icon(icono, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                texto,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paciente = ref.watch(currentPatientProvider).value;
    final registros =
        ref.watch(registrosClinicosProvider).value ?? const <RegistroClinico>[];
    final tope = paciente?.maximoRegistrosDia ?? 3;
    final registrosHoy = _registrosHoy(registros);
    final alTope = registrosHoy >= tope;
    final tipoEfectivo = _tipoEfectivo(registrosHoy, tope);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _alRetroceder();
      },
      child: Scaffold(
        backgroundColor: Paleta.crema,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 100 + 20,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_registroEdicion == null)
                      SeccionTipoRegistro(
                        paciente: paciente,
                        registrosHoy: registrosHoy,
                        tope: tope,
                        alTope: alTope,
                        tipoEfectivo: tipoEfectivo,
                        onTipoRegistro: (t) =>
                            setState(() => _tipoRegistro = t),
                        onConfigurarTope: () {
                          if (paciente != null) {
                            _configurarTope(paciente);
                          }
                        },
                      ),
                    const SizedBox(height: 20),
                    SeccionSignosVitales(controladores: _controladoresSignos),
                    const SizedBox(height: 20),
                    SeccionSintomas(
                      seleccionados: _seleccionados,
                      catalogoPorNombre: _catalogoUnificadoPorNombre,
                      intensidades: _intensidades,
                      otroController: _otroProblemaController,
                      onAlternar: _alternarSeleccion,
                      onIntensidad: (n, v) {
                        setState(() {
                          if (n == 'Otro problema') {
                            _intensidades['Otro problema'] = v;
                            _sincronizarOtroProblema();
                          } else {
                            _fijarIntensidad(n, v);
                          }
                        });
                      },
                      onCambioOtro: () =>
                          setState(() => _sincronizarOtroProblema()),
                    ),
                    const SizedBox(height: 20),
                    _seccionObservaciones(),
                    const SizedBox(height: 20),
                    IndicadorAlerta(alerta: _evaluarAlerta()),
                    const SizedBox(height: 16),
                    BotonGuardar(
                      guardando: _guardando,
                      esEdicion: _registroEdicion != null,
                      onPressed: _guardar,
                    ),
                  ],
                ),
              ),
            ),
            CabeceraRegistro(
              esEdicion: _registroEdicion != null,
              onVerHistorial: _registroEdicion == null
                  ? () => context.push('/historial')
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionObservaciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSeccion('Observaciones', icono: Icons.edit_note_rounded),
        const SizedBox(height: 12),
        CampoObservaciones(controlador: _observacionesController),
      ],
    );
  }
}
