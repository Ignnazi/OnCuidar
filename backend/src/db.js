// Pool de conexiones a PostgreSQL
const { Pool } = require('pg');
const config = require('./config');

// Con limites de tiempo la API responde con error en vez de colgarse si cae la BD
const pool = new Pool({
  connectionString: config.databaseUrl,
  connectionTimeoutMillis: config.dbTiempoConexionMs,
  query_timeout: config.dbTiempoConsultaMs,
  statement_timeout: config.dbTiempoConsultaMs,
  idleTimeoutMillis: config.dbTiempoOcioMs,
  idle_in_transaction_session_timeout: config.dbTiempoTransaccionOciosaMs,
});

// Sin este manejador, un cliente inactivo que pierde la conexion bota el proceso
pool.on('error', (err) => {
  console.error('[db] cliente inactivo del pool:', err.message);
});

async function transaccion(fn) {
  const cliente = await pool.connect();
  let errorConexion;
  try {
    await cliente.query('BEGIN');
    const resultado = await fn(cliente);
    await cliente.query('COMMIT');
    return resultado;
  } catch (e) {
    // Si el ROLLBACK tambien falla la conexion quedo rota y no vuelve al pool
    await cliente.query('ROLLBACK').catch((err) => { errorConexion = err; });
    throw e;
  } finally {
    cliente.release(errorConexion);
  }
}

module.exports = {
  pool,
  consulta: (texto, params) => pool.query(texto, params),
  transaccion,
};
