const express = require('express');
const db = require('../db');
const { requiereToken } = require('../auth');
const { upsert, iso } = require('../upsert');
const {
  ErrorHttp, cuerpoObjeto, rechazarEnClaro, leerCifrados, fechaOpcional, booleanoOpcional,
  enteroOpcional, textoOpcional, validarId, limite,
} = require('../validacion');

const router = express.Router();
router.use('/pacientes', requiereToken);

const pacienteAJson = (p) => ({
  id: p.id,
  notificacionesActivas: p.notificaciones_activas,
  maximoRegistrosDia: p.maximo_registros_dia,
  archivado: p.archivado,
  creadoEn: iso(p.creado_en),
  versionEncriptacion: p.version_encriptacion,
  cifrados: p.cifrados ?? {},
});

const registroAJson = (r) => ({
  id: r.id,
  pacienteId: r.paciente_id,
  fecha: iso(r.fecha),
  creadoEn: iso(r.creado_en),
  tipoRegistro: r.tipo_registro,
  nivelAlerta: r.nivel_alerta,
  versionEncriptacion: r.version_encriptacion,
  cifrados: r.cifrados ?? {},
});

const recordatorioAJson = (r) => ({
  id: r.id,
  pacienteId: r.paciente_id,
  activo: r.activo,
  creadoEn: iso(r.creado_en),
  versionEncriptacion: r.version_encriptacion,
  cifrados: r.cifrados ?? {},
});

async function exigirPaciente(uid, pid) {
  validarId(pid, 'pacienteId');
  const { rows } = await db.consulta('SELECT 1 FROM pacientes WHERE usuario_id = $1 AND id = $2', [uid, pid]);
  if (!rows[0]) throw new ErrorHttp(404, 'Paciente no encontrado');
}

router.get('/pacientes', async (req, res) => {
  const filtro = req.query.archivados;
  const params = [req.uid];
  let extra = '';
  if (filtro === 'true' || filtro === 'false') {
    params.push(filtro === 'true');
    extra = ' AND archivado = $2';
  }
  const { rows } = await db.consulta(
    `SELECT * FROM pacientes WHERE usuario_id = $1${extra} ORDER BY creado_en, id`, params);
  res.json(rows.map(pacienteAJson));
});

router.put('/pacientes/:id', async (req, res) => {
  const id = validarId(req.params.id);
  const cuerpo = cuerpoObjeto(req);
  rechazarEnClaro(cuerpo, 'pacientes');
  const fila = await upsert({
    tabla: 'pacientes',
    claves: { usuario_id: req.uid, id },
    campos: {
      notificaciones_activas: booleanoOpcional(cuerpo.notificacionesActivas, 'notificacionesActivas'),
      maximo_registros_dia: enteroOpcional(cuerpo.maximoRegistrosDia, 'maximoRegistrosDia'),
      archivado: booleanoOpcional(cuerpo.archivado, 'archivado'),
      creado_en: fechaOpcional(cuerpo.creadoEn, 'creadoEn'),
      version_encriptacion: enteroOpcional(cuerpo.versionEncriptacion, 'versionEncriptacion'),
    },
    cifrados: leerCifrados(cuerpo),
  });
  res.json(pacienteAJson(fila));
});

router.delete('/pacientes/:id', async (req, res) => {
  const { rowCount } = await db.consulta('DELETE FROM pacientes WHERE usuario_id = $1 AND id = $2',
    [req.uid, validarId(req.params.id)]);
  if (!rowCount) throw new ErrorHttp(404, 'Paciente no encontrado');
  res.json({ ok: true });
});

// Registros clinicos
router.get('/pacientes/:pid/registros', async (req, res) => {
  await exigirPaciente(req.uid, req.params.pid);
  const { desde, hasta, antesDeCreadoEn } = req.query;
  const params = [req.uid, req.params.pid];
  const cond = ['usuario_id = $1', 'paciente_id = $2'];
  let orden;
  let tope;
  if (desde !== undefined || hasta !== undefined) {
    if (desde !== undefined) {
      params.push(fechaOpcional(desde, 'desde'));
      cond.push(`fecha >= $${params.length}`);
    }
    if (hasta !== undefined) {
      params.push(fechaOpcional(hasta, 'hasta'));
      cond.push(`fecha < $${params.length}`);
    }
    orden = 'fecha ASC, id ASC';
    tope = req.query.limite === undefined ? null : limite(req.query.limite, null, 5000);
  } else {
    if (antesDeCreadoEn !== undefined) {
      params.push(fechaOpcional(antesDeCreadoEn, 'antesDeCreadoEn'));
      cond.push(`creado_en < $${params.length}`);
    }
    orden = 'creado_en DESC, id DESC';
    tope = limite(req.query.limite, 50);
  }
  let sql = `SELECT * FROM registros_clinicos WHERE ${cond.join(' AND ')} ORDER BY ${orden}`;
  if (tope) {
    params.push(tope);
    sql += ` LIMIT $${params.length}`;
  }
  const { rows } = await db.consulta(sql, params);
  res.json(rows.map(registroAJson));
});

