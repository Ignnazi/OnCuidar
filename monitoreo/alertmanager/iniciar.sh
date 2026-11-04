#!/bin/sh
set -eu

: "${ALERTAS_CORREO:?definir ALERTAS_CORREO en .env}"
: "${ALERTAS_CLAVE:?definir ALERTAS_CLAVE en .env}"

# Las contraseñas de aplicación de Gmail se muestran con espacios
clave=$(printf '%s' "$ALERTAS_CLAVE" | tr -d ' ')

sed -e "s|__ALERTAS_CORREO__|$ALERTAS_CORREO|g" \
    -e "s|__ALERTAS_CLAVE__|$clave|g" \
    /etc/alertmanager/alertmanager.yml > /tmp/alertmanager.yml

exec /bin/alertmanager \
  --config.file=/tmp/alertmanager.yml \
  --storage.path=/alertmanager \
  --cluster.listen-address=
