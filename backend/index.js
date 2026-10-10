const config = require('./src/config');

config.validar();

const app = require('./src/app');
const { cargarSiVacia } = require('./scripts/cargar_material');

async function iniciar() {
  try {
    await cargarSiVacia();
  } catch (e) {
    console.error('[material] no se pudo cargar:', e.message);
  }
  app.listen(config.puerto, () => console.log(`API de OnCuidar escuchando en el puerto ${config.puerto}`));
}

iniciar();
