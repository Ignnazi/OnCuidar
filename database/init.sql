-- Esquema de OnCuidar
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS usuarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  correo text UNIQUE NOT NULL,
  contrasena_hash text,
  creado_en timestamptz DEFAULT now(),
  version_encriptacion int DEFAULT 2,
  cifrados jsonb DEFAULT '{}'::jsonb,
  correo_respaldo_hash text NULL,
  pendiente_correo text,
  pendiente_correo_tipo text,
  pendiente_correo_solicitado_en timestamptz,
  respaldo_pendiente_servidor boolean DEFAULT false
);
CREATE INDEX IF NOT EXISTS idx_usuarios_respaldo_hash ON usuarios (correo_respaldo_hash);

CREATE TABLE IF NOT EXISTS favoritos (
  usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  material_id text NOT NULL,
  creado_en timestamptz DEFAULT now(),
  PRIMARY KEY (usuario_id, material_id)
);

CREATE TABLE IF NOT EXISTS pacientes (
  usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  id text NOT NULL,
  notificaciones_activas boolean DEFAULT true,
  maximo_registros_dia int DEFAULT 3,
  archivado boolean DEFAULT false,
  creado_en timestamptz DEFAULT now(),
  version_encriptacion int,
  cifrados jsonb DEFAULT '{}'::jsonb,
  PRIMARY KEY (usuario_id, id)
);

CREATE TABLE IF NOT EXISTS registros_clinicos (
  usuario_id uuid NOT NULL,
  paciente_id text NOT NULL,
  id text NOT NULL,
  fecha timestamptz,
  creado_en timestamptz DEFAULT now(),
  tipo_registro text,
  nivel_alerta text,
  version_encriptacion int,
  cifrados jsonb DEFAULT '{}'::jsonb,
  PRIMARY KEY (usuario_id, paciente_id, id),
  FOREIGN KEY (usuario_id, paciente_id) REFERENCES pacientes(usuario_id, id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_registros_creado ON registros_clinicos (usuario_id, paciente_id, creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_registros_fecha ON registros_clinicos (usuario_id, paciente_id, fecha);

CREATE TABLE IF NOT EXISTS recordatorios (
  usuario_id uuid NOT NULL,
  paciente_id text NOT NULL,
  id text NOT NULL,
  activo boolean DEFAULT true,
  creado_en timestamptz DEFAULT now(),
  version_encriptacion int,
  cifrados jsonb DEFAULT '{}'::jsonb,
  PRIMARY KEY (usuario_id, paciente_id, id),
  FOREIGN KEY (usuario_id, paciente_id) REFERENCES pacientes(usuario_id, id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_recordatorios_creado ON recordatorios (usuario_id, paciente_id, creado_en DESC);

CREATE TABLE IF NOT EXISTS conversaciones (
  usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  id text NOT NULL,
  ultima_actividad timestamptz,
  creado_en timestamptz DEFAULT now(),
  version_encriptacion int,
  cifrados jsonb DEFAULT '{}'::jsonb,
  PRIMARY KEY (usuario_id, id)
);
CREATE INDEX IF NOT EXISTS idx_conversaciones_actividad ON conversaciones (usuario_id, ultima_actividad DESC);

CREATE TABLE IF NOT EXISTS material_educativo (
  id text PRIMARY KEY,
  titulo text,
  categoria text,
  tema text,
  cuerpo text,
  url_imagen text,
  url_archivo text,
  url_miniatura text,
  tipo_archivo text NULL,
  tamano_bytes bigint NULL,
  creado_en timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS claves_datos (
  usuario_id uuid PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  clave_sellada text NOT NULL,
  creado_en timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS esperas_recuperacion (
  hash text PRIMARY KEY,
  ultimo_envio_en timestamptz
);

CREATE TABLE IF NOT EXISTS tokens_restablecer (
  token_hash text PRIMARY KEY,
  usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  expira_en timestamptz NOT NULL,
  usado boolean DEFAULT false
);
