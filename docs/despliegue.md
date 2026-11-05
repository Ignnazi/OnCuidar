# Despliegue

## Servidor

La API, la base de datos y la página de descarga corren en `parra.chillan.ubiobio.cl` con podman y `podman-compose`, en la carpeta `~/oncuidar`. El proxy HTTPS de la universidad publica la API en `https://parra.chillan.ubiobio.cl/oncuidar-backend/` y la web en `https://parra.chillan.ubiobio.cl/oncuidar/`; los puertos 8014 y 8015 solo responden por HTTP.

| Servicio | Puerto | Contenido |
| --- | --- | --- |
| `api` | 8014 | API REST (`/api`) |
| `web` | 8015 | Página de descarga y `OnCuidar.apk` |
| `db` | interno | PostgreSQL 15, datos en el volumen `datos_postgres` |
| `grafana` | 8015 en `/grafana/` | Paneles de monitoreo |
| `prometheus`, `blackbox`, `alertmanager` | interno | Revisión de servicios y alertas por correo |

El servidor usa el mismo `docker-compose.yml` del repositorio (proyecto `oncuidar`). El archivo `~/oncuidar/.env` tiene las credenciales de producción y no se versiona. Las variables necesarias están en `.env.ejemplo`; en el servidor además van:

```
PUERTO_API=8014
PUERTO_WEB=8015
IMAGEN_API=<la fija el despliegue>
```

Los videos de `backend/archivos/videos` no están en git: viven en el servidor y se montan en la API.

En local, el proyecto también se llama `oncuidar`. Quien lo haya levantado antes con el nombre `oncuidar-docker` debe bajarlo primero con `docker compose -p oncuidar-docker down`; sus datos quedan en los volúmenes `oncuidar-docker_*`.

## Despliegue automático

Cada push a `main` (o sea, cada pull request integrado) se despliega solo, después de que pasen las pruebas. El firewall de la universidad no deja entrar conexiones SSH desde GitHub, así que el despliegue funciona al revés: GitHub publica y el servidor sale a buscar.

En `.github/workflows/ci.yml`:

1. **Imagen**: construye la imagen de la API y la publica en GitHub Container Registry como `ghcr.io/ignnazi/oncuidar-api:<commit>`.
2. **Paquete de despliegue**: publica `ghcr.io/ignnazi/oncuidar-despliegue` con el `docker-compose.yml`, `monitoreo/`, la página, `database/init.sql`, `scripts/`, el APK recién compilado y el nombre de la imagen de la API. La etiqueta `:main` apunta siempre al último commit de `main` que pasó todo.

En el servidor, cron ejecuta `scripts/actualizar.sh` cada 15 minutos:

- revisa si la etiqueta `:main` del paquete cambió; si no, termina sin hacer nada;
- si cambió, extrae el paquete en `~/oncuidar/.despliegue` y ejecuta `scripts/desplegar.sh` con la imagen nueva;
- anota la versión desplegada en `.paquete-desplegado`; si el despliegue falla, la anota en `.paquete-fallido` y no la reintenta hasta que llegue otra;
- deja lo que hizo en `~/oncuidar/actualizar.log`, que se recorta a 1000 líneas cuando pasa de 2000; si nada cambió, no escribe.

`scripts/desplegar.sh`:

- descarga la imagen nueva antes de tocar nada; si no puede, no cambia nada;
- copia solo los archivos que cambiaron y reinicia solo los servicios afectados; la base de datos nunca se reinicia;
- deja la imagen en `IMAGEN_API` del `.env` y recrea la API;
- espera a que respondan `/api/salud` y la página; si no responden, restaura los archivos y la imagen anteriores;
- conserva las 3 imágenes más recientes de la API y borra las demás.

La salida de `podman-compose` incluye variables del `.env`, así que queda solo en `~/oncuidar/despliegue.log`, que se reemplaza en cada despliegue.

Las imágenes son públicas (el repositorio también lo es), así que el servidor no guarda ninguna credencial de GitHub. Las pruebas de los dos scripts están en `test/despliegue/` y corren en el job Backend.

Puesta en marcha (una sola vez):

1. Después de la primera ejecución del CI en `main`, en GitHub > Packages > `oncuidar-despliegue` > Package settings, dejar la visibilidad en **Public**. Si queda privado, el servidor no lo puede descargar y `actualizar.log` muestra "No se pudo consultar el paquete de despliegue".
2. Copiar `scripts/actualizar.sh` al servidor en `~/oncuidar/scripts/` (después se actualiza solo con cada despliegue) e instalar la revisión periódica:

```bash
(crontab -l 2>/dev/null; echo "*/15 * * * * bash \$HOME/oncuidar/scripts/actualizar.sh") | crontab -
```

### Desplegar a mano

Para forzar una revisión sin esperar a cron, ejecutar `bash ~/oncuidar/scripts/actualizar.sh` y mirar `actualizar.log`. Si GitHub no está disponible, se puede desplegar desde el servidor:

