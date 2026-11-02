#!/usr/bin/env bash
# Respaldo comprimido de la base de datos de producción.
# Variables opcionales: MOTOR (podman o docker), CONTENEDOR, DESTINO, DIAS.
set -euo pipefail

MOTOR="${MOTOR:-podman}"
CONTENEDOR="${CONTENEDOR:-oncuidar_db_1}"
DESTINO="${DESTINO:-$HOME/respaldos-oncuidar}"
DIAS="${DIAS:-14}"

mkdir -p "$DESTINO"
archivo="$DESTINO/oncuidar-$(date +%Y%m%d-%H%M).sql.gz"
temporal="$archivo.parcial"
trap 'rm -f "$temporal"' EXIT

"$MOTOR" exec "$CONTENEDOR" sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip > "$temporal"
mv "$temporal" "$archivo"

find "$DESTINO" -name 'oncuidar-*.sql.gz' -mtime +"$DIAS" -delete

echo "Respaldo creado: $archivo"
