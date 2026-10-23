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

| # | Falla | Qué se verifica | Resultado (20 y 23 de octubre) |
|---|---|---|---|
| 01 | `docker compose kill api` | Si Docker vuelve a levantar la API | No se levanta. Docker trata el kill como parada manual e ignora `restart: unless-stopped` |
| 02 | `docker compose kill db` | Si la API vuelve a responder | No responde. La consulta a la base quedaba esperando sin límite de tiempo |
| 03 | `docker compose pause api` | Si la API responde estando congelada | No responde. El contenedor sigue activo pero no atiende peticiones |
| 04 | `docker compose exec api kill 1` | Si Docker vuelve a levantar la API tras una caída interna | La API respondió 200 a los 20 segundos |
| 05 | `docker compose kill db` y luego `up` | Si la API falla rápido y se recupera | Responde 500 en 5 segundos con la base caída y 200 cuando vuelve |

A partir del experimento 02 se agregaron límites de tiempo al pool de PostgreSQL en backend/src/db.js. El experimento 05 comprueba ese cambio.
