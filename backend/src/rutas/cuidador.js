const express = require('express');
const db = require('../db');
const { requiereToken } = require('../auth');
const { iso } = require('../upsert');
const { ErrorHttp, cuerpoObjeto, rechazarEnClaro, leerCifrados, enteroOpcional } = require('../validacion');

const router = express.Router();
router.use('/cuidador', requiereToken);

const aJson = (u) => ({
  id: u.id,
  correo: u.correo,
  creadoEn: iso(u.creado_en),
  versionEncriptacion: u.version_encriptacion,
  cifrados: u.cifrados ?? {},
  pendienteCorreo: u.pendiente_correo,
  pendienteCorreoTipo: u.pendiente_correo_tipo,
  pendienteCorreoSolicitadoEn: iso(u.pendiente_correo_solicitado_en),
  respaldoPendiente: u.respaldo_pendiente_servidor === true,
  respaldoPendienteServidor: u.respaldo_pendiente_servidor,
  correoVerificado: u.correo_verificado === true,
  correoRespaldoVerificado: u.correo_respaldo_hash != null,
});

router.get('/cuidador', async (req, res) => {
  const { rows } = await db.consulta('SELECT * FROM usuarios WHERE id = $1', [req.uid]);
  if (!rows[0]) throw new ErrorHttp(404, 'Cuidador no encontrado');
  res.json(aJson(rows[0]));
});

router.put('/cuidador', async (req, res) => {
  const cuerpo = cuerpoObjeto(req);
  rechazarEnClaro(cuerpo, 'usuario');
  const { poner, borrar } = leerCifrados(cuerpo);
  const campos = {
    version_encriptacion: enteroOpcional(cuerpo.versionEncriptacion, 'versionEncriptacion'),
  };
  const sets = [];
  const params = [req.uid];
  for (const [col, val] of Object.entries(campos)) {
    if (val === undefined) continue;
    params.push(val);
    sets.push(`${col} = $${params.length}`);
  }
  params.push(JSON.stringify(poner), borrar);
  sets.push(`cifrados = (COALESCE(cifrados, '{}'::jsonb) || $${params.length - 1}::jsonb) - $${params.length}::text[]`);
  const { rows } = await db.consulta(`UPDATE usuarios SET ${sets.join(', ')} WHERE id = $1 RETURNING *`, params);
  if (!rows[0]) throw new ErrorHttp(404, 'Cuidador no encontrado');
  res.json(aJson(rows[0]));
});

module.exports = router;
