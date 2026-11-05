#!/usr/bin/env bash
# Pruebas de scripts/actualizar.sh con podman y flock simulados.
# Uso: bash test/despliegue/actualizar_test.sh
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$RAIZ/scripts/actualizar.sh"
IMAGEN="ghcr.io/ejemplo/oncuidar-api:abc123"
fallos=0

preparar() {
  TMP=$(mktemp -d)
  CARPETA="$TMP/oncuidar"
  BIN="$TMP/bin"
  PAQUETE="$TMP/paquete"
  LLAMADAS="$TMP/llamadas.log"
  mkdir -p "$CARPETA" "$BIN" "$PAQUETE/despliegue/scripts"
  echo "$IMAGEN" > "$PAQUETE/despliegue/IMAGEN_API"
  echo "compose" > "$PAQUETE/despliegue/docker-compose.yml"
  # desplegar.sh simulado: anota con qué se llamó y falla si FALLA_DESPLIEGUE está definida
  cat > "$PAQUETE/despliegue/scripts/desplegar.sh" << EOF
echo "desplegar \$* IMAGEN_API_en_paquete=\$([ -e .despliegue/IMAGEN_API ] && echo si || echo no)" >> "$LLAMADAS"
# En Linux revisa si este proceso recibió abierto el archivo del candado
if ls -l /proc/\$\$/fd 2> /dev/null | grep -q -E "actualizar.(candado|lock)"; then echo "HEREDA_CANDADO" >> "$LLAMADAS"; fi
# Simula un despliegue que trae una versión nueva de actualizar.sh, de otro largo
if [ -n "\${SOBRESCRIBE:-}" ]; then
  for i in \$(seq 1 300); do echo "echo BASURA_\$i >> $LLAMADAS"; done > scripts/actualizar.sh
fi
[ -z "\${FALLA_DESPLIEGUE:-}" ]
EOF

  cat > "$BIN/podman" << EOF
#!/usr/bin/env bash
echo "podman \$*" >> "$LLAMADAS"
case "\$1" in
  pull) [ -z "\${FALLA_PULL:-}" ] ;;
  image) echo "\${ID_PAQUETE:-sha256:paquete1}" ;;
  create) echo "contenedor1" ;;
  cp) [ -z "\${FALLA_CP:-}" ] || exit 1; cp -r "$PAQUETE/despliegue/." "\$3" ;;
esac
EOF
  # Se usa el flock real si existe (Linux). Si no, uno simulado que ejecuta el comando
  if ! command -v flock > /dev/null; then
    cat > "$BIN/flock" << 'EOF'
#!/usr/bin/env bash
while [ "${1#-}" != "$1" ]; do
  [ "$1" = "-E" ] && shift
  shift
