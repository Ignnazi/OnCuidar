# Despliegue

## Servidor

La API, la base de datos y la página de descarga corren en `parra.chillan.ubiobio.cl` con podman y `podman-compose`, en la carpeta `~/oncuidar`.

| Servicio | Puerto | Contenido |
| --- | --- | --- |
| `api` | 8014 | API REST (`/api`) |
| `web` | 8015 | Página de descarga y `OnCuidar.apk` |
| `db` | interno | PostgreSQL 15, datos en el volumen `datos_postgres` |

El archivo `~/oncuidar/.env` tiene las credenciales de producción y no se versiona. Las variables necesarias están en `.env.ejemplo`.

## Actualizar el backend

1. Respaldar la base de datos (ver [Respaldos](#respaldos)).
2. Copiar el backend sin `node_modules` ni `archivos`:

   ```bash
   rsync -av --exclude node_modules --exclude archivos backend/ <usuario>@parra.chillan.ubiobio.cl:~/oncuidar/backend/
   ```

3. Reconstruir y reiniciar solo la API:

   ```bash
   cd ~/oncuidar
   podman-compose build api
   podman-compose up -d --no-deps api
   ```

4. Verificar:

   ```bash
   curl -s http://localhost:8014/api/salud
   podman logs --tail 50 oncuidar_api_1
   ```

Si algo falla, volver a copiar la versión anterior del backend y repetir el paso 3.

## Publicar el APK

El workflow de CI compila el APK en cada integración a `main` y lo deja como artefacto de la ejecución en la pestaña Actions. Para publicarlo:

```bash
scp app-release.apk <usuario>@parra.chillan.ubiobio.cl:~/oncuidar/web/OnCuidar.apk
```

La URL de la API se fija al compilar con la variable de repositorio `API_URL` (Settings > Secrets and variables > Actions > Variables), por ejemplo `http://parra.chillan.ubiobio.cl:8014/api`. Sin ella el job falla.

## Versiones

Cada versión publicada sube `version` en `pubspec.yaml`: el número antes del `+` es la versión visible y el de después debe aumentar siempre, porque Android lo usa para reconocer una actualización. Una vez integrada en `main`, se crea la etiqueta con el mismo número:

```bash
git switch main && git pull
git tag -a v1.0.1 -m "OnCuidar v1.0.1"
git push origin v1.0.1
```

`.github/workflows/release.yml` comprueba que la etiqueta coincida con `pubspec.yaml` y apunte a un commit de `main`, corre las pruebas, compila el APK y lo publica en la pestaña Releases como `OnCuidar-v1.0.1.apk`, con las notas generadas a partir de los pull requests.

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
- Backend: pruebas de integración contra PostgreSQL 15.
- APK: solo en `main`, después de que pasen las pruebas de la app.

Dependabot (`.github/dependabot.yml`) abre pull requests hacia `desarrollo` los lunes con las dependencias de Flutter y del backend, y una vez al mes con la imagen de Docker y las acciones de GitHub. Las actualizaciones menores llegan agrupadas en un solo pull request.
