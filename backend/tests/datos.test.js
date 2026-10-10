const { app, request, db, crearUsuario, con, cerrar, limpiar } = require('./ayudas');

let a;
let b;

beforeAll(async () => {
  a = await crearUsuario('a');
  b = await crearUsuario('b');
});
afterAll(async () => { await limpiar(); await cerrar(); });

const put = (u, ruta, cuerpo) => request(app).put(`/api/${ruta}`).set(con(u)).send(cuerpo);
const get = (u, ruta) => request(app).get(`/api/${ruta}`).set(con(u));

describe('aislamiento entre usuarios', () => {
  test('B no ve ni toca datos de A', async () => {
    await put(a, 'pacientes/pa', { cifrados: { nombre_cifrado: 'x' } });
    await put(a, 'pacientes/pa/registros/r1', { cifrados: { datos_cifrados: 'y' } });
    await put(a, 'pacientes/pa/recordatorios/rc1', { cifrados: { datos_cifrados: 'z' } });
    await put(a, 'conversaciones/c1', { cifrados: { datos_cifrados: 'w' } });

    expect((await get(b, 'pacientes')).body).toEqual([]);
    expect((await get(b, 'pacientes/pa/registros')).status).toBe(404);
    expect((await get(b, 'pacientes/pa/recordatorios')).status).toBe(404);
    expect((await put(b, 'pacientes/pa/registros/r1', { cifrados: { datos_cifrados: 'hack' } })).status).toBe(404);
    expect((await put(b, 'pacientes/pa/recordatorios/rc1', {})).status).toBe(404);
    expect((await request(app).delete('/api/pacientes/pa/registros/r1').set(con(b))).status).toBe(404);
    expect((await request(app).delete('/api/pacientes/pa').set(con(b))).status).toBe(404);
    expect((await get(b, 'conversaciones')).body).toEqual([]);
    expect((await request(app).delete('/api/conversaciones/c1').set(con(b))).status).toBe(404);

    // lo de A sigue intacto
    expect((await get(a, 'pacientes/pa/registros')).body[0].cifrados.datos_cifrados).toBe('y');
    expect((await get(a, 'conversaciones')).body).toHaveLength(1);
  });

  test('el mismo id de paciente en otro usuario crea un recurso independiente', async () => {
    await put(b, 'pacientes/pa', { cifrados: { nombre_cifrado: 'distinto' } });
    expect((await get(a, 'pacientes')).body[0].cifrados.nombre_cifrado).toBe('x');
    expect((await get(b, 'pacientes')).body[0].cifrados.nombre_cifrado).toBe('distinto');
  });
});

describe('campos clinicos en claro', () => {
  test.each([
    ['pacientes/p9', { nombreCompleto: 'Ana' }],
    ['pacientes/p9', { rut: '1-9', cifrados: { nombre_cifrado: 'x' } }],
    ['pacientes/pa/registros/r9', { generalNotes: 'hola' }],
    ['pacientes/pa/registros/r9', { sintomas: [] }],
    ['pacientes/pa/recordatorios/rc9', { titulo: 'Remedio' }],
    ['conversaciones/c9', { mensajes: [] }],
    ['cuidador', { nombre: 'Maria' }],
    ['cuidador', { correo_respaldo: 'a@b.cl' }],
  ])('rechaza %s con %j', async (ruta, cuerpo) => {
    const r = await put(a, ruta, cuerpo);
    expect(r.status).toBe(400);
    expect(r.body.error).toBeTruthy();
  });

  test('en cifrados solo se aceptan claves cifradas con texto', async () => {
    expect((await put(a, 'pacientes/p9', { cifrados: { nombre: 'Ana' } })).status).toBe(400);
    expect((await put(a, 'pacientes/p9', { cifrados: { nombre_cifrado: 123 } })).status).toBe(400);
    expect((await put(a, 'pacientes/p9', { cifrados: { nombre_cifrado: 'ok', edad_cifrada: 'ok' } })).status).toBe(200);
  });
});

