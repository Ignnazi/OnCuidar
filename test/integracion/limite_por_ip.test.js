const { app, request, cerrar } = require('./ayudas');
const config = require('../../backend/src/config');

const limiteOriginal = config.limiteAuth;
afterAll(async () => { config.limiteAuth = limiteOriginal; await cerrar(); });

const intentar = (ip) => request(app).post('/api/auth/login')
  .set('X-Forwarded-For', ip)
  .send({ correo: 'nadie@prueba.cl', contrasena: 'incorrecta' });

describe('límite de intentos detrás del proxy', () => {
  test('cuenta por la IP real que agrega el proxy, no una sola para todos', async () => {
    config.limiteAuth = 2;
    await intentar('203.0.113.1');
    await intentar('203.0.113.1');
    expect((await intentar('203.0.113.1')).status).toBe(429);

    expect((await intentar('203.0.113.2')).status).not.toBe(429);
  });

  test('un X-Forwarded-For inventado por el cliente no salta el límite', async () => {
    config.limiteAuth = 2;
    const conCabeceraFalsa = (falsa) => request(app).post('/api/auth/login')
      .set('X-Forwarded-For', `${falsa}, 203.0.113.9`)
      .send({ correo: 'nadie@prueba.cl', contrasena: 'incorrecta' });
    await conCabeceraFalsa('198.51.100.1');
    await conCabeceraFalsa('198.51.100.2');
    expect((await conCabeceraFalsa('198.51.100.3')).status).toBe(429);
  });
});
