const { app, request, crearUsuario, con, cerrar, limpiar } = require('./ayudas');

let u;

beforeAll(async () => {
  u = await crearUsuario('nivel');
  await request(app).put('/api/pacientes/pn').set(con(u)).send({ cifrados: { nombre_cifrado: 'x' } });
});
afterAll(async () => { await limpiar(); await cerrar(); });

const put = (ruta, cuerpo) => request(app).put(`/api/pacientes/pn/${ruta}`).set(con(u)).send(cuerpo);

describe('nivel de alerta cifrado', () => {
  test('un registro nuevo guarda el nivel cifrado y nada en claro', async () => {
    const r = await put('registros/n1', {
      fecha: '2026-11-07T10:00:00.000Z', nivelAlerta: null, cifrados: { nivel_alerta_cifrado: 'AAA' },
    });
    expect(r.status).toBe(200);
    expect(r.body.nivelAlerta).toBeNull();
    expect(r.body.cifrados.nivel_alerta_cifrado).toBe('AAA');
    expect(r.body.fecha).toBe('2026-11-07T10:00:00.000Z');
  });

  test('al reescribir un registro antiguo se borra el nivel en claro', async () => {
    await put('registros/v1', { nivelAlerta: 'critico', cifrados: {} });
    const r = await put('registros/v1', { nivelAlerta: null, cifrados: { nivel_alerta_cifrado: 'BBB' } });
    expect(r.body.nivelAlerta).toBeNull();
    expect(r.body.cifrados.nivel_alerta_cifrado).toBe('BBB');
  });

  test('las versiones anteriores de la app siguen pudiendo guardar en claro', async () => {
    const r = await put('registros/v2', { nivelAlerta: 'alerta', cifrados: {} });
    expect(r.status).toBe(200);
    expect(r.body.nivelAlerta).toBe('alerta');
  });
});
