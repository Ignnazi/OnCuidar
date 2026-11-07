const { db, cerrar } = require('./ayudas');
const { cargarMaterial, generarId } = require('../../backend/scripts/cargar_material');
const lista = require('../../backend/scripts/material_educativo.json');

afterAll(cerrar);

describe('carga del material educativo', () => {
  test('retira lo que ya no está en el JSON y actualiza lo que sí', async () => {
    await db.consulta(
      `INSERT INTO material_educativo (id, titulo, url_archivo, creado_en)
       VALUES ('manual-retirado', 'Manual retirado', '/archivos/guias/manual-control-sintomas.pdf', now())
       ON CONFLICT (id) DO NOTHING`);
    const primero = lista[0];
    const idPrimero = primero.id ?? generarId(primero.titulo);
    await db.consulta(
      `INSERT INTO material_educativo (id, titulo, creado_en) VALUES ($1, 'Título viejo', now())
       ON CONFLICT (id) DO UPDATE SET titulo = 'Título viejo'`, [idPrimero]);

    const n = await cargarMaterial();

    expect(n).toBe(lista.length);
    const { rows } = await db.consulta('SELECT id, titulo FROM material_educativo');
    expect(rows.map((r) => r.id)).not.toContain('manual-retirado');
    expect(rows).toHaveLength(lista.length);
    expect(rows.find((r) => r.id === idPrimero).titulo).toBe(primero.titulo);
  });
});
