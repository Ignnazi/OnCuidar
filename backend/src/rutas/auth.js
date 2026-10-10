const crypto = require('crypto');
const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const config = require('../config');
const correo = require('../correo');
const plantillas = require('../plantillas');
const sellado = require('../sellado');
const { firmarToken, requiereToken, limitarIntentos } = require('../auth');
const { ErrorHttp, cuerpoObjeto, correoValido, normalizarCorreo } = require('../validacion');

const router = express.Router();
const sha256 = (t) => crypto.createHash('sha256').update(t).digest('hex');
const HASH_FALSO = bcrypt.hashSync('contraseña-inexistente', 10);

function exigirContrasena(valor, nombre = 'contrasena') {
  if (typeof valor !== 'string' || valor.length < 6) {
    throw new ErrorHttp(400, `La contraseña debe tener al menos 6 caracteres (${nombre})`);
  }
  return valor;
}

async function verificarContrasena(uid, contrasena) {
  const { rows } = await db.consulta('SELECT contrasena_hash FROM usuarios WHERE id = $1', [uid]);
  if (!rows[0] || typeof contrasena !== 'string') return false;
  return bcrypt.compare(contrasena, rows[0].contrasena_hash);
}

async function enviarRestablecimiento(usuarioId, destino) {
  const token = crypto.randomBytes(32).toString('hex');
  await db.consulta(
    "INSERT INTO tokens_restablecer (token_hash, usuario_id, expira_en) VALUES ($1, $2, now() + interval '1 hour')",
    [sha256(token), usuarioId],
  );
  await correo.enviarEnlace(destino, `${config.urlPublica}/api/auth/restablecer?token=${token}`);
}

async function crearTokenCorreo(cliente, usuarioId, tipo, { correoNuevo = null, respaldoHash = null } = {}) {
  await cliente.query('UPDATE tokens_correo SET usado = true WHERE usuario_id = $1 AND tipo = $2 AND usado = false', [usuarioId, tipo]);
  const token = crypto.randomBytes(32).toString('hex');
  await cliente.query(
    `INSERT INTO tokens_correo (token_hash, usuario_id, tipo, correo_nuevo, respaldo_hash, expira_en)
     VALUES ($1, $2, $3, $4, $5, now() + interval '1 hour')`,
    [sha256(token), usuarioId, tipo, correoNuevo, respaldoHash],
  );
  return token;
}

const enlaceConfirmacion = (token) => `${config.urlPublica}/api/auth/confirmar-correo?token=${token}`;

const enviarConfirmacion = (destino, token, tipo) => correo.enviarEnlace(destino, enlaceConfirmacion(token), tipo);

function enviarSinEsperar(destino, token, tipo) {
  enviarConfirmacion(destino, token, tipo).catch((e) => console.error(`[correo ${tipo}]`, e.message));
}

router.use('/auth', limitarIntentos());

router.post('/auth/registro', async (req, res) => {
  const { correo: c, contrasena } = cuerpoObjeto(req);
  if (!correoValido(c)) throw new ErrorHttp(400, 'Correo inválido');
  exigirContrasena(contrasena);
  const hash = await bcrypt.hash(contrasena, 10);
  try {
    const { rows } = await db.consulta(
      'INSERT INTO usuarios (correo, contrasena_hash) VALUES ($1, $2) RETURNING id',
      [normalizarCorreo(c), hash],
    );
    const uid = rows[0].id;
    const normalizado = normalizarCorreo(c);
    try {
      const token = await db.transaccion((cl) => crearTokenCorreo(cl, uid, 'verificacion', { correoNuevo: normalizado }));
      enviarSinEsperar(normalizado, token, 'verificar');
    } catch (e) {
      console.error('[verificacion de registro]', e.message);
    }
    res.status(201).json({ token: firmarToken(uid), uid });
  } catch (e) {
    if (e.code === '23505') throw new ErrorHttp(409, 'Ya existe una cuenta con ese correo');
    throw e;
  }
});

router.post('/auth/login', async (req, res) => {
  const { correo: c, contrasena } = cuerpoObjeto(req);
  const mensaje = 'Correo o contraseña incorrectos';
  if (typeof c !== 'string' || typeof contrasena !== 'string') throw new ErrorHttp(401, mensaje);
  const { rows } = await db.consulta('SELECT id, contrasena_hash FROM usuarios WHERE correo = $1', [normalizarCorreo(c)]);
  const ok = await bcrypt.compare(contrasena, rows[0]?.contrasena_hash ?? HASH_FALSO);
  if (!rows[0] || !ok) throw new ErrorHttp(401, mensaje);
  res.json({ token: firmarToken(rows[0].id), uid: rows[0].id });
});

router.post('/auth/verificar-contrasena', requiereToken, async (req, res) => {
  const { contrasena } = cuerpoObjeto(req);
  if (!(await verificarContrasena(req.uid, contrasena))) throw new ErrorHttp(401, 'Contraseña incorrecta');
  res.json({ ok: true });
});

