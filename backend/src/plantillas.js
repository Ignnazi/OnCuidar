const fs = require('fs');
const path = require('path');

const LOGO_PNG = fs.readFileSync(path.join(__dirname, 'recursos', 'logo-oncuidar.png'));
const LOGO_DATA_URI = `data:image/png;base64,${LOGO_PNG.toString('base64')}`;
const CID_LOGO = 'logo-oncuidar';

const C = {
  dorado: '#D99A16',
  doradoOscuro: '#C08808',
  claro: '#FFF0C2',
  crema: '#FFFBF5',
  texto: '#2C1A00',
  suave: '#6B5A3A',
  naranja: '#FF6B0B',
  amarillo: '#FFD000',
};
const FUENTE = "'Nunito','Segoe UI',Arial,sans-serif";
const PIE_AUTOMATICO = 'Mensaje automático de OnCuidar, por favor no respondas a este correo.';
const PIE_AYUDA = '¿Necesitas ayuda? Vuelve a la app de OnCuidar e intenta de nuevo desde la pantalla de inicio de sesión.';
const LEMA = 'Acompañando a quienes cuidan';

const ESCAPES = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ESCAPES[c]);

function urlSegura(valor) {
  let u;
  try {
    u = new URL(String(valor ?? '').trim());
  } catch {
    throw new Error('Enlace no válido');
  }
  if (u.protocol !== 'http:' && u.protocol !== 'https:') throw new Error('Enlace no válido');
  return u.href;
}

