#!/usr/bin/env bash
# Revisa si hay una versión nueva publicada por el CI y, si la hay, la despliega.
# Lo ejecuta cron en el servidor cada 5 minutos (ver docs/despliegue.md).
#
# El firewall de la universidad no deja entrar conexiones SSH desde GitHub, así que es
# el servidor el que sale a buscar el paquete de despliegue al registro de imágenes.
# El paquete trae la configuración, la página, el APK y el nombre de la imagen de la API.
#
# Todo va dentro de main: un despliegue puede reemplazar este mismo archivo mientras corre,
# y así bash ya lo leyó completo antes de empezar.
set -euo pipefail

main() {
  local carpeta="${CARPETA_ONCUIDAR:-$HOME/oncuidar}"
  local paquete_imagen="${PAQUETE_DESPLIEGUE:-ghcr.io/ignnazi/oncuidar-despliegue:main}"
  # cron arranca con un PATH mínimo; se agregan al final para no tapar lo que ya esté
  export PATH="$PATH:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

  cd "$carpeta"

  # Nunca dos revisiones a la vez (un despliegue puede tardar más de 5 minutos)
  exec 9> .actualizar.lock
  flock -n 9 || return 0

  # Registro propio: al pasar de 2000 líneas se deja en las últimas 1000
  local registro="$carpeta/actualizar.log"
  if [ -f "$registro" ] && [ "$(wc -l < "$registro")" -gt 2000 ]; then
    tail -n 1000 "$registro" > "$registro.tmp" && mv "$registro.tmp" "$registro"
  fi
  exec >> "$registro" 2>&1

  # Sin novedades no se escribe nada en el registro
  if ! podman pull -q "$paquete_imagen" > /dev/null 2>&1; then
    echo "$(fecha) No se pudo consultar el paquete de despliegue"
    return 0
  fi
  local paquete
  paquete=$(podman image inspect --format '{{.Id}}' "$paquete_imagen")
  [ "$paquete" = "$(cat .paquete-desplegado 2> /dev/null)" ] && return 0
  # Una versión que ya falló no se reintenta: se espera la siguiente
  [ "$paquete" = "$(cat .paquete-fallido 2> /dev/null)" ] && return 0

  rm -rf .despliegue
  mkdir .despliegue
  local contenedor
  contenedor=$(podman create "$paquete_imagen" true)
  if ! podman cp "$contenedor:/despliegue/." .despliegue/ > /dev/null; then
    podman rm "$contenedor" > /dev/null 2>&1 || true
    echo "$(fecha) No se pudo extraer el paquete; se reintenta en la próxima revisión"
    return 0
  fi
  podman rm "$contenedor" > /dev/null
  local imagen
  imagen=$(cat .despliegue/IMAGEN_API)
  rm .despliegue/IMAGEN_API

  echo "$(fecha) Desplegando $imagen"
  if bash .despliegue/scripts/desplegar.sh "$imagen" < /dev/null; then
    echo "$paquete" > .paquete-desplegado
    rm -f .paquete-fallido
  else
    echo "$paquete" > .paquete-fallido
    echo "$(fecha) El despliegue falló; se mantiene la versión anterior"
  fi
  podman image prune -f > /dev/null 2>&1 || true
}

fecha() { date '+%Y-%m-%d %H:%M:%S'; }

# En la misma línea: bash la lee completa antes de ejecutar main
main "$@"; exit $?
