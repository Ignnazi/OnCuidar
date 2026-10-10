// Ayudas compartidas por las pruebas
const crypto = require('crypto');
const request = require('supertest');
const app = require('../src/app');
const db = require('../src/db');

const unico = () => crypto.randomBytes(5).toString('hex');

async function crearUsuario(prefijo = 'u') {
  const correo = `${prefijo}-${unico()}@prueba.cl`;
  const r = await request(app).post('/api/auth/registro').send({ correo, contrasena: 'secreta1' });
  return { correo, contrasena: 'secreta1', token: r.body.token, uid: r.body.uid };
}

const con = (u) => ({ Authorization: `Bearer ${u.token}` });

async function cerrar() {
  await db.pool.end();
}

async function limpiar() {
  await db.consulta("DELETE FROM usuarios WHERE correo LIKE '%@prueba.cl'");
  await db.consulta('DELETE FROM esperas_recuperacion');
}

module.exports = { app, request, db, unico, crearUsuario, con, cerrar, limpiar };