router.post('/auth/cambiar-correo', requiereToken, async (req, res) => {
  const { contrasena, nuevoCorreo } = cuerpoObjeto(req);
  if (!correoValido(nuevoCorreo)) throw new ErrorHttp(400, 'Correo inválido');
  if (!(await verificarContrasena(req.uid, contrasena))) throw new ErrorHttp(401, 'Contraseña incorrecta');
  const nuevo = normalizarCorreo(nuevoCorreo);
  const { rows } = await db.consulta('SELECT id FROM usuarios WHERE correo = $1', [nuevo]);
  if (rows[0]) {
    if (rows[0].id === req.uid) throw new ErrorHttp(400, 'Ese ya es tu correo principal');
    throw new ErrorHttp(409, 'Ya existe una cuenta con ese correo');
  }
  const token = await db.transaccion(async (cl) => {
    const t = await crearTokenCorreo(cl, req.uid, 'cambio', { correoNuevo: nuevo });
    await cl.query(
      `UPDATE usuarios SET pendiente_correo = $1, pendiente_correo_tipo = 'principal',
       pendiente_correo_solicitado_en = now() WHERE id = $2`,
      [nuevo, req.uid],
    );
    return t;
  });
  try {
    await enviarConfirmacion(nuevo, token, 'cambio');
  } catch (e) {
    console.error('[cambiar-correo]', e.message);
    throw new ErrorHttp(502, 'No se pudo enviar el correo de confirmación, intenta de nuevo');
  }
  res.json({ ok: true, pendiente: true });
});

router.delete('/cuenta', requiereToken, async (req, res) => {
  await db.consulta('DELETE FROM usuarios WHERE id = $1', [req.uid]);
  res.json({ ok: true });
});

router.post('/auth/recuperar-contrasena', async (req, res) => {
  const { correo: c } = req.body ?? {};
  if (correoValido(c)) {
    try {
      const { rows } = await db.consulta('SELECT id, correo FROM usuarios WHERE correo = $1', [normalizarCorreo(c)]);
      if (rows[0]) await enviarRestablecimiento(rows[0].id, rows[0].correo);
    } catch (e) {
      console.error('[recuperar-contrasena]', e.message);
    }
  }
  res.json({ ok: true });
});

router.post('/auth/restablecer-contrasena', async (req, res) => {
  const { token, contrasena } = cuerpoObjeto(req);
  exigirContrasena(contrasena);
  if (typeof token !== 'string') throw new ErrorHttp(400, 'Enlace inválido o vencido');
  const { rows } = await db.consulta(
    `UPDATE tokens_restablecer SET usado = true
     WHERE token_hash = $1 AND usado = false AND expira_en > now() RETURNING usuario_id`,
    [sha256(token)],
  );
  if (!rows[0]) throw new ErrorHttp(400, 'Enlace inválido o vencido');
  await db.consulta('UPDATE usuarios SET contrasena_hash = $1 WHERE id = $2', [
    await bcrypt.hash(contrasena, 10), rows[0].usuario_id,
  ]);
  res.json({ ok: true });
});

router.get('/auth/restablecer', (req, res) => {
  const token = String(req.query.token ?? '');
  const nonce = crypto.randomBytes(16).toString('base64');
  res.set('Cache-Control', 'no-store');
  res.set('Referrer-Policy', 'no-referrer');
  res.set('Content-Security-Policy', plantillas.cspPagina(nonce, { conScript: /^[a-f0-9]{64}$/.test(token) }));
  if (!/^[a-f0-9]{64}$/.test(token)) return res.status(400).type('html').send(plantillas.paginaConfirmacion(false, nonce, plantillas.PASOS_CONTRASENA));
  res.type('html').send(plantillas.paginaRestablecer(token, nonce));
});

router.post('/auth/reenviar-verificacion', requiereToken, async (req, res) => {
  const { rows } = await db.consulta('SELECT correo, correo_verificado FROM usuarios WHERE id = $1', [req.uid]);
  if (!rows[0]) throw new ErrorHttp(404, 'Cuidador no encontrado');
  if (rows[0].correo_verificado) return res.json({ ok: true, verificado: true });
  const reciente = await db.consulta(
    `SELECT 1 FROM tokens_correo WHERE usuario_id = $1 AND tipo = 'verificacion'
     AND creado_en > now() - make_interval(secs => $2)`,
    [req.uid, config.esperaRecuperacionSeg],
  );
  if (reciente.rows[0]) throw new ErrorHttp(429, 'Espera un minuto antes de pedir otro enlace');
  const token = await db.transaccion((cl) => crearTokenCorreo(cl, req.uid, 'verificacion', { correoNuevo: rows[0].correo }));
  try {
    await enviarConfirmacion(rows[0].correo, token, 'verificar');
  } catch (e) {
    console.error('[reenviar-verificacion]', e.message);
    throw new ErrorHttp(502, 'No se pudo enviar el correo, intenta de nuevo');
  }
  res.json({ ok: true });
});

