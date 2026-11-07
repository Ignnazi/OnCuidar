const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');
const db = require('../src/db');

const CARPETA_ARCHIVOS = path.join(__dirname, '..', 'archivos');
const CARPETA_MINIATURAS = path.join(CARPETA_ARCHIVOS, 'miniaturas');

const ARCHIVO = path.join(__dirname, 'material_educativo.json');

const generarId = (titulo) => titulo
  .normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 100);

async function asegurarMiniatura(urlVideo) {
  const nombre = path.basename(urlVideo, path.extname(urlVideo)) + '.jpg';
  const salida = path.join(CARPETA_MINIATURAS, nombre);
  if (!fs.existsSync(salida)) {
    const entrada = path.join(CARPETA_ARCHIVOS, urlVideo.slice('/archivos/'.length));
    if (!fs.existsSync(entrada)) return null;
    fs.mkdirSync(CARPETA_MINIATURAS, { recursive: true });
    const generar = (segundo) => new Promise((resolver) => execFile('ffmpeg',
      ['-y', '-loglevel', 'error', '-ss', String(segundo), '-i', entrada, '-frames:v', '1', '-vf', 'scale=640:-2', '-q:v', '4', salida],
      (error) => resolver(!error && fs.existsSync(salida))));
    if (!(await generar(2)) && !(await generar(0))) {
      console.warn(`[material] no se pudo sacar la miniatura de ${urlVideo}`);
      return null;
    }
  }
  return '/archivos/miniaturas/' + nombre;
}

async function asegurarMiniaturas() {
  const { rows } = await db.consulta("SELECT id, url_archivo FROM material_educativo WHERE tipo_archivo = 'video' AND url_archivo IS NOT NULL");
  for (const fila of rows) {
    const miniatura = await asegurarMiniatura(fila.url_archivo);
    if (miniatura) await db.consulta('UPDATE material_educativo SET url_miniatura = $2 WHERE id = $1 AND url_miniatura IS DISTINCT FROM $2', [fila.id, miniatura]);
  }
}

async function cargarMaterial() {
  const lista = JSON.parse(fs.readFileSync(ARCHIVO, 'utf8'));
  const ids = lista.map((m) => m.id ?? generarId(m.titulo));
  for (const [i, m] of lista.entries()) {
    await db.consulta(
      `INSERT INTO material_educativo
         (id, titulo, categoria, tema, cuerpo, url_imagen, url_archivo, url_miniatura, tipo_archivo, tamano_bytes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       ON CONFLICT (id) DO UPDATE SET titulo = EXCLUDED.titulo, categoria = EXCLUDED.categoria,
         tema = EXCLUDED.tema, cuerpo = EXCLUDED.cuerpo, url_imagen = EXCLUDED.url_imagen,
         url_archivo = EXCLUDED.url_archivo, url_miniatura = EXCLUDED.url_miniatura,
         tipo_archivo = EXCLUDED.tipo_archivo, tamano_bytes = EXCLUDED.tamano_bytes`,
      [ids[i], m.titulo, m.categoria ?? null, m.tema ?? null, m.cuerpo ?? null,
        m.urlImagen ?? null, m.urlArchivo ?? null, m.urlMiniatura ?? null, m.tipoArchivo ?? null,
        m.tamanoBytes ?? null],
    );
  }
  // Se quita lo que ya no está en el JSON
  const { rowCount } = await db.consulta('DELETE FROM material_educativo WHERE NOT (id = ANY($1))', [ids]);
  if (rowCount > 0) console.log(`[material] ${rowCount} materiales retirados`);
  await asegurarMiniaturas();
  return lista.length;
}

async function sincronizarMaterial() {
  const n = await cargarMaterial();
  console.log(`[material] ${n} materiales sincronizados`);
}

module.exports = { cargarMaterial, sincronizarMaterial, generarId };

if (require.main === module) {
  cargarMaterial()
    .then((n) => { console.log(`${n} materiales cargados`); return db.pool.end(); })
    .catch((e) => { console.error(e); process.exit(1); });
}
