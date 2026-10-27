const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const config = require('./config');
const db = require('./db');

// Si la contrasena cambia, la huella cambia y los tokens anteriores dejan de servir
const huella = (contrasenaHash) => crypto.createHash('sha256').update(contrasenaHash).digest('hex').slice(0, 16);

function firmarToken(uid, contrasenaHash) {
  return jwt.sign({ sub: uid, v: huella(contrasenaHash) }, config.jwtSecreto, { algorithm: 'HS256', expiresIn: '30d' });
}

async function requiereToken(req, res, next) {
  const [tipo, token] = (req.headers.authorization || '').split(' ');
  if (tipo !== 'Bearer' || !token) return res.status(401).json({ error: 'Falta el token de acceso' });
  let datos;
  try {
    datos = jwt.verify(token, config.jwtSecreto, { algorithms: ['HS256'] });
  } catch {
    return res.status(401).json({ error: 'Token inválido o vencido' });
  }
  const { rows } = await db.consulta('SELECT contrasena_hash FROM usuarios WHERE id = $1', [datos.sub]);
  if (!rows[0] || datos.v !== huella(rows[0].contrasena_hash)) {
    return res.status(401).json({ error: 'Token inválido o vencido' });
  }
  req.uid = datos.sub;
  next();
}

// Limite por IP en memoria
function limitarIntentos() {
  const contadores = new Map();
  return (req, res, next) => {
    const ahora = Date.now();
    let c = contadores.get(req.ip);
    if (!c || c.vence < ahora) {
      c = { cuenta: 0, vence: ahora + config.ventanaAuthMs };
      contadores.set(req.ip, c);
    }
    c.cuenta += 1;
    if (c.cuenta > config.limiteAuth) {
      return res.status(429).json({ error: 'Demasiados intentos, espera unos minutos' });
    }
    next();
  };
}

module.exports = { firmarToken, requiereToken, limitarIntentos };
