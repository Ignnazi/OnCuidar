class ErrorHttp extends Error {
  constructor(estado, mensaje) {
    super(mensaje);
    this.estado = estado;
  }
}

const PROHIBIDOS = {
  pacientes: ['nombreCompleto', 'rut', 'edad', 'diagnostico', 'tratamientoFase', 'centroSaludNombre',
    'centroSaludDireccion', 'centroSaludTelefono', 'contactoEmergenciaNombre', 'contactoEmergenciaTelefono'],
  registros: ['generalNotes', 'alertMessage', 'observaciones', 'mensajeAlerta', 'sintomas', 'signosVitales'],
  recordatorios: ['titulo', 'descripcion', 'tipo', 'fechaHora', 'diasRepeticion', 'recurrencia', 'completadoEn'],
  conversaciones: ['titulo', 'mensajes', 'primeraPregunta'],
  usuario: ['nombre', 'telefono', 'relacion', 'correo_respaldo', 'correo_respaldo_hash'],
};

function cuerpoObjeto(req) {
  const cuerpo = req.body ?? {};
  if (typeof cuerpo !== 'object' || Array.isArray(cuerpo)) {
    throw new ErrorHttp(400, 'El cuerpo debe ser un objeto JSON');
  }
  return cuerpo;
}

function rechazarEnClaro(cuerpo, recurso) {
  const presentes = PROHIBIDOS[recurso].filter((c) => Object.hasOwn(cuerpo, c));
  if (presentes.length) {
    throw new ErrorHttp(400, `Campos sensibles en claro no permitidos: ${presentes.join(', ')}. Deben ir cifrados.`);
  }
}

const esClaveCifrada = (k) => k === 'datos_cifrados' || k.endsWith('_cifrado') || k.endsWith('_cifrada');

function leerCifrados(cuerpo) {
  const poner = {};
  const borrar = [];
  if (cuerpo.cifrados === undefined) return { poner, borrar };
  const c = cuerpo.cifrados;
  if (c === null || typeof c !== 'object' || Array.isArray(c)) throw new ErrorHttp(400, 'cifrados debe ser un objeto');
  for (const [k, v] of Object.entries(c)) {
    if (!esClaveCifrada(k)) {
      throw new ErrorHttp(400, `La clave "${k}" de cifrados debe terminar en _cifrado o _cifrada`);
    }
    if (v === null) borrar.push(k);
    else if (typeof v === 'string') poner[k] = v;
    else throw new ErrorHttp(400, `El valor de "${k}" debe ser texto cifrado o null`);
  }
  return { poner, borrar };
}

function fechaOpcional(valor, nombre, { nulaPermitida = false } = {}) {
  if (valor === undefined) return undefined;
  if (valor === null && nulaPermitida) return null;
  const d = new Date(valor);
  if (typeof valor !== 'string' || Number.isNaN(d.getTime())) {
    throw new ErrorHttp(400, `${nombre} debe ser una fecha ISO-8601`);
  }
  return d.toISOString();
}

function booleanoOpcional(valor, nombre) {
  if (valor === undefined) return undefined;
  if (typeof valor !== 'boolean') throw new ErrorHttp(400, `${nombre} debe ser verdadero o falso`);
  return valor;
}

function enteroOpcional(valor, nombre) {
  if (valor === undefined) return undefined;
  if (!Number.isInteger(valor)) throw new ErrorHttp(400, `${nombre} debe ser un entero`);
  return valor;
}

function textoOpcional(valor, nombre, { nuloPermitido = false } = {}) {
  if (valor === undefined) return undefined;
  if (valor === null && nuloPermitido) return null;
  if (typeof valor !== 'string' || valor.length > 200) throw new ErrorHttp(400, `${nombre} debe ser texto corto`);
  return valor;
}

function validarId(id, nombre = 'id') {
  if (!/^[A-Za-z0-9_.:-]{1,128}$/.test(id)) throw new ErrorHttp(400, `${nombre} inválido`);
  return id;
}

function limite(valor, porDefecto, maximo = 500) {
  if (valor === undefined) return porDefecto;
  const n = Number(valor);
  if (!Number.isInteger(n) || n < 1) throw new ErrorHttp(400, 'limite debe ser un entero positivo');
  return Math.min(n, maximo);
}

function correoValido(correo) {
  return typeof correo === 'string' && correo.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo.trim());
}

const normalizarCorreo = (c) => c.trim().toLowerCase();

module.exports = {
  ErrorHttp, cuerpoObjeto, rechazarEnClaro, leerCifrados, fechaOpcional, booleanoOpcional,
  enteroOpcional, textoOpcional, validarId, limite, correoValido, normalizarCorreo,
};
