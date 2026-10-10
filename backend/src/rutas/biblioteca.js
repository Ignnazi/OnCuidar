const express = require('express');
const db = require('../db');
const { requiereToken } = require('../auth');
const { iso } = require('../upsert');
const config = require('../config');
const { ErrorHttp, validarId } = require('../validacion');

const router = express.Router();
router.use(['/biblioteca', '/favoritos'], requiereToken);

const absoluta = (u) => (typeof u === 'string' && u.startsWith('/') ? `${config.urlPublica}${u}` : u);

const aJson = (m) => ({
  id: m.id,
  titulo: m.titulo,
  categoria: m.categoria,
  tema: m.tema,
  cuerpo: m.cuerpo,
  urlImagen: absoluta(m.url_imagen),
  urlArchivo: absoluta(m.url_archivo),
  urlMiniatura: absoluta(m.url_miniatura),
  tipoArchivo: m.tipo_archivo,
  tamanoBytes: m.tamano_bytes === null ? null : Number(m.tamano_bytes),
  creadoEn: iso(m.creado_en),
});

router.get('/biblioteca', async (_req, res) => {
  const { rows } = await db.consulta('SELECT * FROM material_educativo ORDER BY creado_en DESC, id');
  res.json(rows.map(aJson));
});

router.get('/biblioteca/:id', async (req, res) => {
  const { rows } = await db.consulta('SELECT * FROM material_educativo WHERE id = $1', [req.params.id]);
  if (!rows[0]) throw new ErrorHttp(404, 'Material no encontrado');
  res.json(aJson(rows[0]));
});

router.get('/favoritos', async (req, res) => {
  const { rows } = await db.consulta(
    'SELECT material_id FROM favoritos WHERE usuario_id = $1 ORDER BY creado_en, material_id', [req.uid]);
  res.json({ ids: rows.map((r) => r.material_id) });
});

router.put('/favoritos/:id', async (req, res) => {
  await db.consulta(
    'INSERT INTO favoritos (usuario_id, material_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [req.uid, validarId(req.params.id)]);
  res.json({ ok: true });
});

router.delete('/favoritos/:id', async (req, res) => {
  await db.consulta('DELETE FROM favoritos WHERE usuario_id = $1 AND material_id = $2',
    [req.uid, validarId(req.params.id)]);
  res.json({ ok: true });
});

module.exports = router;
