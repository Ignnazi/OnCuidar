# Despliegue

## Servidor

La API, la base de datos y la página de descarga corren en `parra.chillan.ubiobio.cl`, en la carpeta `~/oncuidar`, con podman y `podman-compose`.

El proxy HTTPS de la universidad publica:

- la API en `https://parra.chillan.ubiobio.cl/oncuidar-backend/`
- la página de descarga en `https://parra.chillan.ubiobio.cl/oncuidar/`

Los puertos 8014 y 8015 solo responden por HTTP y no se usan desde fuera. La API escucha solo en `127.0.0.1`: se llega a ella a través del Apache de la U, que agrega la IP real del cliente (la API confía en ese único salto para el límite de intentos).

| Servicio | Puerto | Contenido |
| --- | --- | --- |
| `api` | 8014 | API REST (`/api`) |
| `web` | 8015 | Página de descarga y `OnCuidar.apk` |
| `db` | interno | PostgreSQL 15, datos en el volumen `datos_postgres` |
| `grafana` | 8015, en `/grafana/` | Paneles de monitoreo |
| `prometheus`, `blackbox`, `alertmanager` | interno | Revisión de servicios y alertas por correo |

El servidor usa el mismo `docker-compose.yml` del repositorio. Las credenciales de producción están en `~/oncuidar/.env`, que no se versiona. Las variables necesarias están en `.env.ejemplo`. En el servidor también van estas:

```
PUERTO_API=8014
PUERTO_WEB=8015
IMAGEN_API=<la escribe el despliegue>
```

Los videos de `backend/archivos/videos` no están en git. Están en el servidor y se montan en la API.

Si alguien levantó el proyecto en local con el nombre antiguo `oncuidar-docker`, primero debe bajarlo con `docker compose -p oncuidar-docker down`. Sus datos siguen en los volúmenes `oncuidar-docker_*`.

## Despliegue automático

Cada pull request integrado en `main` se despliega solo cuando pasan las pruebas.

El firewall de la universidad bloquea las conexiones SSH que vienen de GitHub. Por eso GitHub no entra al servidor. Publica un paquete y es el servidor el que lo va a buscar.

### En GitHub

Dos jobs de `.github/workflows/ci.yml` corren solo en `main`:

1. **Imagen** construye la imagen de la API y la publica como `ghcr.io/ignnazi/oncuidar-api:<commit>`.
2. **Paquete de despliegue** publica `ghcr.io/ignnazi/oncuidar-despliegue` con el `docker-compose.yml`, `monitoreo/`, la página, `database/init.sql`, `scripts/`, el APK y el nombre de la imagen de la API. La etiqueta `:main` apunta al último commit de `main` que pasó todas las pruebas.

Las dos imágenes son públicas, igual que el repositorio. El servidor no guarda credenciales de GitHub.

### En el servidor

Cada 15 minutos, cron ejecuta `scripts/actualizar.sh`. El script:

1. Revisa si cambió la etiqueta `:main` del paquete. Si no cambió, termina sin hacer nada.
2. Extrae el paquete en `~/oncuidar/.despliegue` y ejecuta `scripts/desplegar.sh` con la imagen nueva.
3. Anota la versión en `.paquete-desplegado`. Si el despliegue falla, la anota en `.paquete-fallido` y no la vuelve a intentar hasta que llegue otra versión.

`scripts/desplegar.sh`:

1. Descarga la imagen nueva. Si no puede, se detiene sin cambiar nada.
2. Copia solo los archivos que cambiaron y reinicia los servicios afectados. La base de datos nunca se reinicia.
3. Escribe la imagen en `IMAGEN_API` y recrea la API.
4. Espera a que respondan `/api/salud` y la página. Si no responden, vuelve a los archivos y la imagen anteriores.
5. Conserva las 3 imágenes más recientes de la API y borra las demás.

Dos registros quedan en el servidor:

- `~/oncuidar/actualizar.log` guarda cada despliegue. Cuando pasa de 2000 líneas se recorta a las últimas 1000.
- `~/oncuidar/despliegue.log` guarda la salida de `podman-compose` del último despliegue. No se muestra en GitHub porque incluye variables del `.env`.

Las pruebas de los dos scripts están en `test/despliegue/` y corren en el job Backend.

### Puesta en marcha

Se hace una sola vez:

1. Después de la primera ejecución en `main`, revisar en GitHub > Packages > `oncuidar-despliegue` que la visibilidad sea **Public**. Si es privado, el servidor no lo puede descargar y `actualizar.log` muestra "No se pudo consultar el paquete de despliegue".
2. Copiar `scripts/actualizar.sh` a `~/oncuidar/scripts/`. Después se actualiza solo con cada despliegue.
3. Instalar la tarea de cron:

```bash
(crontab -l 2>/dev/null; echo "*/15 * * * * bash \$HOME/oncuidar/scripts/actualizar.sh") | crontab -
```

Para desactivar el despliegue automático basta con `crontab -r`.

### Desplegar a mano

Para revisar sin esperar a cron:

```bash
bash ~/oncuidar/scripts/actualizar.sh
tail ~/oncuidar/actualizar.log
```

Si GitHub no está disponible, se puede construir la API en el servidor. Antes hay que quitar `IMAGEN_API` del `.env` para que se use la imagen local:

```bash
cd ~/oncuidar
podman-compose build api
podman-compose up -d --no-deps --force-recreate api
curl -s http://localhost:8014/api/salud
podman logs --tail 50 oncuidar_api_1
```

