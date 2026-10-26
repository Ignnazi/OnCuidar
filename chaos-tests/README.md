# Pruebas de caos

Experimentos con Chaos Toolkit para ver cómo se comporta el backend cuando falla una parte del sistema. Cada experimento mide el estado sano de la API, provoca una falla en un contenedor, vuelve a medir y al final deja todo arriba de nuevo.

Se usa Chaos Toolkit en vez del Chaos Monkey de Netflix porque ese está pensado para la nube y aquí el sistema corre en Docker.

## Requisitos

- Docker Desktop abierto y el .env creado a partir de .env.ejemplo.
- Chaos Toolkit instalado: `pip install chaostoolkit`
- El sistema arriba, desde la raíz del repositorio:

```
docker compose up -d --wait
```

## Cómo correr un experimento

Desde la raíz del repositorio:

```
chaos validate chaos-tests/experiments/01-matar-api.json
chaos run chaos-tests/experiments/01-matar-api.json --rollback-strategy=always --journal-path chaos-tests/registros/01-journal.json
```

Con `--rollback-strategy=always` el sistema se vuelve a levantar aunque el experimento falle. Por defecto Chaos Toolkit no lo hace si la hipótesis no se cumple.

El resultado de cada corrida queda en chaos-tests/registros, con el estado y la duración de cada medición.

Las esperas se hacen con `powershell Start-Sleep` porque `time.sleep` con `type: python` no pasa la validación de Chaos Toolkit.

## Experimentos

| # | Falla | Qué se verifica | Resultado (26 de octubre) |
|---|---|---|---|
| 01 | `docker compose kill api` | Si Docker vuelve a levantar la API | No se levanta. Docker trata el kill como parada manual e ignora `restart: unless-stopped` |
| 02 | `pg_ctl stop -m immediate` dentro de la base | Si la base se reinicia sola y la API vuelve a consultarla | Docker reinicia la base y la API responde 200 sin intervención |
| 03 | `docker compose pause api` | Si la API responde estando congelada | No responde. El contenedor sigue activo pero no atiende peticiones |
| 04 | `kill -9` al proceso de Node dentro de la API | Si Docker reinicia la API tras una caída interna | Docker reinicia el contenedor y la API responde 200 |
| 05 | `docker compose kill db` y luego `up` | Si la API falla rápido y se recupera | Responde 500 en 4 segundos con la base caída y 200 cuando vuelve |

Los experimentos 01 y 03 muestran límites de Docker y no fallas de la app. Para cubrirlos haría falta un orquestador o un monitor externo.

Lo que salió de estas pruebas:

- Con la base caída la consulta quedaba esperando sin límite. Se agregaron límites de tiempo al pool de PostgreSQL en backend/src/db.js y el experimento 05 comprueba el cambio.
- Node corría como PID 1 y así ignora las señales, por lo que un `kill` dentro del contenedor no lo detenía. Se agregó `init: true` a la API en docker-compose.yml.
- Los experimentos 02 y 04 confirman que el contenedor se reinició midiendo la antigüedad del PID 1, no solo con la respuesta de la API.