done
[ -n "${CANDADO_OCUPADO:-}" ] && exit 0
shift
exec "$@"
EOF
  fi
  chmod +x "$BIN"/*
  # Se ejecuta una copia, como en el servidor, para que un despliegue pueda reemplazarla
  mkdir -p "$CARPETA/scripts"
  cp "$SCRIPT" "$CARPETA/scripts/actualizar.sh"
}

ejecutar() {
  (cd "$TMP" && PATH="$BIN:$PATH" CARPETA_ONCUIDAR="$CARPETA" PAQUETE_DESPLIEGUE=ghcr.io/ejemplo/paquete:main \
    "$@" bash "$CARPETA/scripts/actualizar.sh" > "$TMP/salida.txt" 2>&1)
  ESTADO=$?
  REGISTRO_TXT=$(cat "$CARPETA/actualizar.log" 2> /dev/null)
}

comprobar() {
  local descripcion="$1"
  shift
  if "$@"; then
    echo "  ok   $descripcion"
  else
    echo "  FALLA $descripcion"
    fallos=$((fallos + 1))
  fi
}

contiene() { grep -qF -- "$2" "$1"; }
no_contiene() { ! grep -qF -- "$2" "$1" 2> /dev/null; }

echo "Hay una versión nueva"
preparar
ejecutar env
comprobar "termina sin error" [ "$ESTADO" -eq 0 ]
comprobar "despliega la imagen que indica el paquete" contiene "$LLAMADAS" "desplegar $IMAGEN"
comprobar "no deja IMAGEN_API entre los archivos a copiar" contiene "$LLAMADAS" "IMAGEN_API_en_paquete=no"
comprobar "anota la versión desplegada" contiene "$CARPETA/.paquete-desplegado" "sha256:paquete1"
comprobar "deja constancia en el registro" contiene <(echo "$REGISTRO_TXT") "Desplegando $IMAGEN"
comprobar "borra el contenedor temporal" contiene "$LLAMADAS" "podman rm contenedor1"
comprobar "no escribe en la salida de cron" [ ! -s "$TMP/salida.txt" ]
comprobar "el despliegue no hereda el candado" no_contiene "$LLAMADAS" "HEREDA_CANDADO"
rm -rf "$TMP"

echo "La versión ya está desplegada"
preparar
echo "sha256:paquete1" > "$CARPETA/.paquete-desplegado"
ejecutar env
comprobar "termina sin error" [ "$ESTADO" -eq 0 ]
comprobar "no despliega" no_contiene "$LLAMADAS" "desplegar"
comprobar "no escribe en el registro" [ -z "$REGISTRO_TXT" ]
rm -rf "$TMP"

echo "El despliegue falla"
preparar
ejecutar env FALLA_DESPLIEGUE=1
comprobar "termina sin error para cron" [ "$ESTADO" -eq 0 ]
comprobar "anota la versión fallida" contiene "$CARPETA/.paquete-fallido" "sha256:paquete1"
comprobar "no la marca como desplegada" [ ! -e "$CARPETA/.paquete-desplegado" ]
comprobar "lo deja en el registro" contiene <(echo "$REGISTRO_TXT") "El despliegue falló"
rm -f "$LLAMADAS"
ejecutar env
comprobar "no reintenta la misma versión" no_contiene "$LLAMADAS" "desplegar"
rm -f "$LLAMADAS"
ejecutar env ID_PAQUETE=sha256:paquete2
comprobar "sí despliega la versión siguiente" contiene "$LLAMADAS" "desplegar $IMAGEN"
comprobar "olvida la versión fallida" [ ! -e "$CARPETA/.paquete-fallido" ]
rm -rf "$TMP"

echo "No se puede consultar el registro de imágenes"
preparar
ejecutar env FALLA_PULL=1
comprobar "termina sin error para cron" [ "$ESTADO" -eq 0 ]
comprobar "no despliega" no_contiene "$LLAMADAS" "desplegar"
comprobar "lo deja en el registro" contiene <(echo "$REGISTRO_TXT") "No se pudo consultar"
rm -rf "$TMP"

echo "El despliegue reemplaza este mismo script"
preparar
ejecutar env SOBRESCRIBE=1
comprobar "termina sin error" [ "$ESTADO" -eq 0 ]
comprobar "no ejecuta trozos de la versión nueva" no_contiene "$LLAMADAS" "BASURA"
comprobar "anota la versión desplegada" contiene "$CARPETA/.paquete-desplegado" "sha256:paquete1"
rm -rf "$TMP"

echo "Falla la extracción del paquete"
preparar
ejecutar env FALLA_CP=1
comprobar "termina sin error para cron" [ "$ESTADO" -eq 0 ]
comprobar "borra el contenedor temporal" contiene "$LLAMADAS" "podman rm contenedor1"
comprobar "no despliega" no_contiene "$LLAMADAS" "desplegar"
comprobar "no la marca como fallida (se reintenta)" [ ! -e "$CARPETA/.paquete-fallido" ]
comprobar "lo deja en el registro" contiene <(echo "$REGISTRO_TXT") "No se pudo extraer el paquete"
rm -rf "$TMP"

echo "Otra revisión tiene el candado"
preparar
if command -v flock > /dev/null; then
  flock "$CARPETA/.actualizar.candado" sleep 5 &
  sleep 1
  ejecutar env
  wait
else
  ejecutar env CANDADO_OCUPADO=1
fi
comprobar "termina sin error para cron" [ "$ESTADO" -eq 0 ]
comprobar "no despliega" no_contiene "$LLAMADAS" "desplegar"
rm -rf "$TMP"

echo "El registro crece demasiado"
preparar
echo "sha256:paquete1" > "$CARPETA/.paquete-desplegado"
seq 1 2500 > "$CARPETA/actualizar.log"
ejecutar env
comprobar "se recorta a las últimas 1000 líneas" [ "$(wc -l < "$CARPETA/actualizar.log")" -eq 1000 ]
comprobar "conserva lo más reciente" contiene "$CARPETA/actualizar.log" "2500"
rm -rf "$TMP"

if [ "$fallos" -gt 0 ]; then
  echo "$fallos comprobaciones fallaron"
  exit 1
fi
echo "Todas las comprobaciones pasaron"
