const nodemailer = require('nodemailer');
const config = require('./config');
const plantillas = require('./plantillas');

let transporte;

const PLANTILLAS = plantillas.CORREOS;

async function enviarEnlace(destino, enlace, tipo = 'restablecer') {
  const { asunto, html, texto } = plantillas.armarCorreo(tipo, enlace);
  if (!config.smtp.host) {
    if (process.env.NODE_ENV !== 'test') console.log(`[correo] ${asunto} para ${destino}: ${enlace}`);
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
    subject: asunto,
    text: texto,
    html,
    attachments: [{
      filename: 'logo-oncuidar.png',
      content: plantillas.LOGO_PNG,
      contentType: 'image/png',
      cid: plantillas.CID_LOGO,
      contentDisposition: 'inline',
    }],
  });
}

module.exports = { enviarEnlace, PLANTILLAS };
