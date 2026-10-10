const fs = require('fs');
const path = require('path');
const db = require('../src/db');

const ARCHIVO = path.join(__dirname, 'material_educativo.json');

const generarId = (titulo) => titulo
  .normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 100);

async function cargarMaterial() {
  const lista = JSON.parse(fs.readFileSync(ARCHIVO, 'utf8'));
  for (const m of lista) {
    await db.consulta(
      `INSERT INTO material_educativo
         (id, titulo, categoria, tema, cuerpo, url_imagen, url_archivo, url_miniatura, tipo_archivo, tamano_bytes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       ON CONFLICT (id) DO UPDATE SET titulo = EXCLUDED.titulo, categoria = EXCLUDED.categoria,
         tema = EXCLUDED.tema, cuerpo = EXCLUDED.cuerpo, url_imagen = EXCLUDED.url_imagen,
         url_archivo = EXCLUDED.url_archivo, url_miniatura = EXCLUDED.url_miniatura,
         tipo_archivo = EXCLUDED.tipo_archivo, tamano_bytes = EXCLUDED.tamano_bytes`,
      [m.id ?? generarId(m.titulo), m.titulo, m.categoria ?? null, m.tema ?? null, m.cuerpo ?? null,
        m.urlImagen ?? null, m.urlArchivo ?? null, m.urlMiniatura ?? null, m.tipoArchivo ?? null,
        m.tamanoBytes ?? null],
    );
  }
  return lista.length;
}

async function cargarSiVacia() {
  const { rows } = await db.consulta('SELECT count(*)::int AS n FROM material_educativo');
  if (rows[0].n === 0) {
    const n = await cargarMaterial();
    console.log(`[material] ${n} materiales cargados`);
  }
}

module.exports = { cargarMaterial, cargarSiVacia };

if (require.main === module) {
  cargarMaterial()
    .then((n) => { console.log(`${n} materiales cargados`); return db.pool.end(); })
    .catch((e) => { console.error(e); process.exit(1); });
}
