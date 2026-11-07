const { app, request, db, unico, crearUsuario, con, cerrar, limpiar } = require('./ayudas');
const bcrypt = require('bcryptjs');
const correo = require('../../backend/src/correo');

afterAll(async () => { await limpiar(); await cerrar(); });
beforeEach(() => jest.restoreAllMocks());

async function respaldoConfirmado(u, respaldo) {
  expect((await request(app).post('/api/correo-respaldo').set(con(u)).send({ correo: 'malo' })).status).toBe(400);
  const r = await request(app).post('/api/correo-respaldo').set(con(u)).send({ correo: respaldo });
  expect(r.body).toEqual({ ok: true, pendiente: true });
  const envio = correo.enviarEnlace.mock.calls.at(-1);
  expect(envio[0]).toBe(respaldo);
  expect((await request(app).post(new URL(envio[1]).pathname + new URL(envio[1]).search)).status).toBe(200);
  correo.enviarEnlace.mockClear();
}

describe('autenticacion', () => {
  test('salud responde ok', async () => {
    const r = await request(app).get('/api/salud');
    expect(r.status).toBe(200);
    expect(r.body).toEqual({ ok: true });
  });

  test('registro, login y credenciales invalidas', async () => {
    const c = `a-${unico()}@prueba.cl`;
    const reg = await request(app).post('/api/auth/registro').send({ correo: c.toUpperCase(), contrasena: 'secreta1' });
    expect(reg.status).toBe(201);
    expect(reg.body.token).toBeTruthy();
    const dup = await request(app).post('/api/auth/registro').send({ correo: c, contrasena: 'secreta1' });
    expect(dup.status).toBe(409);
    const corta = await request(app).post('/api/auth/registro').send({ correo: `b-${unico()}@prueba.cl`, contrasena: '123' });
    expect(corta.status).toBe(400);
    const ok = await request(app).post('/api/auth/login').send({ correo: c, contrasena: 'secreta1' });
    expect(ok.status).toBe(200);
    expect(ok.body.uid).toBe(reg.body.uid);
    const malaClave = await request(app).post('/api/auth/login').send({ correo: c, contrasena: 'otra123' });
    const malUsuario = await request(app).post('/api/auth/login').send({ correo: 'no@prueba.cl', contrasena: 'secreta1' });
    expect(malaClave.status).toBe(401);
    expect(malUsuario.status).toBe(401);
    expect(malaClave.body.error).toBe(malUsuario.body.error);
  });

  test('rutas protegidas exigen token valido', async () => {
    expect((await request(app).get('/api/pacientes')).status).toBe(401);
    expect((await request(app).get('/api/biblioteca').set('Authorization', 'Bearer falso')).status).toBe(401);
  });

  test('verificar contrasena y cambiar correo', async () => {
    const u = await crearUsuario();
    expect((await request(app).post('/api/auth/verificar-contrasena').set(con(u)).send({ contrasena: 'x12345' })).status).toBe(401);
    expect((await request(app).post('/api/auth/verificar-contrasena').set(con(u)).send({ contrasena: u.contrasena })).body).toEqual({ ok: true });
    const otro = await crearUsuario();
    const choque = await request(app).post('/api/auth/cambiar-correo').set(con(u)).send({ contrasena: u.contrasena, nuevoCorreo: otro.correo });
    expect(choque.status).toBe(409);
  });

  test('borrar cuenta elimina todo en cascada', async () => {
    const u = await crearUsuario();
    await request(app).put('/api/pacientes/p1').set(con(u)).send({});
    expect((await request(app).delete('/api/cuenta').set(con(u)).send({ contrasena: u.contrasena })).status).toBe(200);
    const { rows } = await db.consulta('SELECT 1 FROM pacientes WHERE usuario_id = $1', [u.uid]);
    expect(rows).toHaveLength(0);
    expect((await request(app).post('/api/auth/login').send({ correo: u.correo, contrasena: u.contrasena })).status).toBe(401);
  });
});

describe('borrar cuenta exige la contrasena', () => {
  test('sin contrasena responde 401 y la cuenta sigue', async () => {
    const u = await crearUsuario();
    const r = await request(app).delete('/api/cuenta').set(con(u));
    expect(r.status).toBe(401);
    expect(r.body.error).toBe('Contraseña incorrecta');
    expect((await request(app).post('/api/auth/login').send({ correo: u.correo, contrasena: u.contrasena })).status).toBe(200);
  });

  test('con contrasena incorrecta responde 401 y la cuenta sigue', async () => {
    const u = await crearUsuario();
    const r = await request(app).delete('/api/cuenta').set(con(u)).send({ contrasena: 'otra-clave' });
    expect(r.status).toBe(401);
    expect(r.body.error).toBe('Contraseña incorrecta');
    const { rows } = await db.consulta('SELECT 1 FROM usuarios WHERE id = $1', [u.uid]);
    expect(rows).toHaveLength(1);
  });

  test('con la contrasena correcta borra la cuenta', async () => {
    const u = await crearUsuario();
    expect((await request(app).delete('/api/cuenta').set(con(u)).send({ contrasena: u.contrasena })).body).toEqual({ ok: true });
    const { rows } = await db.consulta('SELECT 1 FROM usuarios WHERE id = $1', [u.uid]);
    expect(rows).toHaveLength(0);
  });
});

