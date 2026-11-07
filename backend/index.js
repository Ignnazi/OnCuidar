const config = require('./src/config');

config.validar();

const app = require('./src/app');
const db = require('./src/db');
const { sincronizarMaterial } = require('./scripts/cargar_material');

// init.sql solo corre en una base nueva, esta tabla llego despues
const TABLA_PACIENTES_BORRADOS = `
CREATE TABLE IF NOT EXISTS pacientes_borrados (
  usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  id text NOT NULL,
  borrado_en timestamptz DEFAULT now(),
  PRIMARY KEY (usuario_id, id)
);`;

async function iniciar() {
  try {
    await db.consulta(TABLA_PACIENTES_BORRADOS);
  } catch (e) {
    console.error('[esquema] no se pudo crear pacientes_borrados:', e.message);
  }
  try {
    await sincronizarMaterial();
  } catch (e) {
    console.error('[material] no se pudo cargar:', e.message);
  }
  app.listen(config.puerto, () => console.log(`API de OnCuidar escuchando en el puerto ${config.puerto}`));
}

iniciar();
