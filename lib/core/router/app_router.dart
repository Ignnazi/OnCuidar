import 'package:go_router/go_router.dart';
import '../../caracteristicas/biblioteca/biblioteca.dart';
import '../../caracteristicas/biblioteca/pantalla_detalle.dart';
import '../../caracteristicas/chat/chat.dart';
import '../../caracteristicas/dashboard/dashboard.dart';
import '../../caracteristicas/faq/faq.dart';
import '../../caracteristicas/historial/historial.dart';
import '../../caracteristicas/onboarding/bienvenida.dart';
import '../../caracteristicas/onboarding/iniciar_sesion.dart';
import '../../caracteristicas/onboarding/recuperar_acceso.dart';
import '../../caracteristicas/onboarding/registro.dart';
import '../../caracteristicas/onboarding/splash.dart';
import '../../caracteristicas/perfil/perfil.dart';
import '../../caracteristicas/recordatorios/recordatorios.dart';
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

GoRoute _rutaChat() {
  return GoRoute(
    path: '/chat',
    builder: (context, state) => const ChatScreen(),
  );
}

GoRoute _rutaFaq() {
  return GoRoute(path: '/faq', builder: (context, state) => const FaqScreen());
}

GoRoute _rutaRecordatorios() {
  return GoRoute(
    path: '/recordatorios',
    builder: (context, state) => const RecordatoriosScreen(),
  );
}

GoRoute _rutaBiblioteca() {
  return GoRoute(
    path: '/biblioteca',
    builder: (context, state) => const BibliotecaScreen(),
  );
}

GoRoute _rutaBibliotecaDetalle() {
  return GoRoute(
    path: '/biblioteca/:id',
    builder: (context, state) =>
        PantallaDetalleMaterial(id: state.pathParameters['id'] ?? ''),
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
            _rutaChat(),
            _rutaFaq(),
            _rutaRecordatorios(),
            _rutaBiblioteca(),
            _rutaBibliotecaDetalle(),
          ],
        ),
        // Pestaña Perfil.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/perfil',
              builder: (context, state) => const Perfil(),
            ),
            _rutaRegistroClinico(),
            _rutaHistorial(),
            _rutaChat(),
            _rutaFaq(),
            _rutaRecordatorios(),
            _rutaBiblioteca(),
            _rutaBibliotecaDetalle(),
          ],
        ),
      ],
    ),
  ],
);