describe('registros clinicos', () => {
  test('pacienteId inconsistente es 400', async () => {
    const r = await put(a, 'pacientes/pa/registros/r2', { pacienteId: 'otro', cifrados: {} });
    expect(r.status).toBe(400);
    const ok = await put(a, 'pacientes/pa/registros/r2', { pacienteId: 'pa', cifrados: {} });
    expect(ok.status).toBe(200);
  });

  test('upsert idempotente y merge con null que borra la clave', async () => {
    const cuerpo = {
      fecha: '2026-01-05T10:00:00.000Z', creadoEn: '2026-01-05T10:00:00.000Z', tipoRegistro: 'diario',
      nivelAlerta: 'verde', versionEncriptacion: 2, cifrados: { datos_cifrados: 'AAA', nota_cifrada: 'BBB' },
    };
    const r1 = await put(a, 'pacientes/pa/registros/idem', cuerpo);
    const r2 = await put(a, 'pacientes/pa/registros/idem', cuerpo);
    expect(r1.status).toBe(200);
    expect(r2.body).toEqual(r1.body);
    expect(r1.body.fecha).toBe('2026-01-05T10:00:00.000Z');
    expect((await get(a, 'pacientes/pa/registros?limite=100')).body.filter((x) => x.id === 'idem')).toHaveLength(1);

    const m = await put(a, 'pacientes/pa/registros/idem', { cifrados: { nota_cifrada: null, otra_cifrada: 'CCC' } });
    expect(m.body.cifrados).toEqual({ datos_cifrados: 'AAA', otra_cifrada: 'CCC' });
    expect(m.body.nivelAlerta).toBe('verde');
  });

  test('paginacion por antesDeCreadoEn y rango desde/hasta', async () => {
    await put(a, 'pacientes/pag', {});
    for (let i = 1; i <= 5; i += 1) {
      await put(a, `pacientes/pag/registros/g${i}`, {
        creadoEn: `2026-02-0${i}T12:00:00.000Z`, fecha: `2026-02-0${i}T08:00:00.000Z`, cifrados: {},
      });
    }
    const p1 = (await get(a, 'pacientes/pag/registros?limite=2')).body;
    expect(p1.map((r) => r.id)).toEqual(['g5', 'g4']);
    const p2 = (await get(a, `pacientes/pag/registros?limite=2&antesDeCreadoEn=${p1[1].creadoEn}`)).body;
    expect(p2.map((r) => r.id)).toEqual(['g3', 'g2']);

    const rango = (await get(a, 'pacientes/pag/registros?desde=2026-02-02T08:00:00.000Z&hasta=2026-02-04T08:00:00.000Z')).body;
    expect(rango.map((r) => r.id)).toEqual(['g2', 'g3']);
    expect((await get(a, 'pacientes/pag/registros?desde=basura')).status).toBe(400);
  });
});

describe('pacientes y recordatorios', () => {
  test('filtro de archivados y valores por defecto', async () => {
    const r = await put(a, 'pacientes/arch', { archivado: true });
    expect(r.body.notificacionesActivas).toBe(true);
    expect(r.body.maximoRegistrosDia).toBe(3);
    expect((await get(a, 'pacientes?archivados=true')).body.map((p) => p.id)).toEqual(['arch']);
    expect((await get(a, 'pacientes?archivados=false')).body.map((p) => p.id)).not.toContain('arch');
  });

  test('cascada al borrar paciente', async () => {
    await put(a, 'pacientes/casc', {});
    await put(a, 'pacientes/casc/registros/r1', { cifrados: {} });
    await put(a, 'pacientes/casc/recordatorios/rc1', { activo: false, cifrados: { datos_cifrados: 'q' } });
    expect((await get(a, 'pacientes/casc/recordatorios')).body[0].activo).toBe(false);
    expect((await request(app).delete('/api/pacientes/casc').set(con(a))).status).toBe(200);
    for (const t of ['registros_clinicos', 'recordatorios']) {
      const { rows } = await db.consulta(`SELECT 1 FROM ${t} WHERE usuario_id = $1 AND paciente_id = 'casc'`, [a.uid]);
      expect(rows).toHaveLength(0);
    }
    expect((await get(a, 'pacientes/casc/registros')).status).toBe(404);
  });
});

