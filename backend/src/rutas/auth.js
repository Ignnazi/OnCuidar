const crypto = require('crypto');
const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const config = require('../config');
const correo = require('../correo');
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
    res.status(201).json({ token: firmarToken(rows[0].id), uid: rows[0].id });
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
  try {
    await db.consulta('UPDATE usuarios SET correo = $1 WHERE id = $2', [normalizarCorreo(nuevoCorreo), req.uid]);
  } catch (e) {
    if (e.code === '23505') throw new ErrorHttp(409, 'Ya existe una cuenta con ese correo');
    throw e;
  }
  res.json({ ok: true });
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

const PAGINA_RESTABLECER = (token) => `<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Restablecer contraseña - OnCuidar</title>
<style>body{font-family:sans-serif;max-width:380px;margin:3rem auto;padding:0 1rem}input,button{width:100%;padding:.7rem;margin:.4rem 0;font-size:1rem}#msg{margin-top:1rem}</style></head>
<body><h1>Nueva contraseña</h1>
<form id="f"><input id="c1" type="password" minlength="6" placeholder="Nueva contraseña" required>
<input id="c2" type="password" minlength="6" placeholder="Repite la contraseña" required>
<button type="submit">Guardar contraseña</button></form><p id="msg"></p>
<script>
document.getElementById('f').addEventListener('submit', async (e) => {
  e.preventDefault();
  const msg = document.getElementById('msg');
  const c1 = document.getElementById('c1').value;
  if (c1 !== document.getElementById('c2').value) { msg.textContent = 'Las contraseñas no coinciden'; return; }
  const r = await fetch('/api/auth/restablecer-contrasena', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: '${token}', contrasena: c1 }) });
  const d = await r.json();
  msg.textContent = r.ok ? 'Listo. Ya puedes iniciar sesión en la app.' : d.error;
});
</script></body></html>`;

router.get('/auth/restablecer', (req, res) => {
  const token = String(req.query.token ?? '');
  if (!/^[a-f0-9]{64}$/.test(token)) return res.status(400).type('text').send('Enlace inválido');
  res.set('Content-Security-Policy',
    "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'");
  res.type('html').send(PAGINA_RESTABLECER(token));
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
  await db.consulta('UPDATE usuarios SET correo_respaldo_hash = $1 WHERE id = $2', [hashRespaldo(c), req.uid]);
  res.json({ ok: true });
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
