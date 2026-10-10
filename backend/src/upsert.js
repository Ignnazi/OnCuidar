const db = require('./db');

async function upsert({ tabla, claves, campos, cifrados }) {
  const cols = [...Object.keys(claves)];
  const vals = [...Object.values(claves)];
  const actualizar = [];
  for (const [col, val] of Object.entries(campos)) {
    if (val === undefined) continue;
    cols.push(col);
    vals.push(val);
    actualizar.push(`${col} = EXCLUDED.${col}`);
  }
  cols.push('cifrados');
  vals.push(JSON.stringify(cifrados.poner));
  vals.push(cifrados.borrar);
  actualizar.push(`cifrados = (${tabla}.cifrados || EXCLUDED.cifrados) - $${vals.length}::text[]`);
  const marcas = cols.map((_, i) => `$${i + 1}${cols[i] === 'cifrados' ? '::jsonb' : ''}`);
  const sql = `INSERT INTO ${tabla} (${cols.join(', ')}) VALUES (${marcas.join(', ')})
    ON CONFLICT (${Object.keys(claves).join(', ')}) DO UPDATE SET ${actualizar.join(', ')}
    RETURNING *`;
  const { rows } = await db.consulta(sql, vals);
  return rows[0];
}

const iso = (d) => (d ? new Date(d).toISOString() : null);

module.exports = { upsert, iso };
