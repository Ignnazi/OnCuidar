import 'package:go_router/go_router.dart';
import '../../caracteristicas/dashboard/dashboard.dart';
import '../../caracteristicas/onboarding/bienvenida.dart';
import '../../caracteristicas/onboarding/iniciar_sesion.dart';
import '../../caracteristicas/onboarding/proximamente.dart';
import '../../caracteristicas/onboarding/registro.dart';
import '../../caracteristicas/onboarding/splash.dart';
import '../../caracteristicas/perfil/perfil.dart';
import '../../compartidos/widgets/navegacion_principal.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Splash(
        alFinalizar: () => context.go('/bienvenida'),
      ),
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
    ShellRoute(
      builder: (context, state, child) => NavegacionPrincipal(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Dashboard(),
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const Perfil(),
        ),
        GoRoute(
          path: '/proximamente',
          builder: (context, state) => Proximamente(
            titulo: state.uri.queryParameters['titulo'] ?? 'Próximamente',
          ),
        ),
      ],
    ),
  ],
);