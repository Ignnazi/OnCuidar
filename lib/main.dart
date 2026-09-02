import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/proveedores/proveedores.dart';
import 'core/router/app_router.dart';
import 'core/tema/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: FirebaseOpciones.actual);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const ProviderScope(child: OncuidarApp()));
}

class OncuidarApp extends ConsumerStatefulWidget {
  const OncuidarApp({super.key});

  @override
  ConsumerState<OncuidarApp> createState() => _OncuidarAppState();
}

class _OncuidarAppState extends ConsumerState<OncuidarApp> {
  @override
  void initState() {
    super.initState();
    ref.read(firebaseAuthProvider).authStateChanges().listen((usuario) {
      if (usuario == null) {
        ref.read(servicioCifradoProvider).bloquear();
        ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(estadoAutenticacionProvider).value;
    final desbloqueado = ref.watch(bloqueoCifradoProvider);
    return MaterialApp.router(
      title: 'Oncuidar',
      debugShowCheckedModeBanner: false,
      theme: Tema.obtener(),
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          if (usuario != null && !desbloqueado)
            const Positioned.fill(child: _GateClave()),
        ],
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
      final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
      await ref.read(servicioCifradoProvider).asegurarClave(uid);
      ref.read(bloqueoCifradoProvider.notifier).fijarDesbloqueado(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudieron restaurar tus datos.';
        });
      }
    }
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
                    const Icon(Icons.cloud_off_outlined,
                        size: 56, color: Colors.orange),
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
                  ],
                ),
              ),
      ),
    );
  }
}