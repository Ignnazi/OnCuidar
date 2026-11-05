#!/usr/bin/env bash
# Pruebas de scripts/desplegar.sh con podman, podman-compose y curl simulados.
# Uso: bash test/despliegue/desplegar_test.sh
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$RAIZ/scripts/desplegar.sh"
IMAGEN="ghcr.io/ejemplo/oncuidar-api:abc123"
fallos=0

preparar() {
  TMP=$(mktemp -d)
  CARPETA="$TMP/oncuidar"
  BIN="$TMP/bin"
  REGISTRO="$TMP/llamadas.log"
  mkdir -p "$CARPETA/monitoreo/nginx" "$CARPETA/web" "$BIN"
  printf 'POSTGRES_PASSWORD=x\nPUERTO_API=8014\nPUERTO_WEB=8015\n' > "$CARPETA/.env"
  echo "compose viejo" > "$CARPETA/docker-compose.yml"
  echo "nginx viejo" > "$CARPETA/monitoreo/nginx/default.conf.template"
  echo "apk viejo" > "$CARPETA/web/OnCuidar.apk"
  mkdir -p "$CARPETA/.despliegue/monitoreo/nginx" "$CARPETA/.despliegue/web" "$CARPETA/.despliegue/database"
  echo "compose viejo" > "$CARPETA/.despliegue/docker-compose.yml"
  echo "nginx nuevo" > "$CARPETA/.despliegue/monitoreo/nginx/default.conf.template"
  echo "apk nuevo" > "$CARPETA/.despliegue/web/OnCuidar.apk"
  echo "esquema" > "$CARPETA/.despliegue/database/init.sql"

  cat > "$BIN/podman" << EOF
#!/usr/bin/env bash
echo "podman \$*" >> "$REGISTRO"
case "\$1" in
  container) echo "sha256:imagenanterior" ;;
  image) [ -n "\${YA_EXISTE:-}" ] ;;
  login) cat > /dev/null; [ -z "\${FALLA_LOGIN:-}" ] || exit 1 ;;
  pull) [ -z "\${FALLA_PULL:-}\${FALLA_LOGIN:-}" ] || exit 1 ;;
  images)
    echo "2026-11-01 10:00:00 +0000 UTC|ghcr.io/ejemplo/oncuidar-api:a1"
    echo "2026-11-02 10:00:00 +0000 UTC|ghcr.io/ejemplo/oncuidar-api:a2"
    echo "2026-11-03 10:00:00 +0000 UTC|ghcr.io/ejemplo/oncuidar-api:a3"
    echo "2026-11-04 10:00:00 +0000 UTC|ghcr.io/ejemplo/oncuidar-api:abc123"
    echo "2026-10-01 10:00:00 +0000 UTC|docker.io/library/postgres:15"
    ;;
esac
EOF
  cat > "$BIN/podman-compose" << EOF
#!/usr/bin/env bash
echo "podman-compose \$* IMAGEN_API=\$(sed -n 's/^IMAGEN_API=//p' .env)" >> "$REGISTRO"
# Igual que el real, muestra las variables de entorno de cada contenedor
echo "podman run -e GF_SECURITY_ADMIN_PASSWORD=clave-del-env"
if [ -n "\${FALLA_WEB:-}" ] && [[ " \$* " == *" web "* ]]; then exit 1; fi
EOF
  # La API responde solo con la imagen anterior si FALLA_API está definida
  cat > "$BIN/curl" << EOF
