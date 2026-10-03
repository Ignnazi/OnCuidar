const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

const UID = 'cuidador1';
const OTRO_UID = 'cuidador2';
const RAIZ = path.resolve(__dirname, '..', '..');

let entorno;

before(async () => {
  const [host, puerto] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  entorno = await initializeTestEnvironment({
    projectId: 'oncuidar-reglas-test',
    firestore: {
      host,
      port: Number(puerto),
      rules: fs.readFileSync(path.join(RAIZ, 'firestore.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await entorno.cleanup();
});

beforeEach(async () => {
  await entorno.clearFirestore();
});

const bd = (uid = UID) => entorno.authenticatedContext(uid).firestore();
const ruta = (coleccion, idPaciente, id) =>
  `users/${UID}/patients/${idPaciente}/${coleccion}/${id}`;

const colecciones = [
  {
    nombre: 'clinicalRecords',
    campo: 'paciente_id',
    valido: (p) => ({ paciente_id: p, tipoRegistro: 'diario', sintomas_cifrado: 'a.b.c' }),
  },
  {
    nombre: 'recordatorios',
    campo: 'pacienteId',
    valido: (p) => ({ pacienteId: p, activo: true, titulo_cifrado: 'a.b.c' }),
  },
];

for (const c of colecciones) {
  test(`${c.nombre}: crear con el paciente de la ruta es aceptado`, async () => {
    await assertSucceeds(setDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), c.valido('A')));
  });

  test(`${c.nombre}: crear declarando otro paciente es rechazado`, async () => {
    await assertFails(setDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), c.valido('B')));
  });

  test(`${c.nombre}: crear sin declarar paciente es rechazado`, async () => {
    const { [c.campo]: _omitido, ...sinPaciente } = c.valido('A');
    await assertFails(setDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), sinPaciente));
  });

  test(`${c.nombre}: actualizar sin cambiar el paciente es aceptado`, async () => {
    await assertSucceeds(setDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), c.valido('A')));
    await assertSucceeds(updateDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), { activo: false }));
  });

  test(`${c.nombre}: reasignar el documento a otro paciente es rechazado`, async () => {
    await assertSucceeds(setDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), c.valido('A')));
    await assertFails(updateDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), { [c.campo]: 'B' }));
  });

  test(`${c.nombre}: borrar sigue permitido para el dueño`, async () => {
    await assertSucceeds(setDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), c.valido('A')));
    await assertSucceeds(deleteDoc(doc(bd(), ruta(c.nombre, 'A', 'd1'))));
  });

  test(`${c.nombre}: otro cuidador no puede escribir en mis pacientes`, async () => {
    await assertFails(
      setDoc(doc(bd(OTRO_UID), ruta(c.nombre, 'A', 'd1')), c.valido('A')),
    );
  });
}

test('clinicalRecords: los campos sensibles en claro siguen prohibidos', async () => {
  await assertFails(
    setDoc(doc(bd(), ruta('clinicalRecords', 'A', 'd1')), {
      paciente_id: 'A',
      observaciones: 'texto en claro',
    }),
  );
});

const sembrarDocLegado = async (coleccion, idPaciente, id, campos) => {
  const [host, puerto] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  const url =
    `http://${host}:${puerto}/v1/projects/oncuidar-reglas-test` +
    `/databases/(default)/documents/users/${UID}/patients/${idPaciente}/${coleccion}/${id}`;
  const fields = {};
  for (const [clave, valor] of Object.entries(campos)) {
    fields[clave] =
      typeof valor === 'boolean' ? { booleanValue: valor } : { stringValue: String(valor) };
  }
  const r = await fetch(url, {
    method: 'PATCH',
    headers: { Authorization: 'Bearer owner', 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  if (!r.ok) {
    throw new Error(`No se pudo sembrar el documento legado: ${r.status} ${await r.text()}`);
  }
};

for (const c of colecciones) {
  test(`${c.nombre}: un documento legado se migra declarando su paciente`, async () => {
    const { [c.campo]: _omitido, ...legado } = c.valido('A');
    await sembrarDocLegado(c.nombre, 'A', 'd1', legado);
    await assertSucceeds(
      updateDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), { [c.campo]: 'A', activo: false }),
    );
  });

  test(`${c.nombre}: un documento legado no se actualiza omitiendo su paciente`, async () => {
    const { [c.campo]: _omitido, ...legado } = c.valido('A');
    await sembrarDocLegado(c.nombre, 'A', 'd1', legado);
    await assertFails(updateDoc(doc(bd(), ruta(c.nombre, 'A', 'd1')), { activo: false }));
  });
}