router.put('/pacientes/:pid/registros/:rid', async (req, res) => {
  const cuerpo = cuerpoObjeto(req);
  rechazarEnClaro(cuerpo, 'registros');
  const rid = validarId(req.params.rid, 'registroId');
  if (cuerpo.pacienteId !== undefined && cuerpo.pacienteId !== req.params.pid) {
    throw new ErrorHttp(400, 'pacienteId del cuerpo no coincide con el de la ruta');
  }
  const cifrados = leerCifrados(cuerpo);
  const campos = {
    fecha: fechaOpcional(cuerpo.fecha, 'fecha', { nulaPermitida: true }),
    creado_en: fechaOpcional(cuerpo.creadoEn, 'creadoEn'),
    tipo_registro: textoOpcional(cuerpo.tipoRegistro, 'tipoRegistro', { nuloPermitido: true }),
    nivel_alerta: textoOpcional(cuerpo.nivelAlerta, 'nivelAlerta', { nuloPermitido: true }),
    version_encriptacion: enteroOpcional(cuerpo.versionEncriptacion, 'versionEncriptacion'),
  };
  await exigirPaciente(req.uid, req.params.pid);
  const fila = await upsert({
    tabla: 'registros_clinicos',
    claves: { usuario_id: req.uid, paciente_id: req.params.pid, id: rid },
    campos,
    cifrados,
  });
  res.json(registroAJson(fila));
});

router.delete('/pacientes/:pid/registros/:rid', async (req, res) => {
  await exigirPaciente(req.uid, req.params.pid);
  const { rowCount } = await db.consulta(
    'DELETE FROM registros_clinicos WHERE usuario_id = $1 AND paciente_id = $2 AND id = $3',
    [req.uid, req.params.pid, validarId(req.params.rid, 'registroId')]);
  if (!rowCount) throw new ErrorHttp(404, 'Registro no encontrado');
  res.json({ ok: true });
});

// Recordatorios
router.get('/pacientes/:pid/recordatorios', async (req, res) => {
  await exigirPaciente(req.uid, req.params.pid);
  const { rows } = await db.consulta(
    `SELECT * FROM recordatorios WHERE usuario_id = $1 AND paciente_id = $2
     ORDER BY creado_en DESC, id DESC LIMIT $3`,
    [req.uid, req.params.pid, limite(req.query.limite, 100)]);
  res.json(rows.map(recordatorioAJson));
});

router.put('/pacientes/:pid/recordatorios/:rid', async (req, res) => {
  const cuerpo = cuerpoObjeto(req);
  rechazarEnClaro(cuerpo, 'recordatorios');
  const rid = validarId(req.params.rid, 'recordatorioId');
  if (cuerpo.pacienteId !== undefined && cuerpo.pacienteId !== req.params.pid) {
    throw new ErrorHttp(400, 'pacienteId del cuerpo no coincide con el de la ruta');
  }
  const cifrados = leerCifrados(cuerpo);
  const campos = {
    activo: booleanoOpcional(cuerpo.activo, 'activo'),
    creado_en: fechaOpcional(cuerpo.creadoEn, 'creadoEn'),
    version_encriptacion: enteroOpcional(cuerpo.versionEncriptacion, 'versionEncriptacion'),
  };
  await exigirPaciente(req.uid, req.params.pid);
  const fila = await upsert({
    tabla: 'recordatorios',
    claves: { usuario_id: req.uid, paciente_id: req.params.pid, id: rid },
    campos,
    cifrados,
  });
  res.json(recordatorioAJson(fila));
});

router.delete('/pacientes/:pid/recordatorios/:rid', async (req, res) => {
  await exigirPaciente(req.uid, req.params.pid);
  const { rowCount } = await db.consulta(
    'DELETE FROM recordatorios WHERE usuario_id = $1 AND paciente_id = $2 AND id = $3',
    [req.uid, req.params.pid, validarId(req.params.rid, 'recordatorioId')]);
  if (!rowCount) throw new ErrorHttp(404, 'Recordatorio no encontrado');
  res.json({ ok: true });
});

module.exports = router;
