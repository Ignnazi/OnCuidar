const express = require('express');
const db = require('../db');
const { requiereToken } = require('../auth');
const { upsert, iso } = require('../upsert');
const {
  ErrorHttp, cuerpoObjeto, rechazarEnClaro, leerCifrados, fechaOpcional, enteroOpcional, validarId, limite,
} = require('../validacion');

const router = express.Router();
router.use('/conversaciones', requiereToken);

const aJson = (c) => ({
  id: c.id,
  ultimaActividad: iso(c.ultima_actividad),
  creadoEn: iso(c.creado_en),
  versionEncriptacion: c.version_encriptacion,
  cifrados: c.cifrados ?? {},
});

router.get('/conversaciones', async (req, res) => {
  const { rows } = await db.consulta(
    `SELECT * FROM conversaciones WHERE usuario_id = $1
     ORDER BY ultima_actividad DESC NULLS LAST, id DESC LIMIT $2`,
    [req.uid, limite(req.query.limite, 50)]);
  res.json(rows.map(aJson));
});

router.put('/conversaciones/:id', async (req, res) => {
  const id = validarId(req.params.id);
  const cuerpo = cuerpoObjeto(req);
  rechazarEnClaro(cuerpo, 'conversaciones');
  const fila = await upsert({
    tabla: 'conversaciones',
    claves: { usuario_id: req.uid, id },
    campos: {
      ultima_actividad: fechaOpcional(cuerpo.ultimaActividad, 'ultimaActividad', { nulaPermitida: true }),
      creado_en: fechaOpcional(cuerpo.creadoEn, 'creadoEn'),
      version_encriptacion: enteroOpcional(cuerpo.versionEncriptacion, 'versionEncriptacion'),
    },
    cifrados: leerCifrados(cuerpo),
  });
  res.json(aJson(fila));
});

router.delete('/conversaciones/:id', async (req, res) => {
  const { rowCount } = await db.consulta('DELETE FROM conversaciones WHERE usuario_id = $1 AND id = $2',
    [req.uid, validarId(req.params.id)]);
  if (!rowCount) throw new ErrorHttp(404, 'Conversación no encontrada');
  res.json({ ok: true });
});

module.exports = router;