#!/usr/bin/env bash
if [ -n "\${FALLA_API:-}" ] && grep -q "^IMAGEN_API=$IMAGEN" "$CARPETA/.env"; then exit 7; fi
exit 0
EOF
  chmod +x "$BIN"/*
}

ejecutar() {
  SALIDA=$(cd "$TMP" && printf 'token-secreto' | PATH="$BIN:$PATH" CARPETA_ONCUIDAR="$CARPETA" \
    INTENTOS_SALUD=2 ESPERA_SALUD=0 "$@" bash "$SCRIPT" "$IMAGEN" usuario 2>&1)
  ESTADO=$?
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
no_contiene() { ! grep -qF -- "$2" "$1"; }

echo "Despliegue correcto"
preparar
ejecutar env
comprobar "termina sin error" [ "$ESTADO" -eq 0 ]
comprobar "fija la imagen nueva en .env" contiene "$CARPETA/.env" "IMAGEN_API=$IMAGEN"
comprobar "conserva el resto del .env" contiene "$CARPETA/.env" "POSTGRES_PASSWORD=x"
comprobar "copia la plantilla de nginx" contiene "$CARPETA/monitoreo/nginx/default.conf.template" "nginx nuevo"
comprobar "publica el APK" contiene "$CARPETA/web/OnCuidar.apk" "apk nuevo"
comprobar "reinicia web porque cambió nginx" contiene "$REGISTRO" "podman-compose up -d --no-deps --force-recreate web"
comprobar "no reinicia grafana si su configuración no cambió" no_contiene "$REGISTRO" "grafana"
comprobar "recrea la API con la imagen nueva" contiene "$REGISTRO" "--force-recreate api IMAGEN_API=$IMAGEN"
comprobar "nunca toca la base de datos" no_contiene "$REGISTRO" " db"
comprobar "inicia sesión en el registro" contiene "$REGISTRO" "podman login ghcr.io -u usuario --password-stdin"
comprobar "no muestra el token" no_contiene <(echo "$SALIDA") "token-secreto"
comprobar "no muestra variables del .env" no_contiene <(echo "$SALIDA") "clave-del-env"
comprobar "borra las imágenes viejas de la API" contiene "$REGISTRO" "podman rmi ghcr.io/ejemplo/oncuidar-api:a1"
comprobar "conserva las 3 más recientes" no_contiene "$REGISTRO" "podman rmi ghcr.io/ejemplo/oncuidar-api:a2"
comprobar "no borra imágenes de otros servicios" no_contiene "$REGISTRO" "postgres"
comprobar "borra la carpeta temporal del despliegue" [ ! -e "$CARPETA/.despliegue" ]
comprobar "no deja respaldos en el servidor" [ -z "$(find "$CARPETA" -name '*.antes*' -o -name '*.bak')" ]
rm -rf "$TMP"

echo "La API nueva no responde"
preparar
ejecutar env FALLA_API=1
comprobar "termina con error" [ "$ESTADO" -ne 0 ]
comprobar "avisa que vuelve atrás" contiene <(echo "$SALIDA") "se vuelve a la versión anterior"
comprobar "vuelve a la imagen anterior" contiene "$CARPETA/.env" "IMAGEN_API=sha256:imagenanterior"
comprobar "restaura la plantilla de nginx" contiene "$CARPETA/monitoreo/nginx/default.conf.template" "nginx viejo"
comprobar "restaura el APK" contiene "$CARPETA/web/OnCuidar.apk" "apk viejo"
comprobar "quita los archivos que no existían" [ ! -e "$CARPETA/database/init.sql" ]
comprobar "confirma que la versión anterior responde" contiene <(echo "$SALIDA") "Se restauró la versión anterior"
rm -rf "$TMP"

echo "La imagen nueva no se puede descargar"
preparar
ejecutar env FALLA_PULL=1
comprobar "termina con error" [ "$ESTADO" -ne 0 ]
comprobar "no reinicia nada" no_contiene "$REGISTRO" "podman-compose"
comprobar "deja el .env como estaba" no_contiene "$CARPETA/.env" "IMAGEN_API"
comprobar "deja los archivos como estaban" contiene "$CARPETA/web/OnCuidar.apk" "apk viejo"
rm -rf "$TMP"

echo "La imagen ya está en el servidor"
preparar
ejecutar env YA_EXISTE=1
comprobar "termina sin error" [ "$ESTADO" -eq 0 ]
comprobar "no la vuelve a descargar" no_contiene "$REGISTRO" "podman pull"
comprobar "la usa en la API" contiene "$REGISTRO" "--force-recreate api IMAGEN_API=$IMAGEN"
rm -rf "$TMP"

echo "Falla el inicio de sesión en el registro"
preparar
ejecutar env FALLA_LOGIN=1
comprobar "termina con error" [ "$ESTADO" -ne 0 ]
comprobar "avisa que no cambió nada" contiene <(echo "$SALIDA") "no se cambió nada"
comprobar "no toca los archivos" contiene "$CARPETA/web/OnCuidar.apk" "apk viejo"
comprobar "no deja archivos nuevos" [ ! -e "$CARPETA/database/init.sql" ]
comprobar "no reinicia nada" no_contiene "$REGISTRO" "podman-compose"
rm -rf "$TMP"

echo "Falla el reinicio de la web"
preparar
ejecutar env FALLA_WEB=1
comprobar "termina con error" [ "$ESTADO" -ne 0 ]
comprobar "explica qué falló" contiene <(echo "$SALIDA") "podman-compose falló"
comprobar "no muestra variables del .env" no_contiene <(echo "$SALIDA") "clave-del-env"
comprobar "restaura la plantilla de nginx" contiene "$CARPETA/monitoreo/nginx/default.conf.template" "nginx viejo"
comprobar "vuelve a la imagen anterior" contiene "$CARPETA/.env" "IMAGEN_API=sha256:imagenanterior"
comprobar "guarda el detalle solo en el servidor" contiene "$CARPETA/despliegue.log" "clave-del-env"
rm -rf "$TMP"

echo "Falta un puerto en .env"
preparar
sed -i '/^PUERTO_API=/d' "$CARPETA/.env"
ejecutar env
comprobar "termina con error" [ "$ESTADO" -ne 0 ]
comprobar "explica qué falta" contiene <(echo "$SALIDA") "Falta PUERTO_API en .env"
comprobar "no toca ningún archivo" contiene "$CARPETA/web/OnCuidar.apk" "apk viejo"
comprobar "no llama a podman" [ ! -e "$REGISTRO" ]
rm -rf "$TMP"

if [ "$fallos" -gt 0 ]; then
  echo "$fallos comprobaciones fallaron"
  exit 1
fi
echo "Todas las comprobaciones pasaron"
