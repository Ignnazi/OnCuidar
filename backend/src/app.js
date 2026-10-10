const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const db = require('./db');

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));

const api = express.Router();
api.get('/salud', async (_req, res) => {
  await db.consulta('SELECT 1');
  res.json({ ok: true });
});
api.use(require('./rutas/auth'));
api.use(require('./rutas/cuidador'));
api.use(require('./rutas/pacientes'));
api.use(require('./rutas/conversaciones'));
api.use(require('./rutas/biblioteca'));
app.use('/api', api);

app.use('/archivos', (_req, res, next) => {
  res.set('Cross-Origin-Resource-Policy', 'cross-origin');
  next();
}, express.static(path.join(__dirname, '..', 'archivos'), {
  index: false,
  dotfiles: 'ignore',
  redirect: false,
  maxAge: '7d',
  immutable: false,
}));

app.use((_req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));

// Manejo central de errores
app.use((err, _req, res, _next) => {
  if (err.estado) return res.status(err.estado).json({ error: err.message });
  if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'JSON inválido' });
  if (err.type === 'entity.too.large') return res.status(413).json({ error: 'Cuerpo demasiado grande' });
  console.error(err);
  res.status(500).json({ error: 'Error interno del servidor' });
});

module.exports = app;
