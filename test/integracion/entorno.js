process.env.DATABASE_URL = process.env.DATABASE_URL_PRUEBAS
  || 'postgres://pruebas:pruebas@localhost:5433/oncuidar_pruebas';
process.env.JWT_SECRETO = 'secreto-de-pruebas-largo-123';
process.env.CLAVE_MAESTRA = Buffer.alloc(32, 7).toString('base64');
process.env.HMAC_CORREO = 'hmac-de-pruebas';
process.env.LIMITE_AUTH = '100000';
process.env.URL_PUBLICA = 'http://localhost:8080';
