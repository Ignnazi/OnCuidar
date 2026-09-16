import 'package:go_router/go_router.dart';
import '../../caracteristicas/dashboard/dashboard.dart';
import '../../caracteristicas/historial/historial.dart';
import '../../caracteristicas/onboarding/bienvenida.dart';
import '../../caracteristicas/onboarding/iniciar_sesion.dart';
import '../../caracteristicas/onboarding/proximamente.dart';
import '../../caracteristicas/onboarding/recuperar_acceso.dart';
import '../../caracteristicas/onboarding/registro.dart';
import '../../caracteristicas/onboarding/splash.dart';
import '../../caracteristicas/perfil/perfil.dart';
import '../../caracteristicas/registro_clinico/registro_clinico.dart';
import '../../compartidos/widgets/navegacion_principal.dart';
import '../../modelos/registro_clinico.dart';

GoRoute _rutaRegistroClinico() {
  return GoRoute(
    path: '/registro-clinico',
    builder: (context, state) => RegistroClinicoScreen(
      registroInicial: state.extra is RegistroClinico
          ? state.extra as RegistroClinico
          : null,
    ),
  );
}

GoRoute _rutaHistorial() {
  return GoRoute(
    path: '/historial',
    builder: (context, state) => HistorialScreen(
      filtroFechaInicial:
          (state.extra as Map<String, dynamic>?)?['filtroFecha'] as DateTime?,
    ),
  );
}

GoRoute _rutaProximamente() {
  return GoRoute(
    path: '/proximamente',
    builder: (context, state) => Proximamente(
      titulo: state.uri.queryParameters['titulo'] ?? 'Próximamente',
    ),
  );
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          Splash(alFinalizar: () => context.go('/bienvenida')),
    ),
    GoRoute(
      path: '/bienvenida',
      builder: (context, state) => Bienvenida(
        alIniciarSesion: () => context.push('/iniciar-sesion'),
        alCrearCuenta: () => context.push('/crear-cuenta'),
      ),
    ),
    GoRoute(
      path: '/iniciar-sesion',
      builder: (context, state) => const IniciarSesion(),
    ),
    GoRoute(
      path: '/crear-cuenta',
      builder: (context, state) => const Registro(),
    ),
    GoRoute(
      path: '/recuperar-acceso',
      builder: (context, state) => const RecuperarAcceso(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => NavegacionPrincipal(
        shell: navigationShell,
        ubicacion: state.uri.path,
        tituloProximamente: state.uri.queryParameters['titulo'],
        child: navigationShell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const Dashboard(),
            ),
            _rutaRegistroClinico(),
            _rutaHistorial(),
            _rutaProximamente(),
          ],
        ),
        // Pestaña Perfil.
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/perfil', builder: (context, state) => const Perfil()),
            _rutaRegistroClinico(),
            _rutaHistorial(),
            _rutaProximamente(),
          ],
        ),
      ],
    ),
  ],
);