El APK se publica copiándolo a `~/oncuidar/web/OnCuidar.apk`.

### URL de la API en el APK

El APK se compila con la variable de repositorio `API_URL` (Settings > Secrets and variables > Actions > Variables). Hoy vale `https://parra.chillan.ubiobio.cl/oncuidar-backend/api`. Si falta, el job APK falla.

## Versiones

En `pubspec.yaml`, `version` tiene dos partes. El número antes del `+` es la versión que ve el usuario. El de después lo usa Android para reconocer una actualización y siempre tiene que aumentar.

Para publicar una versión en la pestaña Releases, se integra en `main` y se crea una etiqueta con el mismo número de `pubspec.yaml`:

```bash
git switch main && git pull
git tag -a vX.Y.Z -m "OnCuidar vX.Y.Z"
git push origin vX.Y.Z
```

`.github/workflows/release.yml` comprueba que la etiqueta coincida con `pubspec.yaml` y apunte a un commit de `main`. Luego corre las pruebas, compila el APK y lo publica como `OnCuidar-vX.Y.Z.apk` con notas generadas a partir de los pull requests.

## Monitoreo

Los servicios se revisan desde dentro del servidor, así que el firewall no afecta las mediciones.

- `blackbox` consulta `http://api:3000/api/salud`, que también comprueba la base de datos, y la página web.
- `prometheus` guarda los resultados cada 30 segundos durante 30 días. Las reglas de `monitoreo/prometheus/alertas.yml` avisan si un servicio cae por más de 2 minutos, si responde en más de 3 segundos durante 5 minutos o si el monitoreo deja de recibir datos.
- `alertmanager` envía por correo cada alerta y su resolución.
- `grafana` muestra el panel "OnCuidar - Servicios" en `https://parra.chillan.ubiobio.cl/oncuidar/grafana/`. Es el único servicio de monitoreo accesible desde fuera. Llega a través del nginx de la web, que le pasa las rutas sin el prefijo `/grafana`.

Variables del `.env`:

```
GRAFANA_USUARIO=<usuario administrador de Grafana, que no sea admin>
GRAFANA_CLAVE=<contraseña de ese usuario>
URL_GRAFANA=https://parra.chillan.ubiobio.cl/oncuidar/grafana/
ALERTAS_CORREO=oncuidar1@gmail.com
ALERTAS_CLAVE=<contraseña de aplicación de Gmail>
```

`GRAFANA_USUARIO` y `GRAFANA_CLAVE` son obligatorias y no tienen valor por defecto. Si falta una, `podman-compose` no arranca ningún servicio.

En parra hay que agregar `GRAFANA_USUARIO` al `.env` antes de desplegar esta versión. Si no, el despliegue falla y vuelve a la versión anterior. Grafana solo usa esta variable la primera vez que crea su base. Si ya existía el usuario `admin`, hay que cambiarle el nombre en Grafana > Administración > Usuarios al mismo valor.

`ALERTAS_CLAVE` es una contraseña de aplicación de Google, que se crea en Seguridad > Verificación en dos pasos > Contraseñas de aplicaciones. La contraseña normal de la cuenta no sirve. Sin `ALERTAS_CORREO` o `ALERTAS_CLAVE`, Alertmanager no arranca, pero el resto de los servicios funciona igual.

## Datos de pacientes

La base de datos no se respalda. OnCuidar es un prototipo sin pacientes reales y los datos de prueba se recrean con `database/init.sql`. Copiar datos de salud fuera del servidor institucional, por ejemplo a un equipo personal, no sería adecuado.

Los datos del paciente, como nombre, RUT, edad, diagnóstico y registros clínicos, se cifran en el teléfono con AES-GCM de 256 bits antes de enviarse. El servidor solo guarda la versión cifrada. El correo del cuidador queda sin cifrar porque se usa para iniciar sesión.

El registro responde 409 si el correo ya tiene cuenta. Es a propósito, para que la persona sepa que debe iniciar sesión. El límite de intentos por IP hace lento probar muchos correos.

Al borrar un paciente queda su id en `pacientes_borrados`. Si después llega un cambio de ese paciente, por ejemplo desde otro teléfono sin conexión, la API responde 410 y no lo vuelve a crear. La API crea esa tabla al arrancar, porque `database/init.sql` solo corre en una base nueva.

Borrar la cuenta pide la contraseña. Las contraseñas nuevas deben tener al menos 8 caracteres. Las cuentas creadas antes con 6 siguen entrando.

En un uso real con pacientes, los respaldos serían obligatorios. Se harían cifrados, en otro servidor de la institución y con acceso restringido.

## Integración continua

`.github/workflows/ci.yml` corre en cada pull request y en cada push a `main` y `desarrollo`.

| Job | Cuándo | Qué hace |
| --- | --- | --- |
| App | siempre | Formato, `flutter analyze` y `flutter test` |
| Backend | siempre | Pruebas contra PostgreSQL 15 y pruebas de los scripts de despliegue |
| APK | solo en `main` | Compila la app |
| Imagen | solo en `main` | Publica la imagen de la API |
| Paquete de despliegue | solo en `main` | Publica el paquete que descarga el servidor |

## Dependencias

Las dependencias se actualizan a mano, revisando cada cambio. Para ver qué hay disponible:

```
flutter pub outdated
cd backend && npm outdated
```

GitHub revisa las dependencias con las alertas de Dependabot y avisa en la pestaña Security si alguna tiene una vulnerabilidad conocida. También bloquea los push que incluyen contraseñas o claves.