describe('cuidador y conversaciones', () => {
  test('GET y PUT con merge y null que borra', async () => {
    const r0 = await get(a, 'cuidador');
    expect(r0.body.correo).toBe(a.correo);
    expect(r0.body).toMatchObject({
      respaldoPendiente: false, correoVerificado: false, correoRespaldoVerificado: false, pendienteCorreo: null,
    });
    const r1 = await put(a, 'cuidador', {
      cifrados: { nombre_cifrado: 'N', telefono_cifrado: 'T' }, pendienteCorreo: 'x@y.cl',
      pendienteCorreoTipo: 'cambio', respaldoPendienteServidor: true,
    });
    expect(r1.body.cifrados).toEqual({ nombre_cifrado: 'N', telefono_cifrado: 'T' });
    expect(r1.body.pendienteCorreo).toBeNull();
    expect(r1.body.respaldoPendiente).toBe(false);
    const r2 = await put(a, 'cuidador', { cifrados: { telefono_cifrado: null } });
    expect(r2.body.cifrados).toEqual({ nombre_cifrado: 'N' });
  });

  test('conversaciones ordenadas por ultima actividad', async () => {
    const u = await crearUsuario();
    await put(u, 'conversaciones/vieja', { ultimaActividad: '2026-01-01T00:00:00Z', cifrados: {} });
    await put(u, 'conversaciones/nueva', { ultimaActividad: '2026-06-01T00:00:00Z', cifrados: {} });
    expect((await get(u, 'conversaciones')).body.map((c) => c.id)).toEqual(['nueva', 'vieja']);
    expect((await get(u, 'conversaciones?limite=1')).body).toHaveLength(1);
  });

  test('JSON invalido da 400', async () => {
    const r = await request(app).put('/api/conversaciones/zz').set(con(a)).set('Content-Type', 'application/json').send('{malo');
    expect(r.status).toBe(400);
  });
});

describe('biblioteca y favoritos', () => {
  test('biblioteca solo para autenticados y con fechas ISO', async () => {
    await db.consulta(
      `INSERT INTO material_educativo (id, titulo, tamano_bytes, creado_en)
       VALUES ('mat-prueba', 'Material de prueba', 1234, '2026-01-01T00:00:00Z') ON CONFLICT DO NOTHING`);
    expect((await request(app).get('/api/biblioteca')).status).toBe(401);
    const lista = await get(a, 'biblioteca');
    expect(lista.status).toBe(200);
    const m = lista.body.find((x) => x.id === 'mat-prueba');
    expect(m.creadoEn).toBe('2026-01-01T00:00:00.000Z');
    expect(m.tamanoBytes).toBe(1234);
    expect((await get(a, 'biblioteca/mat-prueba')).body.titulo).toBe('Material de prueba');
    expect((await get(a, 'biblioteca/no-existe')).status).toBe(404);
    await db.consulta("DELETE FROM material_educativo WHERE id = 'mat-prueba'");
  });

  test('favoritos idempotentes y por usuario', async () => {
    const u = await crearUsuario();
    await request(app).put('/api/favoritos/m1').set(con(u));
    await request(app).put('/api/favoritos/m1').set(con(u));
    await request(app).put('/api/favoritos/m2').set(con(u));
    expect((await get(u, 'favoritos')).body.ids.sort()).toEqual(['m1', 'm2']);
    expect((await request(app).delete('/api/favoritos/m1').set(con(u))).status).toBe(200);
    expect((await request(app).delete('/api/favoritos/m1').set(con(u))).status).toBe(200);
    expect((await get(u, 'favoritos')).body.ids).toEqual(['m2']);
    expect((await get(b, 'favoritos')).body.ids).toEqual([]);
  });
});