describe('largo minimo de la contrasena', () => {
  test('registro con 7 caracteres responde 400 y con 8 se acepta', async () => {
    const corta = await request(app).post('/api/auth/registro').send({ correo: `m-${unico()}@prueba.cl`, contrasena: '1234567' });
    expect(corta.status).toBe(400);
    expect(corta.body.error).toContain('al menos 8 caracteres');
    const justa = await request(app).post('/api/auth/registro').send({ correo: `m-${unico()}@prueba.cl`, contrasena: '12345678' });
    expect(justa.status).toBe(201);
  });

  test('una cuenta antigua con contrasena de 6 caracteres sigue entrando', async () => {
    const c = `vieja-${unico()}@prueba.cl`;
    await db.consulta('INSERT INTO usuarios (correo, contrasena_hash) VALUES ($1, $2)', [c, await bcrypt.hash('abc123', 10)]);
    expect((await request(app).post('/api/auth/login').send({ correo: c, contrasena: 'abc123' })).status).toBe(200);
  });

  test('restablecer con menos de 8 caracteres responde 400', async () => {
    const r = await request(app).post('/api/auth/restablecer-contrasena').send({ token: 'a'.repeat(64), contrasena: 'corta12' });
    expect(r.status).toBe(400);
    expect(r.body.error).toContain('al menos 8 caracteres');
  });

  test('la pagina para restablecer pide 8 caracteres', async () => {
    const pagina = await request(app).get(`/api/auth/restablecer?token=${'b'.repeat(64)}`);
    expect(pagina.text).toContain('Usa al menos 8 caracteres.');
    expect(pagina.text).toContain('var MIN = 8;');
  });
});

describe('clave de datos', () => {
  test('es idempotente y distinta por usuario', async () => {
    const a = await crearUsuario();
    const b = await crearUsuario();
    const a1 = await request(app).post('/api/clave-datos').set(con(a));
    const a2 = await request(app).post('/api/clave-datos').set(con(a));
    const b1 = await request(app).post('/api/clave-datos').set(con(b));
    expect(Buffer.from(a1.body.claveDatos, 'base64')).toHaveLength(32);
    expect(a2.body.claveDatos).toBe(a1.body.claveDatos);
    expect(b1.body.claveDatos).not.toBe(a1.body.claveDatos);
    const { rows } = await db.consulta('SELECT clave_sellada FROM claves_datos WHERE usuario_id = $1', [a.uid]);
    expect(rows[0].clave_sellada.split('.')).toHaveLength(3);
    expect(rows[0].clave_sellada).not.toContain(a1.body.claveDatos);
  });
});

describe('recuperacion de contrasena', () => {
  test('siempre responde 200 y solo envia si el correo existe', async () => {
    const u = await crearUsuario();
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const existe = await request(app).post('/api/auth/recuperar-contrasena').send({ correo: u.correo });
    const noExiste = await request(app).post('/api/auth/recuperar-contrasena').send({ correo: 'nadie@prueba.cl' });
    const basura = await request(app).post('/api/auth/recuperar-contrasena').send({});
    expect([existe.status, noExiste.status, basura.status]).toEqual([200, 200, 200]);
    expect(existe.body).toEqual(noExiste.body);
    expect(enviar).toHaveBeenCalledTimes(1);
    expect(enviar.mock.calls[0][0]).toBe(u.correo);
  });

  test('el token restablece la contrasena una sola vez', async () => {
    const u = await crearUsuario();
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    await request(app).post('/api/auth/recuperar-contrasena').send({ correo: u.correo });
    const enlace = enviar.mock.calls[0][1];
    const token = new URL(enlace).searchParams.get('token');
    const pagina = await request(app).get(`/api/auth/restablecer?token=${token}`);
    expect(pagina.status).toBe(200);
    expect(pagina.text).toContain('Nueva contraseña');
    expect((await request(app).get('/api/auth/restablecer?token=malo')).status).toBe(400);
    const ok = await request(app).post('/api/auth/restablecer-contrasena').send({ token, contrasena: 'nueva1234' });
    expect(ok.body).toEqual({ ok: true });
    expect((await request(app).post('/api/auth/restablecer-contrasena').send({ token, contrasena: 'otra12345' })).status).toBe(400);
    expect((await request(app).post('/api/auth/login').send({ correo: u.correo, contrasena: 'nueva1234' })).status).toBe(200);
    expect((await request(app).get('/api/cuidador').set(con(u))).status).toBe(401);
  });

  test('por correo de respaldo: envia al respaldo y aplica espera de 60 s', async () => {
    const u = await crearUsuario();
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const respaldo = `r-${unico()}@prueba.cl`;
    await respaldoConfirmado(u, respaldo);

    const r1 = await request(app).post('/api/auth/recuperar-por-respaldo').send({ correo: ` ${respaldo.toUpperCase()} ` });
    expect(r1.status).toBe(200);
    expect(enviar).toHaveBeenCalledTimes(1);
    expect(enviar.mock.calls[0][0]).toBe(respaldo.toUpperCase());
    const r2 = await request(app).post('/api/auth/recuperar-por-respaldo').send({ correo: respaldo });
    expect(r2.status).toBe(200);
    expect(enviar).toHaveBeenCalledTimes(1);
    // vencida la espera vuelve a enviar
    await db.consulta("UPDATE esperas_recuperacion SET ultimo_envio_en = now() - interval '61 seconds'");
    await request(app).post('/api/auth/recuperar-por-respaldo').send({ correo: respaldo });
    expect(enviar).toHaveBeenCalledTimes(2);
    expect((await request(app).post('/api/auth/recuperar-por-respaldo').send({ correo: 'zz@prueba.cl' })).status).toBe(200);
  });
});
