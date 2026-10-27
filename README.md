# OnCuidar

Aplicación móvil para cuidadores de niños, niñas y adolescentes con cáncer. Permite registrar síntomas y signos vitales, programar recordatorios y consultar material educativo, incluso sin conexión.

La app está hecha en Flutter y el backend en Node.js con PostgreSQL, levantado con Docker.

## Cómo usarla

Primero se copia .env.ejemplo como .env y se cambian las claves. Luego se levanta el servidor y se corre la app:

```
docker compose up -d --build
flutter pub get
flutter run
```

Para probarla en un teléfono hay que indicar la IP del PC:

```
flutter run --dart-define=API_URL=http://IP-DEL-PC:8080/api
```

Y para generar el APK:

```
flutter build apk --release --dart-define=API_URL=http://SERVIDOR:PUERTO/api
```

Los videos de la biblioteca no están en el repositorio por su peso, se copian a mano en backend/archivos/videos.

## Pruebas

El detalle de cada nivel está en test/README.md.

```
flutter test
docker compose -f docker-compose.pruebas.yml up -d
cd backend && npm install && npm test
```
