# OnCuidar

Aplicación móvil para cuidadores de niños, niñas y adolescentes con cáncer. Permite registrar síntomas y signos vitales, programar recordatorios y consultar material educativo, incluso sin conexión.

La app está hecha en Flutter. El backend usa Node.js y PostgreSQL y se levanta con Docker.

## Cómo usarla

Primero se copia `.env.ejemplo` como `.env` y se cambian las claves. Luego se levanta el servidor y se corre la app:

```
docker compose up -d --build
flutter pub get
flutter run
```

Para probarla en un teléfono hay que indicar la IP del PC:

```
flutter run --dart-define=API_URL=http://IP-DEL-PC:8080/api
```

Para generar el APK:

```
flutter build apk --release --dart-define=API_URL=https://SERVIDOR/ruta/api
```

El APK de producción solo se conecta por HTTPS. La conexión por HTTP sin cifrar se permite únicamente en las compilaciones de desarrollo.

Los videos de la biblioteca pesan mucho y no están en el repositorio. Se copian a mano en `backend/archivos/videos`.

## Pruebas

```
flutter test
docker compose -f docker-compose.pruebas.yml up -d
cd backend && npm install && npm test
```

El detalle de cada nivel está en `test/README.md`.

## Despliegue

Cada pull request integrado en `main` se publica solo en el servidor de la universidad. El servidor, el despliegue automático, el monitoreo y la integración continua están explicados en `docs/despliegue.md`.
