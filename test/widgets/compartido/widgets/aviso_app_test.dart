import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/aviso_app.dart';

void main() {
  late BuildContext contexto;

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            contexto = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );
  }

  Color? colorDelAviso(WidgetTester tester) =>
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor;

  Future<void> esperar(WidgetTester tester, Duration tiempo) async {
    await tester.pump(tiempo);
    await tester.pump(const Duration(milliseconds: 500));
  }

  tearDown(AvisoApp.ocultar);

  testWidgets('muestra el aviso y lo retira al terminar el tiempo', (
    tester,
  ) async {
    await abrir(tester);

    AvisoApp.info(contexto, 'Hola');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Hola'), findsOneWidget);

    await esperar(tester, AvisoApp.duracion);

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('un aviso nuevo reemplaza al visible sin hacer cola', (
    tester,
  ) async {
    await abrir(tester);

    AvisoApp.info(contexto, 'Añadido a favoritos');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    AvisoApp.info(contexto, 'Quitado de favoritos');
    AvisoApp.info(contexto, 'Añadido a favoritos');
    AvisoApp.info(contexto, 'Quitado de favoritos');
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Quitado de favoritos'), findsOneWidget);
    expect(find.text('Añadido a favoritos'), findsNothing);

    await esperar(tester, AvisoApp.duracion);

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('cada tipo conserva el color de siempre', (tester) async {
    await abrir(tester);

    AvisoApp.info(contexto, 'Info');
    await tester.pump();
    expect(colorDelAviso(tester), Paleta.doradoPrincipal);

    AvisoApp.alerta(contexto, 'Error');
    await tester.pump();
    expect(colorDelAviso(tester), Paleta.error);

    AvisoApp.conexion(contexto, 'Sin conexión');
    await tester.pump();
    expect(colorDelAviso(tester), Paleta.doradoBannerOscuro);
  });

  testWidgets('una alerta dura más que un aviso normal', (tester) async {
    await abrir(tester);

    AvisoApp.info(contexto, 'Listo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await esperar(tester, const Duration(milliseconds: 3000));
    expect(find.byType(SnackBar), findsNothing);

    AvisoApp.alerta(contexto, 'Falló');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.byType(SnackBar), findsOneWidget);
    await esperar(tester, const Duration(milliseconds: 1500));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('con ícono el aviso es flotante', (tester) async {
    await abrir(tester);

    AvisoApp.info(contexto, 'Sin red', icono: Icons.cloud_off_rounded);
    await tester.pump();

    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).behavior,
      SnackBarBehavior.floating,
    );
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('ocultar quita el aviso', (tester) async {
    await abrir(tester);

    AvisoApp.info(contexto, 'Descargando…');
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);

    AvisoApp.ocultar();
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('capturar el aviso permite mostrarlo tras una espera', (
    tester,
  ) async {
    await abrir(tester);

    final aviso = AvisoApp.capturar(contexto);
    aviso.alerta('Falló');
    await tester.pump();

    expect(find.text('Falló'), findsOneWidget);
  });
}
