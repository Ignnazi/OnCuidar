const { app, request, db, unico, crearUsuario, con, cerrar, limpiar } = require('./ayudas');
const correo = require('../../backend/src/correo');

afterAll(async () => { await limpiar(); await cerrar(); });
beforeEach(() => jest.restoreAllMocks());

const sha256 = (t) => require('crypto').createHash('sha256').update(t).digest('hex');
const pedir = (u, nuevoCorreo, contrasena = u.contrasena) =>
  request(app).post('/api/auth/cambiar-correo').set(con(u)).send({ contrasena, nuevoCorreo });
const rutaDe = (enlace) => new URL(enlace).pathname + new URL(enlace).search;
const tokenDe = (enlace) => new URL(enlace).searchParams.get('token');
const cuidador = async (u) => (await request(app).get('/api/cuidador').set(con(u))).body;
const fila = async (uid) => (await db.consulta('SELECT * FROM usuarios WHERE id = $1', [uid])).rows[0];

describe('cambio de correo principal', () => {
  test('queda pendiente, no cambia hasta confirmar y el token es de un solo uso', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    enviar.mockClear();
    const nuevo = `n-${unico()}@prueba.cl`;
    expect((await pedir(u, nuevo, 'mala12345')).status).toBe(401);
    const r = await pedir(u, nuevo.toUpperCase());
    expect(r.body).toEqual({ ok: true, pendiente: true });
    expect(enviar).toHaveBeenCalledTimes(1);
    expect(enviar.mock.calls[0][0]).toBe(nuevo);
    expect(enviar.mock.calls[0][2]).toBe('cambio');

    const antes = await cuidador(u);
    expect(antes.correo).toBe(u.correo);
    expect(antes.pendienteCorreo).toBe(nuevo);
    expect(antes.pendienteCorreoTipo).toBe('principal');
    expect((await request(app).post('/api/auth/login').send({ correo: nuevo, contrasena: u.contrasena })).status).toBe(401);

    const vista = await request(app).get(rutaDe(enviar.mock.calls[0][1]));
    expect(vista.status).toBe(200);
    expect(vista.text).toContain('Confirmar correo');
    expect((await cuidador(u)).pendienteCorreo).toBe(nuevo);

    const pagina = await request(app).post(rutaDe(enviar.mock.calls[0][1]));
    expect(pagina.status).toBe(200);
    expect(pagina.text).toContain('Correo confirmado');
    expect(pagina.headers['content-security-policy']).toContain("default-src 'none'");
    const despues = await cuidador(u);
    expect(despues).toMatchObject({ correo: nuevo, pendienteCorreo: null, correoVerificado: true });
    expect((await request(app).post('/api/auth/login').send({ correo: nuevo, contrasena: u.contrasena })).status).toBe(200);
    // el mismo enlace ya no sirve
    const repetido = await request(app).post(rutaDe(enviar.mock.calls[0][1]));
    expect(repetido.status).toBe(400);
    expect(repetido.text).toContain('Enlace inválido o vencido');
  });

  test('una solicitud nueva invalida el enlace anterior', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    enviar.mockClear();
    await pedir(u, `a-${unico()}@prueba.cl`);
    const segundo = `b-${unico()}@prueba.cl`;
    await pedir(u, segundo);
    expect((await request(app).post(rutaDe(enviar.mock.calls[0][1]))).status).toBe(400);
    expect((await request(app).post(rutaDe(enviar.mock.calls[1][1]))).status).toBe(200);
    expect((await cuidador(u)).correo).toBe(segundo);
  });

  test('token invalido, malformado o vencido muestra la pagina de error', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    enviar.mockClear();
    await pedir(u, `v-${unico()}@prueba.cl`);
    expect((await request(app).get('/api/auth/confirmar-correo?token=malo')).status).toBe(400);
    expect((await request(app).get(`/api/auth/confirmar-correo?token=${'a'.repeat(64)}`)).status).toBe(400);
    await db.consulta("UPDATE tokens_correo SET expira_en = now() - interval '1 second' WHERE token_hash = $1", [sha256(tokenDe(enviar.mock.calls[0][1]))]);
    const vencido = await request(app).post(rutaDe(enviar.mock.calls[0][1]));
    expect(vencido.status).toBe(400);
    expect((await cuidador(u)).correo).toBe(u.correo);
  });

  test('409 si el correo ya es de otro usuario, tambien si lo toman antes de confirmar', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    const otro = await crearUsuario();
    enviar.mockClear();
    expect((await pedir(u, otro.correo)).status).toBe(409);
    expect((await pedir(u, u.correo)).status).toBe(400);
    expect(enviar).not.toHaveBeenCalled();
    const codigo = `t-${unico()}@prueba.cl`;
    await pedir(u, codigo);
    // otro usuario registra ese correo entre medio
    await db.consulta('UPDATE usuarios SET correo = $1 WHERE id = $2', [codigo, otro.uid]);
    const r = await request(app).post(rutaDe(enviar.mock.calls[0][1]));
    expect(r.status).toBe(400);
    expect((await cuidador(u)).correo).toBe(u.correo);
  });

  test('si falla el envio responde 502', async () => {
    const u = await crearUsuario();
    jest.spyOn(correo, 'enviarEnlace').mockRejectedValue(new Error('smtp caido'));
    jest.spyOn(console, 'error').mockImplementation(() => {});
    expect((await pedir(u, `f-${unico()}@prueba.cl`)).status).toBe(502);
  });
});

