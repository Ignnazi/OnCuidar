// Configuracion leida del entorno
require('dotenv').config();

const env = process.env;

const config = {
  puerto: Number(env.PUERTO || 3000),
  databaseUrl: env.DATABASE_URL || 'postgres://oncuidar:oncuidar@localhost:5432/oncuidar',
  jwtSecreto: env.JWT_SECRETO || '',
  claveMaestra: env.CLAVE_MAESTRA || '',
  hmacCorreo: env.HMAC_CORREO || '',
  urlPublica: (env.URL_PUBLICA || 'http://localhost:8080').replace(/\/$/, ''),
  limiteAuth: Number(env.LIMITE_AUTH || 30),
  ventanaAuthMs: Number(env.VENTANA_AUTH_MS || 15 * 60 * 1000),
  esperaRecuperacionSeg: 60,
  smtp: {
    host: env.SMTP_HOST || '',
    puerto: Number(env.SMTP_PUERTO || 587),
    usuario: env.SMTP_USUARIO || '',
    clave: env.SMTP_CLAVE || '',
    remitente: env.SMTP_REMITENTE || 'OnCuidar <no-responder@oncuidar.cl>',
  },
};

// Valida los secretos obligatorios al arrancar
config.validar = function validar() {
  if (config.jwtSecreto.length < 16) throw new Error('JWT_SECRETO debe tener al menos 16 caracteres');
  if (Buffer.from(config.claveMaestra, 'base64').length !== 32) {
    throw new Error('CLAVE_MAESTRA debe ser de 32 bytes en base64');
  }
  if (!config.hmacCorreo) throw new Error('HMAC_CORREO es obligatorio');
};

module.exports = config;
