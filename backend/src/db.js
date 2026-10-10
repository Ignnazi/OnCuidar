// Pool de conexiones a PostgreSQL
const { Pool } = require('pg');
const config = require('./config');

const pool = new Pool({ connectionString: config.databaseUrl });

module.exports = {
  pool,
  consulta: (texto, params) => pool.query(texto, params),
};