async function aplicarTokenCorreo(token) {
  return db.transaccion(async (cl) => {
    const { rows } = await cl.query(
      `UPDATE tokens_correo SET usado = true
       WHERE token_hash = $1 AND usado = false AND expira_en > now() RETURNING *`,
      [sha256(token)],
    );
    const t = rows[0];
    if (!t) return false;
    let r;
    if (t.tipo === 'cambio') {
      r = await cl.query(
        `UPDATE usuarios SET correo = $1, correo_verificado = true, pendiente_correo = NULL,
         pendiente_correo_tipo = NULL, pendiente_correo_solicitado_en = NULL
         WHERE id = $2 AND pendiente_correo = $1`,
        [t.correo_nuevo, t.usuario_id],
      );
    } else if (t.tipo === 'respaldo') {
      r = await cl.query(
        'UPDATE usuarios SET correo_respaldo_hash = $1, respaldo_pendiente_servidor = false WHERE id = $2 AND respaldo_pendiente_servidor = true',
        [t.respaldo_hash, t.usuario_id],
      );
    } else {
      r = await cl.query('UPDATE usuarios SET correo_verificado = true WHERE id = $1 AND correo = $2', [t.usuario_id, t.correo_nuevo]);
    }
    return r.rowCount === 1;
  });
}

router.get('/auth/confirmar-correo', async (req, res) => {
  const token = String(req.query.token ?? '');
  const nonce = crypto.randomBytes(16).toString('base64');
  res.set('Cache-Control', 'no-store');
  res.set('Referrer-Policy', 'no-referrer');
  res.set('Content-Security-Policy', plantillas.cspPagina(nonce));
  let ok = false;
  if (/^[a-f0-9]{64}$/.test(token)) {
    try {
      ok = await aplicarTokenCorreo(token);
    } catch (e) {
      if (e.code !== '23505') throw e;
    }
  }
  if (ok) return res.type('html').send(plantillas.paginaConfirmacion(true, nonce));
  res.status(400).type('html').send(plantillas.paginaConfirmacion(false, nonce));
});

router.post('/clave-datos', requiereToken, async (req, res) => {
  const nueva = sellado.sellar(crypto.randomBytes(32));
  await db.consulta(
    'INSERT INTO claves_datos (usuario_id, clave_sellada) VALUES ($1, $2) ON CONFLICT (usuario_id) DO NOTHING',
    [req.uid, nueva],
  );
  const { rows } = await db.consulta('SELECT clave_sellada FROM claves_datos WHERE usuario_id = $1', [req.uid]);
  res.json({ claveDatos: sellado.abrir(rows[0].clave_sellada).toString('base64') });
});

const hashRespaldo = (c) => crypto.createHmac('sha256', config.hmacCorreo).update(normalizarCorreo(c)).digest('hex');

router.post('/correo-respaldo', requiereToken, async (req, res) => {
  const { correo: c } = cuerpoObjeto(req);
  if (!correoValido(c)) throw new ErrorHttp(400, 'Correo inválido');
  const token = await db.transaccion(async (cl) => {
    const t = await crearTokenCorreo(cl, req.uid, 'respaldo', { respaldoHash: hashRespaldo(c) });
    await cl.query('UPDATE usuarios SET respaldo_pendiente_servidor = true WHERE id = $1', [req.uid]);
    return t;
  });
  try {
    await enviarConfirmacion(c.trim(), token, 'respaldo');
  } catch (e) {
    console.error('[correo-respaldo]', e.message);
    throw new ErrorHttp(502, 'No se pudo enviar el correo de confirmación, intenta de nuevo');
  }
  res.json({ ok: true, pendiente: true });
});

router.post('/auth/recuperar-por-respaldo', async (req, res) => {
  const { correo: c } = req.body ?? {};
  if (correoValido(c)) {
    try {
      const hash = hashRespaldo(c);
      const espera = await db.consulta(
        `INSERT INTO esperas_recuperacion (hash, ultimo_envio_en) VALUES ($1, now())
         ON CONFLICT (hash) DO UPDATE SET ultimo_envio_en = now()
         WHERE esperas_recuperacion.ultimo_envio_en < now() - make_interval(secs => $2)
         RETURNING hash`,
        [hash, config.esperaRecuperacionSeg],
      );
      if (espera.rows[0]) {
        const { rows } = await db.consulta('SELECT id, correo FROM usuarios WHERE correo_respaldo_hash = $1', [hash]);
        for (const u of rows) {
          if (normalizarCorreo(c) !== u.correo) await enviarRestablecimiento(u.id, c.trim());
        }
      }
    } catch (e) {
      console.error('[recuperar-por-respaldo]', e.message);
    }
  }
  res.json({ ok: true });
});

module.exports = router;