describe('correo de respaldo', () => {
  test('no se activa hasta confirmar y recuperar-por-respaldo no lo usa antes', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    enviar.mockClear();
    const respaldo = `r-${unico()}@prueba.cl`;
    const r = await request(app).post('/api/correo-respaldo').set(con(u)).send({ correo: respaldo });
    expect(r.body).toEqual({ ok: true, pendiente: true });
    expect(enviar.mock.calls[0][0]).toBe(respaldo);
    expect(enviar.mock.calls[0][2]).toBe('respaldo');
    expect(await cuidador(u)).toMatchObject({ respaldoPendiente: true, correoRespaldoVerificado: false });
    expect((await fila(u.uid)).correo_respaldo_hash).toBeNull();

    enviar.mockClear();
    await request(app).post('/api/auth/recuperar-por-respaldo').send({ correo: respaldo });
    expect(enviar).not.toHaveBeenCalled();
  });

  test('el correo no se guarda en claro y al confirmar queda el HMAC', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    enviar.mockClear();
    const respaldo = `claro-${unico()}@prueba.cl`;
    await request(app).post('/api/correo-respaldo').set(con(u)).send({ correo: respaldo });
    const enlace = enviar.mock.calls[0][1];
    const { rows } = await db.consulta('SELECT * FROM tokens_correo WHERE token_hash = $1', [sha256(tokenDe(enlace))]);
    expect(rows[0].tipo).toBe('respaldo');
    expect(rows[0].respaldo_hash).toMatch(/^[0-9a-f]{64}$/);
    expect(rows[0].correo_nuevo).toBeNull();
    expect(JSON.stringify(rows[0])).not.toContain(respaldo);

    expect((await request(app).post(rutaDe(enlace))).status).toBe(200);
    expect(await cuidador(u)).toMatchObject({ respaldoPendiente: false, correoRespaldoVerificado: true });
    expect(JSON.stringify(await fila(u.uid))).not.toContain(respaldo);
    enviar.mockClear();
    await request(app).post('/api/auth/recuperar-por-respaldo').send({ correo: respaldo });
    expect(enviar).toHaveBeenCalledTimes(1);
    expect((await request(app).post(rutaDe(enlace))).status).toBe(400);
  });

  test('el respaldo anterior sigue valido hasta confirmar el nuevo', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    enviar.mockClear();
    const viejo = `v-${unico()}@prueba.cl`;
    const nuevo = `n-${unico()}@prueba.cl`;
    await request(app).post('/api/correo-respaldo').set(con(u)).send({ correo: viejo });
    await request(app).post(rutaDe(enviar.mock.calls[0][1]));
    await request(app).post('/api/correo-respaldo').set(con(u)).send({ correo: nuevo });
    expect(await cuidador(u)).toMatchObject({ respaldoPendiente: true, correoRespaldoVerificado: true });
    enviar.mockClear();
    await request(app).post('/api/auth/recuperar-por-respaldo').send({ correo: viejo });
    expect(enviar).toHaveBeenCalledTimes(1);
  });
});

describe('verificacion del correo de registro', () => {
  test('el registro envia el enlace y confirmarlo marca correo_verificado', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    expect(enviar).toHaveBeenCalledTimes(1);
    expect(enviar.mock.calls[0][0]).toBe(u.correo);
    expect(enviar.mock.calls[0][2]).toBe('verificar');
    expect((await cuidador(u)).correoVerificado).toBe(false);
    expect((await request(app).post(rutaDe(enviar.mock.calls[0][1]))).status).toBe(200);
    expect((await cuidador(u)).correoVerificado).toBe(true);
    const r = await request(app).post('/api/auth/reenviar-verificacion').set(con(u));
    expect(r.body).toEqual({ ok: true, verificado: true });
    expect(enviar).toHaveBeenCalledTimes(1);
  });

  test('el registro funciona aunque falle el envio', async () => {
    jest.spyOn(correo, 'enviarEnlace').mockRejectedValue(new Error('smtp caido'));
    jest.spyOn(console, 'error').mockImplementation(() => {});
    const r = await request(app).post('/api/auth/registro').send({ correo: `s-${unico()}@prueba.cl`, contrasena: 'secreta1' });
    expect(r.status).toBe(201);
    expect(r.body.token).toBeTruthy();
  });

  test('reenviar-verificacion exige sesion, respeta el limite de 60 s e invalida el enlace anterior', async () => {
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const u = await crearUsuario();
    expect((await request(app).post('/api/auth/reenviar-verificacion')).status).toBe(401);
    expect((await request(app).post('/api/auth/reenviar-verificacion').set(con(u))).status).toBe(429);
    await db.consulta("UPDATE tokens_correo SET creado_en = now() - interval '61 seconds' WHERE usuario_id = $1", [u.uid]);
    expect((await request(app).post('/api/auth/reenviar-verificacion').set(con(u))).body).toEqual({ ok: true });
    expect(enviar).toHaveBeenCalledTimes(2);
    expect((await request(app).post('/api/auth/reenviar-verificacion').set(con(u))).status).toBe(429);
    expect((await request(app).post(rutaDe(enviar.mock.calls[0][1]))).status).toBe(400);
    expect((await request(app).post(rutaDe(enviar.mock.calls[1][1]))).status).toBe(200);
    expect((await cuidador(u)).correoVerificado).toBe(true);
  });
});
