import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/app/enrutador/destino_aviso.dart';
import 'package:oncuidar/app/enrutador/enrutador.dart';
import 'package:oncuidar/app/tema/fundido_de_tema.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/app/tema/repintar.dart';
import 'package:oncuidar/app/tema/tema.dart';
import 'package:oncuidar/caracteristicas/configuracion/presentacion/proveedores_configuracion.dart';
import 'package:oncuidar/nucleo/almacen/almacen_secreto_seguro.dart';
import 'package:oncuidar/nucleo/proveedores.dart';
import 'package:oncuidar/nucleo/red/cliente_api.dart';
import 'package:oncuidar/nucleo/red/config_api.dart';
import 'package:oncuidar/nucleo/sesion/servicio_sesion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final ServicioSesion sesion;
  final api = ClienteApi(
    urlBase: ConfigApi.urlBase,
    obtenerToken: () => sesion.token,
  );
  sesion = ServicioSesion(api: api, almacen: const AlmacenSecretoSeguro());
  await sesion.inicializar();
  runApp(
    ProviderScope(
      overrides: [
        clienteApiProvider.overrideWithValue(api),
        servicioSesionProvider.overrideWithValue(sesion),
      ],
      child: const OncuidarApp(),
    ),
  );
}

class OncuidarApp extends ConsumerStatefulWidget {
  const OncuidarApp({super.key});

  @override
  ConsumerState<OncuidarApp> createState() => _OncuidarAppState();
}

class _OncuidarAppState extends ConsumerState<OncuidarApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _escucharAvisos();
    var sesionPrevia = false;
    ref.read(servicioSesionProvider).cambios.listen((usuario) {
      if (usuario == null) {
        if (!sesionPrevia) return;
        EstadoArranque.reiniciar();
        ref.read(servicioCifradoProvider).bloquear();
        ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(false);
        const publicas = {
          '/',
          '/bienvenida',
          '/iniciar-sesion',
          '/crear-cuenta',
          '/recuperar-acceso',
        };
        if (!publicas.contains(router.state.uri.path)) router.go('/bienvenida');
      } else {
        sesionPrevia = true;
        unawaited(ref.read(orquestadorSincronizacionProvider).drenar());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) setState(() {});
  }

  void _aplicarPaleta() {
    final brilloSistema =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final oscuro = ref.watch(modoTemaProvider).esOscuro(brilloSistema);
    if (Paleta.usar(oscuro ? coloresOscuros : coloresClaros)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _repintarTodo());
    }
  }

  void _repintarTodo() {
    if (mounted) repintarArbol(context);
  }

  void _escucharAvisos() {
    final avisos = ref.read(servicioNotificacionesProvider);
    avisos.alTocar = (payload) => abrirDesdeNotificacion(
      payload,
      router.go,
      haySesion: ref.read(servicioSesionProvider).actual != null,
    );
    unawaited(
      avisos
          .consumirPayloadLanzamiento()
          .then(registrarLanzamientoPorNotificacion)
          .catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(estadoAutenticacionProvider).value;
    final desbloqueado = ref.watch(bloqueoCifradoProvider);
    final escalaTexto = ref.watch(escalaTextoProvider).factor;
    _aplicarPaleta();
    if (usuario != null) ref.watch(orquestadorSincronizacionProvider);
    return MaterialApp.router(
      title: 'Oncuidar',
      debugShowCheckedModeBanner: false,
      theme: Tema.obtener(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(context).scale(1) * escalaTexto,
          ),
        ),
        child: Stack(
          children: [
            FundidoDeTema(
              oscuro: Paleta.esOscura,
              child: child ?? const SizedBox.shrink(),
            ),
            if (usuario != null && !desbloqueado)
              const Positioned.fill(child: _GateClave()),
          ],
        ),
      ),
    );
  }
}

class _GateClave extends ConsumerStatefulWidget {
  const _GateClave();

  @override
  ConsumerState<_GateClave> createState() => _GateClaveState();
}

class _GateClaveState extends ConsumerState<_GateClave> {
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restaurar();
  }

  Future<void> _restaurar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final uid = ref.read(servicioSesionProvider).actual!.uid;
      await ref.read(servicioCifradoProvider).asegurarClave(uid);
      ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true);
    } catch (e, pila) {
      debugPrint('Error restaurando clave: $e\n$pila');
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = _mensajeRestauracion(e);
        });
      }
    }
  }

  String _mensajeRestauracion(Object e) {
    if (e is ExcepcionApi) {
      if (e.esDeRed) {
        return 'No pudimos conectar con el servidor seguro.\n'
            'Revisa tu conexión a internet y vuelve a intentarlo.';
      }
      if (e.codigoHttp == 401) {
        return 'Tu sesión expiró. Inicia sesión nuevamente.';
      }
      if (e.codigoHttp >= 500) {
        return 'Hubo un error interno al restaurar tus datos.\n'
            'Reintenta; si persiste, avísanos con el código del error.';
      }
      return 'No se pudieron restaurar tus datos.\n'
          '(${e.codigoHttp})';
    }
    if (e is FormatException) {
      return 'Tus datos locales están dañados.\n'
          'Se generará una copia nueva; reintenta para continuar.';
    }
    return 'No se pudieron restaurar tus datos.\n'
        'Reintenta y, si persiste, avísanos.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _cargando
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 56,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error ?? 'Restauracion pendiente',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _restaurar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(servicioSesionProvider).cerrarSesion(),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
