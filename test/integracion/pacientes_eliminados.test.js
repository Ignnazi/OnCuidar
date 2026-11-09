const { app, request, db, crearUsuario, con, cerrar, limpiar } = require('./ayudas');

let u;

beforeAll(async () => { u = await crearUsuario('borrados'); });
afterAll(async () => { await limpiar(); await cerrar(); });

const put = (ruta, cuerpo) => request(app).put(`/api/${ruta}`).set(con(u)).send(cuerpo);
const borrar = (ruta) => request(app).delete(`/api/${ruta}`).set(con(u));

describe('paciente eliminado', () => {
  test('PI-04 un PUT posterior responde 410 y no lo vuelve a crear', async () => {
    expect((await put('pacientes/pb1', { cifrados: { nombre_cifrado: 'x' } })).status).toBe(200);
    expect((await borrar('pacientes/pb1')).status).toBe(200);

    const r = await put('pacientes/pb1', { archivado: true, cifrados: { nombre_cifrado: 'x' } });
    expect(r.status).toBe(410);
    expect(r.body.error).toBe('El paciente fue eliminado');
    const { rows } = await db.consulta('SELECT 1 FROM pacientes WHERE usuario_id = $1 AND id = $2', [u.uid, 'pb1']);
    expect(rows).toHaveLength(0);
    expect((await request(app).get('/api/pacientes').set(con(u))).body.map((p) => p.id)).not.toContain('pb1');
  });

  test('registros y recordatorios del paciente eliminado responden 410', async () => {
    await put('pacientes/pb2', {});
    expect((await borrar('pacientes/pb2')).status).toBe(200);
    expect((await put('pacientes/pb2/registros/r1', { cifrados: {} })).status).toBe(410);
    expect((await put('pacientes/pb2/recordatorios/rc1', { cifrados: {} })).status).toBe(410);
    for (const t of ['registros_clinicos', 'recordatorios']) {
      const { rows } = await db.consulta(`SELECT 1 FROM ${t} WHERE usuario_id = $1 AND paciente_id = 'pb2'`, [u.uid]);
      expect(rows).toHaveLength(0);
    }
  });

  test('un paciente que nunca existio sigue dando 404 en sus registros', async () => {
    expect((await put('pacientes/nunca/registros/r1', { cifrados: {} })).status).toBe(404);
  });

  test('la lapida es por usuario', async () => {
    const otro = await crearUsuario('borrados');
    await put('pacientes/pb3', {});
    expect((await borrar('pacientes/pb3')).status).toBe(200);
    const r = await request(app).put('/api/pacientes/pb3').set(con(otro)).send({});
    expect(r.status).toBe(200);
  });

  test('un PUT de un paciente normal sigue haciendo upsert', async () => {
    expect((await put('pacientes/pb4', { maximoRegistrosDia: 2 })).body.maximoRegistrosDia).toBe(2);
    expect((await put('pacientes/pb4', { maximoRegistrosDia: 5 })).body.maximoRegistrosDia).toBe(5);
  });

  test('borrar dos veces da 404 la segunda', async () => {
    await put('pacientes/pb5', {});
    expect((await borrar('pacientes/pb5')).status).toBe(200);
    expect((await borrar('pacientes/pb5')).status).toBe(404);
  });
});

describe('paciente eliminado durante el guardado', () => {
  afterEach(() => jest.restoreAllMocks());

  const fallarInsercion = (tabla) => {
    const original = db.consulta;
    jest.spyOn(db, 'consulta').mockImplementation((sql, params) => {
      if (sql.startsWith(`INSERT INTO ${tabla} `)) {
        return Promise.reject(Object.assign(new Error('violación de llave foránea'), { code: '23503' }));
      }
      return original.call(db, sql, params);
    });
  };

  test.each(['registros', 'recordatorios'])('un %s responde 410 si la llave foránea falla', async (ruta) => {
    await put('pacientes/pb6', {});
    fallarInsercion(ruta === 'registros' ? 'registros_clinicos' : 'recordatorios');
    const r = await put(`pacientes/pb6/${ruta}/x1`, { cifrados: {} });
    expect(r.status).toBe(410);
    expect(r.body.error).toBe('El paciente fue eliminado');
  });

  test('otro error del guardado sigue respondiendo 500', async () => {
    await put('pacientes/pb7', {});
    const original = db.consulta;
    jest.spyOn(db, 'consulta').mockImplementation((sql, params) => {
      if (sql.startsWith('INSERT INTO registros_clinicos ')) return Promise.reject(new Error('caída'));
      return original.call(db, sql, params);
    });
    expect((await put('pacientes/pb7/registros/x1', { cifrados: {} })).status).toBe(500);
  });
});
