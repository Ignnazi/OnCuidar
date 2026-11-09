# Pruebas

Las pruebas están ordenadas según los niveles de prueba de ISTQB (componente, integración, sistema y aceptación) y los tipos de prueba de Flutter (unit, widget e integration).

| Carpeta | Nivel ISTQB | Tipo en Flutter | Qué verifica |
|---|---|---|---|
| `unitarias/` | Componente | Unit | Reglas de negocio, cifrado, cola sin conexión y sincronización, sin pantallas |
| `widgets/` | Componente | Widget | Pantallas y componentes dibujados en un entorno simulado |
| `integracion/` | Integración | | API y base de datos juntas: autenticación, aislamiento entre usuarios y datos cifrados |
| `sistema/` | Sistema | Integration | La app completa en un emulador contra la API en Docker |
| `aceptacion/` | Aceptación | | Matriz de trazabilidad y certificación manual sobre el APK |
| `caos/` | Prueba no funcional de resiliencia | | Caídas de contenedores, red lenta y alerta de servicio caído |

Dentro de `unitarias/` y `widgets/` las carpetas siguen la estructura de `lib/` por área, así que las pruebas de cada parte de la app están en la ruta equivalente. `ayudas/` tiene utilidades compartidas.

## Cómo correrlas

```
flutter test
docker compose -f docker-compose.pruebas.yml up -d
cd backend && npm test
```

`flutter test` corre las unitarias y las de widgets. También se puede correr una sola categoría, por ejemplo `flutter test test/unitarias`.

Las de sistema usan `integration_test` y necesitan el servidor arriba y un teléfono o emulador conectado, por eso `flutter test` las salta. El mismo recorrido se verifica a mano sobre el APK, según `aceptacion/certificacion.md`.

Las de caos se explican en `caos/README.md`.

## Casos del informe

Los casos que se citan en el anexo de pruebas del informe se listan en `aceptacion/casos_criticos.md`. Los de unidad (PU) e integración (PI) llevan el identificador en el nombre de la prueba. Los de sistema (PS) aparecen en la columna Caso de `aceptacion/certificacion.md`, y los de resiliencia (PC-01 a PC-07) son los experimentos 01 a 07 de `caos/`.

Los de unidad e integración se pueden correr solos, con la base de pruebas arriba para los segundos:

```
flutter test --tags criticos
cd backend && npx jest --runInBand -t "PI-"
```
