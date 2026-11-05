#!/usr/bin/env bash
# Despliega una versión nueva en el servidor. Lo ejecuta scripts/actualizar.sh con los
# archivos del paquete ya extraídos en ~/oncuidar/.despliegue.
#
# Uso: desplegar.sh <imagen-api> [usuario-registro]
# Si el registro pide clave, el token se pasa por la entrada estándar.
#
# Primero descarga la imagen. Después copia los archivos que cambiaron, reinicia los
# servicios afectados y recrea la API. Si la API o la web no responden, deja todo como
# estaba. La base de datos nunca se reinicia.
set -euo pipefail
# Si se cierra la terminal que lo lanzó, el despliegue termina igual
trap '' HUP

IMAGEN="${1:?Falta la imagen de la API}"
USUARIO_REGISTRO="${2:-}"
CARPETA="${CARPETA_ONCUIDAR:-$HOME/oncuidar}"
CONTENEDOR_API="${CONTENEDOR_API:-oncuidar_api_1}"
INTENTOS="${INTENTOS_SALUD:-30}"
ESPERA="${ESPERA_SALUD:-2}"
REGISTRO="${IMAGEN%%/*}"
REPOSITORIO_IMAGEN="${IMAGEN%:*}"
ENTRANTE="$CARPETA/.despliegue"
# La salida de podman-compose incluye variables del .env: se guarda aquí y nunca se muestra
BITACORA="$CARPETA/despliegue.log"

cd "$CARPETA"
anteriores=$(mktemp -d)
trap 'rm -rf "$anteriores" "$ENTRANTE"' EXIT
: > "$BITACORA"
chmod 600 "$BITACORA"

leer() { sed -n "s/^$1=//p" .env | tail -n 1; }
fijar() {
  if grep -q "^$1=" .env; then
    sed -i "s#^$1=.*#$1=$2#" .env
  else
    printf '%s=%s\n' "$1" "$2" >> .env
  fi
}
compose() {
  if ! podman-compose "$@" >> "$BITACORA" 2>&1; then
    echo "podman-compose falló al ejecutar: up $* (detalle en despliegue.log del servidor)"
    return 1
  fi
}
responde() {
  local i
  for ((i = 1; i <= INTENTOS; i++)); do
    if curl -fs --max-time 5 -o /dev/null "http://localhost:$(leer PUERTO_API)/api/salud" &&
      curl -fs --max-time 5 -o /dev/null "http://localhost:$(leer PUERTO_WEB)/"; then
      return 0
    fi
    sleep "$ESPERA"
  done
  return 1
}
# Se sobrescribe cada archivo en su lugar para conservar los permisos y etiquetas de los montajes
restaurar() {
  local origen ruta
  while IFS= read -r -d '' origen; do
    ruta="${origen#"$anteriores"/}"
    cp "$origen" "$ruta"
  done < <(find "$anteriores" -type f -print0)
  for ruta in ${nuevos[@]+"${nuevos[@]}"}; do rm -f "$ruta"; done
}

# 1. Comprobaciones antes de tocar nada
[ -f .env ] || { echo "Falta el archivo .env"; exit 1; }
[ -d "$ENTRANTE" ] || { echo "No llegaron los archivos del despliegue"; exit 1; }
for variable in PUERTO_API PUERTO_WEB; do
  [ -n "$(leer "$variable")" ] || { echo "Falta $variable en .env"; exit 1; }
done
imagen_anterior=$(podman container inspect --format '{{.Image}}' "$CONTENEDOR_API" 2> /dev/null || true)

# 2. Imagen nueva de la API: si no se puede descargar, no se cambia nada
token=""
[ -t 0 ] || token=$(cat)
if [ -n "$USUARIO_REGISTRO" ] && [ -n "$token" ]; then
  printf '%s' "$token" | podman login "$REGISTRO" -u "$USUARIO_REGISTRO" --password-stdin > /dev/null 2>&1 || true
fi
descargada=0
if podman image exists "$IMAGEN" || podman pull -q "$IMAGEN" > /dev/null 2>&1; then
  descargada=1
fi
podman logout "$REGISTRO" > /dev/null 2>&1 || true
if [ "$descargada" -ne 1 ]; then
  echo "No se pudo descargar la imagen nueva; no se cambió nada"
  exit 1
fi

# 3. Archivos que cambiaron (se guarda una copia temporal para poder volver atrás)
cp -p .env "$anteriores/.env"
cambiados=()
nuevos=()
while IFS= read -r -d '' origen; do
  ruta="${origen#"$ENTRANTE"/}"
  if [ -f "$ruta" ]; then
    cmp -s "$origen" "$ruta" && continue
    mkdir -p "$anteriores/$(dirname "$ruta")"
    cp -p "$ruta" "$anteriores/$ruta"
  else
    nuevos+=("$ruta")
    mkdir -p "$(dirname "$ruta")"
  fi
  cp "$origen" "$ruta"
  cambiados+=("$ruta")
done < <(find "$ENTRANTE" -type f -print0 | sort -z)

servicios=()
for ruta in ${cambiados[@]+"${cambiados[@]}"}; do
  echo "Actualizado: $ruta"
  case "$ruta" in
    docker-compose.yml) servicios+=(web prometheus blackbox alertmanager grafana) ;;
    monitoreo/nginx/*) servicios+=(web) ;;
    monitoreo/prometheus/*) servicios+=(prometheus) ;;
    monitoreo/blackbox/*) servicios+=(blackbox) ;;
    monitoreo/alertmanager/*) servicios+=(alertmanager) ;;
    monitoreo/grafana/*) servicios+=(grafana) ;;
    database/*) echo "  init.sql solo se aplica al crear la base; no se reinicia la base de datos" ;;
  esac
done
if [ ${#servicios[@]} -gt 0 ]; then
  mapfile -t servicios < <(printf '%s\n' "${servicios[@]}" | sort -u)
fi

volver() {
  echo "La API o la web no respondieron: se vuelve a la versión anterior"
  restaurar
  if [ -n "$imagen_anterior" ]; then
    fijar IMAGEN_API "$imagen_anterior"
  fi
  [ ${#servicios[@]} -eq 0 ] || compose up -d --no-deps --force-recreate "${servicios[@]}" || true
  compose up -d --no-deps --force-recreate api || true
  if responde; then
    echo "Se restauró la versión anterior"
  else
    echo "La versión anterior tampoco responde: revisar el servidor"
  fi
  exit 1
}

# 4. Reinicio de lo que cambió y de la API (sin tocar la base de datos)
fijar IMAGEN_API "$IMAGEN"
if [ ${#servicios[@]} -gt 0 ]; then
  echo "Reiniciando: ${servicios[*]}"
  compose up -d --no-deps --force-recreate "${servicios[@]}" || volver
fi
echo "Reiniciando: api"
compose up -d --no-deps --force-recreate api || volver
responde || volver
echo "Despliegue listo: la API y la web responden"

# 5. Se conservan las 3 imágenes más recientes de la API para poder volver atrás
podman images --format '{{.CreatedAt}}|{{.Repository}}:{{.Tag}}' |
  grep -F "|$REPOSITORIO_IMAGEN:" | sort -r | tail -n +4 | cut -d '|' -f 2 |
  while read -r vieja; do podman rmi "$vieja" > /dev/null 2>&1 || true; done
