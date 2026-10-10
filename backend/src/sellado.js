const crypto = require('crypto');
const config = require('./config');

function claveMaestra() {
  const clave = Buffer.from(config.claveMaestra, 'base64');
  if (clave.length !== 32) throw new Error('CLAVE_MAESTRA invalida');
  return clave;
}

function sellar(buffer) {
  const iv = crypto.randomBytes(12);
  const cifra = crypto.createCipheriv('aes-256-gcm', claveMaestra(), iv);
  const cifrado = Buffer.concat([cifra.update(buffer), cifra.final()]);
  return [iv, cifra.getAuthTag(), cifrado].map((b) => b.toString('base64')).join('.');
}

function abrir(sellado) {
  const [iv, tag, cifrado] = sellado.split('.').map((p) => Buffer.from(p, 'base64'));
  const descifra = crypto.createDecipheriv('aes-256-gcm', claveMaestra(), iv);
  descifra.setAuthTag(tag);
  return Buffer.concat([descifra.update(cifrado), descifra.final()]);
}

module.exports = { sellar, abrir };
