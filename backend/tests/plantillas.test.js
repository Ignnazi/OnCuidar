const { app, request, db, unico, cerrar, limpiar } = require('./ayudas');
const plantillas = require('../src/plantillas');

afterAll(async () => { await limpiar(); await cerrar(); });

const ENLACE = 'https://oncuidar.cl/api/auth/restablecer?token=abc123&x=1';
const ASUNTOS = {
  restablecer: 'Restablece tu contraseña de OnCuidar',
  verificar: 'Confirma tu correo en OnCuidar',
  cambio: 'Confirma tu nuevo correo en OnCuidar',
  respaldo: 'Confirma tu correo de respaldo en OnCuidar',
};

describe('correos', () => {
  test.each(Object.keys(ASUNTOS))('plantilla %s: asunto, enlace, logo CID y texto plano', (tipo) => {
    const c = plantillas.armarCorreo(tipo, ENLACE);
    expect(c.asunto).toBe(ASUNTOS[tipo]);
    expect(c.html).toContain('href="https://oncuidar.cl/api/auth/restablecer?token=abc123&amp;x=1"');
    expect(c.html).toContain('cid:logo-oncuidar');
    expect(c.html).toContain('prefers-color-scheme: dark');
    expect(c.html).toContain('Este enlace vence en 1 hora y solo se puede usar una vez.');
    expect(c.html).toContain('Si no fuiste tú, ignora este mensaje: tu cuenta sigue segura.');
    expect(c.html).toContain('Mensaje automático de OnCuidar, por favor no respondas a este correo.');
    expect(c.texto).toContain(ENLACE);
    expect(c.texto).not.toContain('<');
    expect(c.texto).toContain('Si no fuiste tú');
  });

  test('tipo desconocido falla', () => {
    expect(() => plantillas.armarCorreo('otro', ENLACE)).toThrow('Plantilla de correo desconocida');
  });

  test('escapa HTML hostil en todos los parametros', () => {
    const mal = '<script>alert(1)</script>';
    const html = plantillas.correoHtml({ asunto: mal, previa: mal, titulo: mal, parrafos: [mal], boton: { texto: mal, url: 'https://a.cl/?q="><img src=x>' }, aviso: mal, pie: mal });
    expect(html).not.toContain('<script>');
    expect(html).not.toContain('<img src=x>');
    expect(html).toContain('&lt;script&gt;');
  });

  test('rechaza enlaces que no son http/https', () => {
    for (const url of ['javascript:alert(1)', 'data:text/html,hola', 'ftp://x.cl', 'no es url', '']) {
      expect(() => plantillas.correoHtml({ titulo: 't', boton: { texto: 'b', url } })).toThrow('Enlace no válido');
      expect(() => plantillas.correoTexto({ titulo: 't', boton: { texto: 'b', url } })).toThrow('Enlace no válido');
    }
  });

  test('el logo reducido pesa menos de 25 KB', () => {
    expect(plantillas.LOGO_PNG.length).toBeLessThan(25 * 1024);
    expect(plantillas.LOGO_PNG.subarray(1, 4).toString()).toBe('PNG');
  });
});

describe('paginas web', () => {
  test('paginaHtml escapa titulo y mensaje e incluye el logo', () => {
    const h = plantillas.paginaHtml({ titulo: '<b>x</b>', mensaje: '<script>1</script>', icono: 'exito' });
    expect(h).not.toContain('<script>1');
    expect(h).toContain('&lt;b&gt;x&lt;/b&gt;');
    expect(h).toContain('data:image/png;base64,');
    expect(h).toContain('<svg');
  });

  test('GET restablecer valido: 200, titulo, logo, formulario y CSP con nonce', async () => {
    const r = await request(app).get(`/api/auth/restablecer?token=${'a'.repeat(64)}`);
    expect(r.status).toBe(200);
    expect(r.text).toContain('<title>Crea tu nueva contraseña - OnCuidar</title>');
    expect(r.text).toContain('data:image/png;base64,');
    expect(r.text).toContain('Repite la contraseña');
    expect(r.text).toContain('Tu contraseña fue actualizada. Ya puedes volver a la app de OnCuidar e iniciar sesión.');
    const csp = r.headers['content-security-policy'];
    expect(csp).toContain("default-src 'none'");
    expect(csp).toContain('img-src data:');
    expect(csp).toContain("connect-src 'self'");
    expect(csp).not.toContain('unsafe-eval');
    expect(csp).not.toContain('unsafe-inline');
    const nonce = /script-src 'nonce-([^']+)'/.exec(csp)[1];
    expect(r.text).toContain(`<script nonce="${nonce}">`);
    expect(r.text).toContain(`<style nonce="${nonce}">`);
  });

  test('GET restablecer con token malo: 400 con pagina de error', async () => {
    const r = await request(app).get('/api/auth/restablecer?token=x');
    expect(r.status).toBe(400);
    expect(r.text).toContain('<title>Enlace inválido o vencido - OnCuidar</title>');
    expect(r.text).toContain('data:image/png;base64,');
    expect(r.headers['content-security-policy']).not.toContain('script-src');
  });

  test('GET confirmar-correo: error 400 con titulo y CSP estricta', async () => {
    const r = await request(app).get('/api/auth/confirmar-correo?token=x');
    expect(r.status).toBe(400);
    expect(r.text).toContain('<title>Enlace inválido o vencido - OnCuidar</title>');
    expect(r.headers['content-security-policy']).toContain("default-src 'none'");
    expect(r.headers['content-security-policy']).toContain('img-src data:');
  });

  test('confirmar-correo valido: 200 con titulo de exito', async () => {
    const correo = require('../src/correo');
    const enviar = jest.spyOn(correo, 'enviarEnlace').mockResolvedValue();
    const email = `p-${unico()}@prueba.cl`;
    await request(app).post('/api/auth/registro').send({ correo: email, contrasena: 'secreta1' });
    await new Promise((r) => setTimeout(r, 200));
    const llamada = enviar.mock.calls.find((c) => c[0] === email);
    enviar.mockRestore();
    const url = new URL(llamada[1]);
    const r = await request(app).get(url.pathname + url.search);
    expect(r.status).toBe(200);
    expect(r.text).toContain('<title>¡Correo confirmado! - OnCuidar</title>');
    expect(r.text).toContain('Puedes cerrar esta pestaña y volver a la app');
    await db.consulta('SELECT 1');
  });
});