```bash
cd ~/oncuidar
podman-compose build api
podman-compose up -d --no-deps --force-recreate api
curl -s http://localhost:8014/api/salud
podman logs --tail 50 oncuidar_api_1
```

Antes de construir a mano, quitar `IMAGEN_API` del `.env` para que se use la imagen local. El APK se publica copiándolo a `~/oncuidar/web/OnCuidar.apk`.

La URL de la API se fija al compilar el APK con la variable de repositorio `API_URL` (Settings > Secrets and variables > Actions > Variables), por ejemplo `https://parra.chillan.ubiobio.cl/oncuidar-backend/api`. Sin ella el job falla.

## Versiones

Cada versión publicada sube `version` en `pubspec.yaml`: el número antes del `+` es la versión visible y el de después debe aumentar siempre, porque Android lo usa para reconocer una actualización. Una vez integrada en `main`, se crea la etiqueta con el mismo número:

```bash
git switch main && git pull
git tag -a v1.0.1 -m "OnCuidar v1.0.1"
git push origin v1.0.1
```

`.github/workflows/release.yml` comprueba que la etiqueta coincida con `pubspec.yaml` y apunte a un commit de `main`, corre las pruebas, compila el APK y lo publica en la pestaña Releases como `OnCuidar-v1.0.1.apk`, con las notas generadas a partir de los pull requests.

## Monitoreo

Los servicios se revisan desde dentro del servidor, así que el firewall de la universidad no afecta las mediciones:

- `blackbox` consulta `http://api:3000/api/salud` (que también comprueba la base de datos) y la página web.
- `prometheus` guarda los resultados cada 30 segundos durante 30 días y evalúa las reglas de `monitoreo/prometheus/alertas.yml`: servicio caído por más de 2 minutos, respuesta de más de 3 segundos durante 5 minutos y monitoreo sin datos.
- `alertmanager` envía las alertas y su resolución por correo.
- `grafana` muestra el panel "OnCuidar - Servicios" en `https://parra.chillan.ubiobio.cl/oncuidar/grafana/`. Solo Grafana queda accesible desde fuera, a través del nginx de la web, que le pasa las rutas sin el prefijo `/grafana`.

Variables del `.env`:

```
GRAFANA_CLAVE=<contraseña del usuario admin de Grafana>
URL_GRAFANA=https://parra.chillan.ubiobio.cl/oncuidar/grafana/
ALERTAS_CORREO=oncuidar1@gmail.com
ALERTAS_CLAVE=<contraseña de aplicación de Gmail>
```

`GRAFANA_CLAVE` es obligatoria. La contraseña de aplicación se crea en la cuenta de Google, en Seguridad > Verificación en dos pasos > Contraseñas de aplicaciones; no sirve la contraseña normal. Sin `ALERTAS_CORREO` o `ALERTAS_CLAVE`, Alertmanager no arranca, pero el resto de los servicios sigue funcionando.

Para levantarlo por primera vez o después de cambiar la configuración (la primera vez Grafana tarda unos minutos en responder):

```bash
cd ~/oncuidar
podman-compose up -d prometheus blackbox alertmanager grafana
podman-compose up -d --no-deps web
```

## Respaldos

`scripts/respaldar_bd.sh` guarda un volcado comprimido en `~/respaldos-oncuidar` y elimina los de más de 14 días. Para ejecutarlo todos los días a las 03:00, copiar el script al servidor y agregar con `crontab -e`:

```
0 3 * * * $HOME/oncuidar/scripts/respaldar_bd.sh >> $HOME/respaldos-oncuidar/respaldo.log 2>&1
```

Para restaurar un respaldo, detener la API, recrear la base y cargar el volcado:

```bash
cd ~/oncuidar
podman-compose stop api
podman exec oncuidar_db_1 sh -c 'dropdb -U "$POSTGRES_USER" "$POSTGRES_DB" && createdb -U "$POSTGRES_USER" "$POSTGRES_DB"'
gunzip -c ~/respaldos-oncuidar/oncuidar-AAAAMMDD-HHMM.sql.gz | podman exec -i oncuidar_db_1 sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" "$POSTGRES_DB"'
podman-compose start api
```

## Integración continua

`.github/workflows/ci.yml` corre en cada pull request y push a `main` y `desarrollo`:

- App: formato, `flutter analyze` y `flutter test`.
- Backend: pruebas de integración contra PostgreSQL 15 y pruebas de los scripts de despliegue.
- APK: solo en `main`, después de que pasen las pruebas de la app.
- Imagen y Paquete de despliegue: solo en `main`; ver [Despliegue automático](#despliegue-automático).

Dependabot (`.github/dependabot.yml`) abre pull requests hacia `desarrollo` los lunes con las dependencias de Flutter y del backend, y una vez al mes con la imagen de Docker y las acciones de GitHub. Solo propone actualizaciones menores, agrupadas en un solo pull request; las versiones mayores pueden romper la app y se actualizan a mano.