function correoHtml({ asunto, previa = '', titulo, parrafos = [], boton, aviso, pie } = {}) {
  const url = boton ? urlSegura(boton.url) : null;
  const parrafosHtml = parrafos
    .map((p) => `<p class="texto" style="margin:0 0 14px;font-size:16px;line-height:1.55;color:${C.texto};font-family:${FUENTE};">${esc(p)}</p>`)
    .join('');
  const botonHtml = boton ? `
<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:22px 0 8px;"><tr><td align="center">
<!--[if mso]><v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="${esc(url)}" style="height:50px;v-text-anchor:middle;width:280px;" arcsize="24%" stroke="f" fillcolor="${C.dorado}"><w:anchorlock/><center style="color:${C.texto};font-family:Arial,sans-serif;font-size:16px;font-weight:bold;">${esc(boton.texto)}</center></v:roundrect><![endif]-->
<!--[if !mso]><!-- --><a class="boton" href="${esc(url)}" target="_blank" style="display:inline-block;background-color:${C.dorado};color:${C.texto};font-family:${FUENTE};font-size:16px;font-weight:bold;line-height:50px;height:50px;min-width:240px;padding:0 28px;text-align:center;text-decoration:none;border-radius:12px;">${esc(boton.texto)}</a><!--<![endif]-->
</td></tr></table>
<p class="suave" style="margin:14px 0 0;font-size:13px;line-height:1.5;color:${C.suave};font-family:${FUENTE};">Si el botón no funciona, copia y pega este enlace en tu navegador:<br><a class="enlace" href="${esc(url)}" target="_blank" style="color:#8A5A00;word-break:break-all;">${esc(url)}</a></p>` : '';
  const avisoHtml = aviso ? `
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-top:22px;"><tr><td class="aviso" style="background-color:${C.claro};border-radius:10px;padding:12px 16px;font-size:14px;line-height:1.5;color:${C.texto};font-family:${FUENTE};">${esc(aviso)}</td></tr></table>` : '';
  const pieAyuda = pie ?? PIE_AYUDA;

  return `<!doctype html>
<html lang="es" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light dark">
<meta name="supported-color-schemes" content="light dark">
<title>${esc(asunto)}</title>
<!--[if mso]><xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml><![endif]-->
<style>
@media (prefers-color-scheme: dark) {
  body, .fondo { background-color: #1B1200 !important; }
  .tarjeta { background-color: #2A1D06 !important; box-shadow: none !important; }
  .texto, .marca { color: #FFF0C2 !important; }
  .suave, .pie { color: #D9C79A !important; }
  .enlace { color: #F5C451 !important; }
  .aviso { background-color: #3A2A0A !important; color: #FFF0C2 !important; }
  .boton { background-color: #F5C451 !important; color: #2C1A00 !important; }
}
@media only screen and (max-width: 620px) {
  .contenedor { width: 100% !important; }
  .relleno { padding: 24px 20px !important; }
  .boton { display: block !important; min-width: 0 !important; }
}
</style>
</head>
<body class="fondo" style="margin:0;padding:0;background-color:${C.crema};">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;mso-hide:all;">${esc(previa)}&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;</div>
<table role="presentation" class="fondo" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:${C.crema};">
<tr><td align="center" style="padding:28px 12px;">
<table role="presentation" class="contenedor" width="600" cellpadding="0" cellspacing="0" border="0" style="width:600px;max-width:600px;">
<tr><td>
<table role="presentation" class="tarjeta" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#FFFFFF;border-radius:16px;box-shadow:0 2px 12px rgba(44,26,0,0.10);overflow:hidden;">
<tr><td>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
<td width="40%" height="6" bgcolor="${C.naranja}" style="height:6px;line-height:6px;font-size:0;">&nbsp;</td>
<td width="30%" height="6" bgcolor="${C.amarillo}" style="height:6px;line-height:6px;font-size:0;">&nbsp;</td>
<td width="30%" height="6" bgcolor="${C.dorado}" style="height:6px;line-height:6px;font-size:0;">&nbsp;</td>
</tr></table>
</td></tr>
<tr><td class="relleno" style="padding:28px 36px 32px;">
<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:22px;"><tr>
<td style="padding-right:12px;"><img src="cid:${CID_LOGO}" width="56" height="56" alt="OnCuidar" style="display:block;border:0;width:56px;height:56px;"></td>
<td><div class="marca" style="font-family:${FUENTE};font-size:22px;font-weight:bold;line-height:1.2;color:${C.texto};">OnCuidar</div>
<div class="suave" style="font-family:${FUENTE};font-size:13px;line-height:1.4;color:${C.suave};">${esc(LEMA)}</div></td>
</tr></table>
<h1 class="texto" style="margin:0 0 16px;font-size:24px;line-height:1.3;color:${C.texto};font-family:${FUENTE};">${esc(titulo)}</h1>
${parrafosHtml}${botonHtml}${avisoHtml}
</td></tr>
</table>
</td></tr>
<tr><td class="pie" align="center" style="padding:20px 24px 4px;font-family:${FUENTE};font-size:12px;line-height:1.6;color:${C.suave};">
${esc(PIE_AUTOMATICO)}<br>${esc(pieAyuda)}
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;
}

function correoTexto({ titulo, parrafos = [], boton, aviso, pie } = {}) {
  const partes = [`OnCuidar - ${LEMA}`, '', titulo, '', ...parrafos.flatMap((p) => [p, ''])];
  if (boton) partes.push(`${boton.texto}: ${urlSegura(boton.url)}`, '');
  if (aviso) partes.push(aviso, '');
  partes.push('--', PIE_AUTOMATICO, pie ?? PIE_AYUDA);
  return partes.join('\n');
}

const ICONOS = {
  exito: '<svg viewBox="0 0 64 64" width="64" height="64" role="img" aria-label="Éxito"><circle cx="32" cy="32" r="30" fill="#E3F4E7" stroke="#1E7B3A" stroke-width="3"/><path d="M19 33l9 9 17-19" fill="none" stroke="#1E7B3A" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  error: '<svg viewBox="0 0 64 64" width="64" height="64" role="img" aria-label="Error"><circle cx="32" cy="32" r="30" fill="#FCE8E6" stroke="#B3261E" stroke-width="3"/><path d="M22 22l20 20M42 22L22 42" fill="none" stroke="#B3261E" stroke-width="5" stroke-linecap="round"/></svg>',
  info: '<svg viewBox="0 0 64 64" width="64" height="64" role="img" aria-label="Información"><circle cx="32" cy="32" r="30" fill="#FFF0C2" stroke="#8A5A00" stroke-width="3"/><rect x="21" y="29" width="22" height="16" rx="3" fill="#8A5A00"/><path d="M25 29v-5a7 7 0 0114 0v5" fill="none" stroke="#8A5A00" stroke-width="4" stroke-linecap="round"/></svg>',
};

const ESTILOS_PAGINA = `
:root{--fondo:#FFFBF5;--tarjeta:#FFFFFF;--texto:#2C1A00;--suave:#6B5A3A;--borde:#E8DCC0;--dorado:#D99A16;--enlace:#8A5A00;--error:#B3261E}
@media (prefers-color-scheme:dark){:root{--fondo:#1B1200;--tarjeta:#2A1D06;--texto:#FFF0C2;--suave:#D9C79A;--borde:#4A3912;--enlace:#F5C451;--error:#FF9C94}}
*{box-sizing:border-box}
[hidden]{display:none!important}
body{margin:0;min-height:100vh;display:flex;flex-direction:column;align-items:center;background:var(--fondo);color:var(--texto);font-family:${FUENTE};line-height:1.55}
.franja{width:100%;height:6px;background:linear-gradient(90deg,${C.naranja} 0 40%,${C.amarillo} 40% 70%,${C.dorado} 70% 100%)}
header{display:flex;align-items:center;gap:12px;padding:24px 16px 8px}
header img{width:56px;height:56px}
.marca{font-size:1.4rem;font-weight:700;line-height:1.2}
.lema{font-size:.85rem;color:var(--suave)}
main{width:100%;max-width:440px;padding:12px 16px 24px;flex:1}
.tarjeta{background:var(--tarjeta);border-radius:16px;box-shadow:0 2px 14px rgba(44,26,0,.12);padding:28px 24px;text-align:center}
.icono{display:flex;justify-content:center;margin-bottom:12px}
h1{font-size:1.5rem;line-height:1.3;margin:0 0 10px}
.mensaje{margin:0 0 8px}
.suave{color:var(--suave);font-size:.9rem}
form{text-align:left;margin-top:20px}
label{display:block;font-weight:700;margin:14px 0 6px}
.campo{display:flex;gap:8px}
input{flex:1;min-width:0;font:inherit;font-size:1rem;padding:12px;border:2px solid var(--borde);border-radius:10px;background:var(--tarjeta);color:var(--texto)}
input:focus,button:focus-visible{outline:3px solid #1B5FC7;outline-offset:2px}
.ver{flex:none;font:inherit;font-size:.9rem;font-weight:700;padding:0 12px;border:2px solid var(--borde);border-radius:10px;background:transparent;color:var(--enlace);cursor:pointer}
.barras{display:flex;gap:6px;margin-top:10px}
.barras span{flex:1;height:6px;border-radius:3px;background:var(--borde)}
.barras.nivel-1 span:nth-child(-n+1){background:var(--error)}
.barras.nivel-2 span:nth-child(-n+2){background:var(--dorado)}
.barras.nivel-3 span{background:#2E9E4F}
#fuerza{font-size:.85rem;margin:6px 0 0;color:var(--suave)}
.error{color:var(--error);font-weight:700;font-size:.9rem;margin:10px 0 0;min-height:1.2em}
.principal{display:block;width:100%;margin-top:18px;font:inherit;font-weight:700;font-size:1rem;padding:14px;border:0;border-radius:12px;background:var(--dorado);color:#2C1A00;cursor:pointer}
.principal[disabled]{opacity:.7;cursor:progress}
.pasos{text-align:left;margin:14px 0 0;padding-left:20px;color:var(--suave);font-size:.95rem}
footer{padding:8px 16px 28px;font-size:.8rem;color:var(--suave);text-align:center}
`;

function paginaHtml({ titulo, icono = 'info', mensaje = '', cuerpoExtra = '', script = '', nonce = '' } = {}) {
  const n = nonce ? ` nonce="${esc(nonce)}"` : '';
  return `<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>${esc(titulo)} - OnCuidar</title>
<style${n}>${ESTILOS_PAGINA}</style></head>
<body>
<div class="franja"></div>
<header><img src="${LOGO_DATA_URI}" alt="OnCuidar" width="56" height="56"><div><div class="marca">OnCuidar</div><div class="lema">${esc(LEMA)}</div></div></header>
<main><section class="tarjeta">
<div class="icono" id="icono">${ICONOS[icono] ?? ICONOS.info}</div>
<h1 id="titulo">${esc(titulo)}</h1>
<p class="mensaje" id="mensaje">${esc(mensaje)}</p>
${cuerpoExtra}
</section></main>
<footer>OnCuidar · ${esc(LEMA)}</footer>
${script ? `<script${n}>${script}</script>` : ''}
</body></html>`;
}

function cspPagina(nonce, { conScript = false } = {}) {
  return [
    "default-src 'none'",
    `style-src 'nonce-${nonce}'`,
    conScript ? `script-src 'nonce-${nonce}'` : null,
    conScript ? "connect-src 'self'" : null,
    'img-src data:',
    "base-uri 'none'",
    "form-action 'none'",
    "frame-ancestors 'none'",
  ].filter(Boolean).join('; ');
}

const SCRIPT_RESTABLECER = `
(function () {
  var $ = function (id) { return document.getElementById(id); };
  var form = $('f'), c1 = $('c1'), c2 = $('c2'), err = $('error'), btn = $('guardar');
  var barras = $('barras'), fuerza = $('fuerza');
  var token = form.getAttribute('data-token');
  var MIN = 6;
  function nivel(p) {
    if (p.length < MIN) return 1;
    var s = 0;
    if (p.length >= 8) s++;
    if (p.length >= 12) s++;
    if (/[a-z]/.test(p) && /[A-Z]/.test(p)) s++;
    if (/\\d/.test(p)) s++;
    if (/[^A-Za-z0-9]/.test(p)) s++;
    return s >= 4 ? 3 : s >= 2 ? 2 : 1;
  }
  var TEXTOS = { 1: 'Fortaleza: débil', 2: 'Fortaleza: media', 3: 'Fortaleza: fuerte' };
  c1.addEventListener('input', function () {
    var v = c1.value;
    if (!v) { barras.className = 'barras'; fuerza.textContent = 'Usa al menos ' + MIN + ' caracteres.'; return; }
    var n = nivel(v);
    barras.className = 'barras nivel-' + n;
    fuerza.textContent = v.length < MIN ? 'Fortaleza: débil (faltan ' + (MIN - v.length) + ' caracteres)' : TEXTOS[n];
  });
  document.querySelectorAll('.ver').forEach(function (b) {
    b.addEventListener('click', function () {
      var campo = $(b.getAttribute('data-campo'));
      var visible = campo.type === 'text';
      campo.type = visible ? 'password' : 'text';
      b.textContent = visible ? 'Mostrar' : 'Ocultar';
      b.setAttribute('aria-pressed', visible ? 'false' : 'true');
    });
  });
  function vista(tipo) {
    $('vista-form').hidden = true;
    $('icono').innerHTML = $('icono-' + tipo).innerHTML;
    $('titulo').textContent = tipo === 'exito' ? '¡Contraseña actualizada!' : 'Enlace inválido o vencido';
    $('mensaje').textContent = tipo === 'exito'
      ? 'Tu contraseña fue actualizada. Ya puedes volver a la app de OnCuidar e iniciar sesión.'
      : 'Este enlace ya se usó o venció (duran 1 hora).';
    $('vista-' + tipo).hidden = false;
    document.title = $('titulo').textContent + ' - OnCuidar';
  }
  form.addEventListener('submit', function (e) {
    e.preventDefault();
    err.textContent = '';
    if (c1.value.length < MIN) { err.textContent = 'La contraseña debe tener al menos ' + MIN + ' caracteres.'; c1.focus(); return; }
    if (c1.value !== c2.value) { err.textContent = 'Las contraseñas no coinciden. Revisa que sean iguales.'; c2.focus(); return; }
    btn.disabled = true; btn.textContent = 'Guardando...';
    fetch('/api/auth/restablecer-contrasena', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: token, contrasena: c1.value }) })
      .then(function (r) { return r.json().catch(function () { return {}; }).then(function (d) { return { ok: r.ok, d: d }; }); })
      .then(function (x) {
        if (x.ok) return vista('exito');
        if (x.d && x.d.error === 'Enlace inválido o vencido') return vista('error');
        err.textContent = (x.d && x.d.error) || 'No pudimos guardar la contraseña. Intenta de nuevo.';
        btn.disabled = false; btn.textContent = 'Guardar contraseña';
      })
      .catch(function () {
        err.textContent = 'No hay conexión con el servidor. Revisa tu internet e intenta de nuevo.';
        btn.disabled = false; btn.textContent = 'Guardar contraseña';
      });
  });
})();
`;

function paginaRestablecer(token, nonce) {
  const cuerpoExtra = `
<div id="vista-form">
<form id="f" data-token="${esc(token)}" novalidate>
<label for="c1">Nueva contraseña</label>
<div class="campo"><input id="c1" type="password" autocomplete="new-password" required aria-describedby="fuerza"><button type="button" class="ver" data-campo="c1" aria-pressed="false" aria-label="Mostrar u ocultar la nueva contraseña">Mostrar</button></div>
<div class="barras" id="barras" aria-hidden="true"><span></span><span></span><span></span></div>
<p id="fuerza">Usa al menos 6 caracteres.</p>
<label for="c2">Repite la contraseña</label>
<div class="campo"><input id="c2" type="password" autocomplete="new-password" required><button type="button" class="ver" data-campo="c2" aria-pressed="false" aria-label="Mostrar u ocultar la contraseña repetida">Mostrar</button></div>
<p class="error" id="error" role="alert" aria-live="assertive"></p>
<button type="submit" class="principal" id="guardar">Guardar contraseña</button>
</form></div>
<div id="vista-exito" hidden><p class="suave">Puedes cerrar esta pestaña y volver a la app.</p></div>
<div id="vista-error" hidden><ol class="pasos"><li>Vuelve a la app de OnCuidar.</li><li>En el inicio de sesión, elige «Olvidé mi contraseña».</li><li>Pide un enlace nuevo y ábrelo desde tu correo.</li></ol></div>
<template id="icono-exito">${ICONOS.exito}</template>
<template id="icono-error">${ICONOS.error}</template>`;
  return paginaHtml({
    titulo: 'Crea tu nueva contraseña',
    icono: 'info',
    mensaje: 'Elige una contraseña que recuerdes y que sea difícil de adivinar.',
    cuerpoExtra,
    script: SCRIPT_RESTABLECER,
    nonce,
  });
}

const PASOS_CORREO = ['Vuelve a la app de OnCuidar.', 'Pide un enlace nuevo desde tu perfil.', 'Ábrelo desde el correo más reciente.'];
const PASOS_CONTRASENA = ['Vuelve a la app de OnCuidar.', 'En el inicio de sesión, elige «Olvidé mi contraseña».', 'Pide un enlace nuevo y ábrelo desde tu correo más reciente.'];

function paginaConfirmacion(ok, nonce, pasos = PASOS_CORREO) {
  return ok
    ? paginaHtml({ titulo: '¡Correo confirmado!', icono: 'exito', mensaje: 'Listo, tu correo quedó confirmado en OnCuidar.', cuerpoExtra: '<p class="suave">Puedes cerrar esta pestaña y volver a la app.</p>', nonce })
    : paginaHtml({
      titulo: 'Enlace inválido o vencido',
      icono: 'error',
      mensaje: 'Este enlace ya se usó, venció (duran 1 hora) o no es correcto.',
      cuerpoExtra: `<ol class="pasos">${pasos.map((p) => `<li>${esc(p)}</li>`).join('')}</ol>`,
      nonce,
    });
}

const EXPIRA = 'Este enlace vence en 1 hora y solo se puede usar una vez.';
const SEGURIDAD = 'Si no fuiste tú, ignora este mensaje: tu cuenta sigue segura.';

const CORREOS = {
  restablecer: {
    asunto: 'Restablece tu contraseña de OnCuidar',
    previa: 'Crea una contraseña nueva para entrar a OnCuidar.',
    titulo: 'Restablece tu contraseña',
    parrafos: ['Recibimos una solicitud para cambiar la contraseña de tu cuenta de OnCuidar.', 'Toca el botón para elegir una contraseña nueva.'],
    boton: 'Crear contraseña nueva',
  },
  verificar: {
    asunto: 'Confirma tu correo en OnCuidar',
    previa: 'Un último paso para dejar tu cuenta lista.',
    titulo: 'Te damos la bienvenida a OnCuidar',
    parrafos: ['Gracias por unirte. Estamos para acompañarte en el cuidado.', 'Confirma tu correo para dejar tu cuenta lista y segura.'],
    boton: 'Confirmar mi correo',
  },
  cambio: {
    asunto: 'Confirma tu nuevo correo en OnCuidar',
    previa: 'Confirma que este será tu correo principal.',
    titulo: 'Confirma tu nuevo correo',
    parrafos: ['Pediste usar este correo como principal en OnCuidar.', 'Confírmalo para completar el cambio. Hasta entonces seguirás usando tu correo actual.'],
    boton: 'Confirmar nuevo correo',
  },
  respaldo: {
    asunto: 'Confirma tu correo de respaldo en OnCuidar',
    previa: 'Te ayudará a recuperar tu cuenta si la necesitas.',
    titulo: 'Confirma tu correo de respaldo',
    parrafos: ['Pediste usar este correo como respaldo en OnCuidar.', 'Con él podrás recuperar el acceso a tu cuenta si olvidas tu contraseña.'],
    boton: 'Confirmar correo de respaldo',
  },
};

// Arma asunto, html y texto de un tipo de correo
function armarCorreo(tipo, enlace) {
  const base = CORREOS[tipo];
  if (!base) throw new Error(`Plantilla de correo desconocida: ${tipo}`);
  const datos = {
    asunto: base.asunto,
    previa: base.previa,
    titulo: base.titulo,
    parrafos: base.parrafos,
    boton: { texto: base.boton, url: enlace },
    aviso: `${EXPIRA} ${SEGURIDAD}`,
  };
  return { asunto: base.asunto, html: correoHtml(datos), texto: correoTexto(datos) };
}

module.exports = {
  correoHtml, correoTexto, paginaHtml, paginaRestablecer, paginaConfirmacion, PASOS_CONTRASENA, cspPagina,
  armarCorreo, CORREOS, CID_LOGO, LOGO_PNG, LOGO_DATA_URI, urlSegura, esc, C,
};
