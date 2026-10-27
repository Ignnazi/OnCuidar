// Envia registros a la API a traves de Toxiproxy con la red lenta y cortes al azar.
// Reintenta cada registro igual que la cola de la app y al final revisa en la API
// directa que llegaron todos, una sola vez y en orden.
const http = require('http');
const crypto = require('crypto');

const API = 'http://localhost:8080/api';
const PROXY = 'http://localhost:8090/api';
const TOXIPROXY = 'http://localhost:8474';
const TOTAL = Number(process.env.TOTAL_REGISTROS || 30);

function pedir(base, metodo, ruta, { token, cuerpo, limiteMs = 3000 } = {}) {
  const url = new URL(base + ruta);
  const datos = cuerpo === undefined ? null : JSON.stringify(cuerpo);
  return new Promise((resolver, rechazar) => {
    const req = http.request(url, {
      method: metodo,
      agent: false,
      timeout: limiteMs,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
      },
    }, (res) => {
      let texto = '';
      res.on('data', (parte) => { texto += parte; });
      res.on('end', () => resolver({ estado: res.statusCode, cuerpo: texto ? JSON.parse(texto) : null }));
      res.on('error', rechazar);
    });
    req.on('timeout', () => req.destroy(new Error('tiempo agotado')));
    req.on('error', rechazar);
    if (datos) req.write(datos);
    req.end();
  });
}

async function toxiproxy(metodo, ruta, cuerpo) {
  const r = await pedir(TOXIPROXY, metodo, ruta, { cuerpo });
  if (r.estado >= 400 && r.estado !== 404 && r.estado !== 409) {
    throw new Error(`Toxiproxy respondio ${r.estado} en ${ruta}`);
  }
}

async function prepararRed() {
  await toxiproxy('DELETE', '/proxies/api');
  await toxiproxy('POST', '/proxies', { name: 'api', listen: '0.0.0.0:8090', upstream: 'api:3000' });
  await toxiproxy('POST', '/proxies/api/toxics', {
    name: 'lenta', type: 'latency', stream: 'downstream', attributes: { latency: 800, jitter: 400 },
  });
  await toxiproxy('POST', '/proxies/api/toxics', {
    name: 'cortes', type: 'reset_peer', stream: 'downstream', toxicity: 0.3, attributes: { timeout: 0 },
  });
}

// Reintenta hasta que la API confirme, como hace la cola de escrituras
async function enviarConReintentos(token, ruta, cuerpo) {
  for (let intento = 1; intento <= 20; intento++) {
    try {
      const r = await pedir(PROXY, 'PUT', ruta, { token, cuerpo });
      if (r.estado === 200) return intento;
      if (r.estado < 500) throw new Error(`La API rechazo ${ruta} con ${r.estado}`);
    } catch (e) {
      if (e.message.startsWith('La API rechazo')) throw e;
    }
  }
  throw new Error(`No se pudo enviar ${ruta}`);
}

async function main() {
  const correo = `caos-${crypto.randomBytes(4).toString('hex')}@prueba.cl`;
  const alta = await pedir(API, 'POST', '/auth/registro', { cuerpo: { correo, contrasena: 'secreta1' } });
  const { token } = alta.cuerpo;
  await pedir(API, 'PUT', '/pacientes/p1', { token, cuerpo: { cifrados: { nombre_cifrado: 'x' } } });

  await prepararRed();
  const inicio = Date.parse('2026-10-26T12:00:00Z');
  let reintentos = 0;
  for (let i = 1; i <= TOTAL; i++) {
    const intentos = await enviarConReintentos(token, `/pacientes/p1/registros/r${i}`, {
      creadoEn: new Date(inicio + i * 1000).toISOString(),
      cifrados: { datos_cifrados: `dato-${i}` },
    });
    reintentos += intentos - 1;
  }
  await toxiproxy('DELETE', '/proxies/api');

  const lista = await pedir(API, 'GET', `/pacientes/p1/registros?limite=${TOTAL + 10}`, { token });
  const ids = lista.cuerpo.map((r) => r.id).reverse();
  const esperado = Array.from({ length: TOTAL }, (_, i) => `r${i + 1}`);
  console.log(`Registros enviados: ${TOTAL}, reintentos por cortes: ${reintentos}, en el servidor: ${ids.length}`);

  if (ids.length !== TOTAL) throw new Error(`Se esperaban ${TOTAL} registros y hay ${ids.length}`);
  if (new Set(ids).size !== ids.length) throw new Error('Hay registros duplicados');
  if (ids.join() !== esperado.join()) throw new Error('Los registros no quedaron en orden');
  console.log('Todos llegaron una sola vez y en orden');
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
