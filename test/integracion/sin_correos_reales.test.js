const nodemailer = require('nodemailer');
const config = require('../../backend/src/config');
const correo = require('../../backend/src/correo');

describe('pruebas sin correos reales', () => {
  test('ignoran la configuración SMTP del .env', () => {
    expect(config.smtp.host).toBe('');
    expect(config.smtp.usuario).toBe('');
    expect(config.smtp.clave).toBe('');
  });

  test('enviarEnlace no abre una conexión SMTP', async () => {
    const crear = jest.spyOn(nodemailer, 'createTransport');
    const log = jest.spyOn(console, 'log').mockImplementation(() => {});
    await correo.enviarEnlace('alguien@prueba.cl', 'http://localhost:8080/api/auth/restablecer?token=x');
    expect(crear).not.toHaveBeenCalled();
    crear.mockRestore();
    log.mockRestore();
  });
});
