const nodemailer = require('nodemailer');
const config = require('./config');

let transporte;

async function enviarEnlace(destino, enlace) {
  if (!config.smtp.host) {
    console.log(`[correo] Enlace de restablecimiento para ${destino}: ${enlace}`);
    return;
  }
  transporte ??= nodemailer.createTransport({
    host: config.smtp.host,
    port: config.smtp.puerto,
    secure: config.smtp.puerto === 465,
    auth: config.smtp.usuario ? { user: config.smtp.usuario, pass: config.smtp.clave } : undefined,
  });
  await transporte.sendMail({
    from: config.smtp.remitente,
    to: destino,
    subject: 'Restablecer tu contraseña de OnCuidar',
    text: `Para restablecer tu contraseña abre este enlace (vence en 1 hora):\n${enlace}\n\nSi no lo solicitaste, ignora este mensaje.`,
  });
}

module.exports = { enviarEnlace };
