# Pruebas

Las pruebas están ordenadas según los niveles de prueba de ISTQB (componente, integración, sistema y aceptación) y los tipos de prueba de Flutter (unit, widget e integration).

| Carpeta | Nivel ISTQB | Tipo en Flutter | Qué verifica |
|---|---|---|---|
| `unitarias/` | Componente | Unit | Reglas de negocio, cifrado, cola sin conexión y sincronización, sin pantallas |
| `widgets/` | Componente | Widget | Pantallas y componentes dibujados en un entorno simulado |
| `integracion/` | Integración | | API y base de datos juntas: autenticación, aislamiento entre usuarios y datos cifrados |
| `sistema/` | Sistema | Integration | La app completa en un emulador contra la API en Docker |
| `aceptacion/` | Aceptación | | Matriz de trazabilidad y certificación manual sobre el APK |
| `caos/` | Prueba no funcional de resiliencia | | Caídas de contenedores, red lenta y toques al azar |

Dentro de `unitarias/` y `widgets/` las carpetas son espejo de `lib/`, así que la prueba de cada archivo se encuentra en la misma ruta. `ayudas/` tiene utilidades compartidas.

## Cómo correrlas

```
flutter test
docker compose -f docker-compose.pruebas.yml up -d
cd backend && npm test
```

`flutter test` corre las unitarias y las de widgets. También se puede correr una sola categoría, por ejemplo `flutter test test/unitarias`.

Las de sistema necesitan el servidor arriba (`docker compose up -d`) y un emulador Android de 64 bits o un teléfono conectado. `flutter test` las salta por defecto:

```
flutter test test/sistema -d emulator-5554 --run-skipped
```

Las de caos se explican en caos/README.md.
