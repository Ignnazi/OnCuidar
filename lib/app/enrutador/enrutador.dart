import 'package:go_router/go_router.dart';
import 'package:oncuidar/app/navegacion_principal.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_bienvenida.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_carga.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_crear_cuenta.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_iniciar_sesion.dart';
import 'package:oncuidar/caracteristicas/autenticacion/presentacion/pantalla_recuperar_acceso.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_biblioteca.dart';
import 'package:oncuidar/caracteristicas/biblioteca/presentacion/pantalla_detalle_material.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/pantalla_chat.dart';
import 'package:oncuidar/caracteristicas/historial/presentacion/pantalla_historial.dart';
import 'package:oncuidar/caracteristicas/panel_principal/presentacion/pantalla_panel_principal.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/pantalla_perfil.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/presentacion/pantalla_preguntas_frecuentes.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/pantalla_recordatorios.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/pantalla_registro_clinico.dart';

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
    builder: (context, state) =>
        BibliotecaScreen(abrirId: state.uri.queryParameters['abrir']),
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
