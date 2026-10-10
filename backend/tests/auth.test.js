const { app, request, db, unico, crearUsuario, con, cerrar, limpiar } = require('./ayudas');
const correo = require('../src/correo');

afterAll(async () => { await limpiar(); await cerrar(); });
beforeEach(() => jest.restoreAllMocks());

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
    const nuevo = `n-${unico()}@prueba.cl`;
    const ok = await request(app).post('/api/auth/cambiar-correo').set(con(u)).send({ contrasena: u.contrasena, nuevoCorreo: nuevo });
    expect(ok.status).toBe(200);
    expect((await request(app).post('/api/auth/login').send({ correo: nuevo, contrasena: u.contrasena })).status).toBe(200);
  });

  test('borrar cuenta elimina todo en cascada', async () => {
    const u = await crearUsuario();
    await request(app).put('/api/pacientes/p1').set(con(u)).send({});
    expect((await request(app).delete('/api/cuenta').set(con(u))).status).toBe(200);
    const { rows } = await db.consulta('SELECT 1 FROM pacientes WHERE usuario_id = $1', [u.uid]);
    expect(rows).toHaveLength(0);
    expect((await request(app).post('/api/auth/login').send({ correo: u.correo, contrasena: u.contrasena })).status).toBe(401);
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
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    const existe = await request(app).post('/api/auth/recuperar-contrasena').send({ correo: u.correo });
    const noExiste = await request(app).post('/api/auth/recuperar-contrasena').send({ correo: 'nadie@prueba.cl' });
    const basura = await request(app).post('/api/auth/recuperar-contrasena').send({});
    expect([existe.status, noExiste.status, basura.status]).toEqual([200, 200, 200]);
    expect(existe.body).toEqual(noExiste.body);
    expect(enviar).toHaveBeenCalledTimes(1);
    expect(enviar.mock.calls[0][0]).toBe(u.correo);
  });

  test('el token restablece la contrasena una sola vez', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
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
  });

  test('por correo de respaldo: envia al respaldo y aplica espera de 60 s', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    const respaldo = `r-${unico()}@prueba.cl`;
    expect((await request(app).post('/api/correo-respaldo').set(con(u)).send({ correo: 'malo' })).status).toBe(400);
    expect((await request(app).post('/api/correo-respaldo').set(con(u)).send({ correo: respaldo })).body).toEqual({ ok: true });
    const { rows } = await db.consulta('SELECT correo_respaldo_hash FROM usuarios WHERE id = $1', [u.uid]);
    expect(rows[0].correo_respaldo_hash).toMatch(/^[0-9a-f]{64}$/);

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
