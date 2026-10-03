const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'oncuidar-v1';
const COLLECTION = 'materialEducativo';
const SEED_FILE = path.join(__dirname, 'material_educativo.json');

const items = JSON.parse(fs.readFileSync(SEED_FILE, 'utf-8'));
console.log(`Leidos ${items.length} items desde ${SEED_FILE}`);

function toFirestoreDocument(item) {
  const fields = {};
  for (const [key, value] of Object.entries(item)) {
    if (key === 'creadoEn') {
      fields[key] = { timestampValue: new Date().toISOString() };
    } else if (key === 'tamanoBytes') {
      fields[key] = { integerValue: value };
    } else {
      fields[key] = { stringValue: String(value) };
    }
  }
  if (!fields.creadoEn) {
    fields.creadoEn = { timestampValue: new Date().toISOString() };
  }
  return { fields };
}

function getAccessToken() {
  const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    '.config',
    'configstore',
    'firebase-tools.json'
  );
  if (!fs.existsSync(configPath)) {
    throw new Error('No se encuentra firebase-tools.json. Ejecuta: firebase login');
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
  const token = config.tokens?.access_token;
  if (!token) {
    throw new Error('No hay access_token en firebase-tools.json. Ejecuta: firebase login');
  }
  return token;
}

function docId(item) {
  const cleanTitle = item.titulo
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  return `${item.categoria.toLowerCase()}-${cleanTitle}`;
}

async function uploadItem(accessToken, item, index) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}`;
  const id = docId(item);
  const body = toFirestoreDocument(item);
  const response = await fetch(`${url}?documentId=${id}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    const err = await response.text();
    if (response.status === 409) {
      console.log(`  [${index}/${items.length}] ${id} ya existe`);
      return;
    }
    throw new Error(`HTTP ${response.status} para ${id}: ${err}`);
  }
  console.log(`  [${index}/${items.length}] ${id}`);
}

async function main() {
  const accessToken = getAccessToken();
  console.log(`Subiendo ${items.length} items a ${PROJECT_ID}/${COLLECTION}...`);
  for (let i = 0; i < items.length; i++) {
    await uploadItem(accessToken, items[i], i + 1);
    await new Promise((r) => setTimeout(r, 150));
  }
  console.log('Todo el contenido educativo subido exitosamente');
}

main().catch((error) => {
  console.error(`Error: ${error.message}`);
  process.exit(1);
});