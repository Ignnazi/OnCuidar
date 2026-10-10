const jwt = require('jsonwebtoken');
const config = require('./config');

function firmarToken(uid) {
  return jwt.sign({ sub: uid }, config.jwtSecreto, { algorithm: 'HS256', expiresIn: '30d' });
}

function requiereToken(req, res, next) {
  const [tipo, token] = (req.headers.authorization || '').split(' ');
  if (tipo !== 'Bearer' || !token) return res.status(401).json({ error: 'Falta el token de acceso' });
  try {
    req.uid = jwt.verify(token, config.jwtSecreto, { algorithms: ['HS256'] }).sub;
    next();
  } catch {
    res.status(401).json({ error: 'Token inválido o vencido' });
  }
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
