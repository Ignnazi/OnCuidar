const admin = require('firebase-admin');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { KeyManagementServiceClient } = require('@google-cloud/kms');

admin.initializeApp();
const db = admin.firestore();

// Secrets desde Secret Manager. Se sanean porque un set manual desde Windows
// puede dejar CRLF/BOM (bug real de prod con Cloud KMS).
const backupHmac = defineSecret('ONCUIDAR_BACKUP_EMAIL_HMAC_KEY');
const smtpUser = defineSecret('RECOVERY_SMTP_USER');
const smtpPass = defineSecret('RECOVERY_SMTP_PASS');
const continueUrl = defineSecret('RECOVERY_CONTINUE_URL');
const master = defineSecret('ONCUIDAR_RECOVERY_MASTER_KEY');
const kmsKeyResource = defineSecret('ONCUIDAR_KMS_KEY_RESOURCE');

// ── Helpers ──

function sanitizeSecretValue(value) {
  if (typeof value !== 'string') return '';
  return value.replace(/^\uFEFF/, '').trim();
}

const KMS_RESOURCE_RE =
  /^projects\/[a-z0-9-]+\/locations\/[a-z0-9-]+\/keyRings\/[a-zA-Z0-9_-]+\/cryptoKeys\/[a-zA-Z0-9_-]+$/;

function sanitizeKmsResource(value) {
  const clean = sanitizeSecretValue(value);
  return clean && KMS_RESOURCE_RE.test(clean) ? clean : '';
}

function isEmulator() {
  return process.env.FUNCTIONS_EMULATOR === 'true' || !!process.env.FIREBASE_FUNCTIONS_EMULATOR;
}

const EMAIL_REGEX = /^[\w\.\-\+]+@([\w\-]+\.)+[\w\-]{2,}$/;

function normalizeBackupEmail(email) {
  return email.trim().toLowerCase();
}

// Hash canónico del respaldo: HMAC calculado SOLO en el servidor.
function hmacBackupEmail(email) {
  return crypto
    .createHmac('sha256', backupHmac.value())
    .update(normalizeBackupEmail(email), 'utf8')
    .digest('hex');
}

// Fallback para correos registrados antes del hash server-side.
function hashBackupEmailLegacy(email) {
  return crypto
    .createHash('sha256')
    .update(normalizeBackupEmail(email), 'utf8')
    .digest('hex');
}

// ── Página terminal de "contraseña actualizada" ──
// Firebase Auth exige una continueUrl, esta página estática no redirige a nada.
const RESET_DONE_HTML = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OnCuidar - Contraseña actualizada</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      background: #f5f7fa;
    }
    .card {
      background: #fff;
      border-radius: 16px;
      padding: 40px;
      max-width: 360px;
      text-align: center;
      box-shadow: 0 4px 24px rgba(0,0,0,0.08);
    }
    .icon { font-size: 56px; margin-bottom: 16px; }
    h1 { font-size: 22px; color: #1f2933; margin: 0 0 8px; }
    p { color: #52606d; font-size: 15px; line-height: 1.5; margin: 0; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✅</div>
    <h1>Contraseña actualizada</h1>
    <p>Tu contraseña se actualizó correctamente. Ya puedes cerrar esta página y volver a la app de OnCuidar para iniciar sesión.</p>
  </div>
</body>
</html>`;

exports.resetDone = onRequest({ region: 'southamerica-west1' }, (req, res) => {
  res.status(200).set('Content-Type', 'text/html; charset=utf-8').send(RESET_DONE_HTML);
});

async function sendRecoveryMail(backupEmail, primaryEmail) {
  const rawUrl = sanitizeSecretValue(continueUrl.value() || '');
  const url = /^https:\/\/[^\s]+$/.test(rawUrl)
    ? rawUrl
    : `https://southamerica-west1-${process.env.GCLOUD_PROJECT || 'oncuidar-v1'}.cloudfunctions.net/resetDone`;
  let link;
  try {
    link = await admin.auth().generatePasswordResetLink(primaryEmail, { url });
  } catch (e) {
    console.error('sendRecoveryMail: generatePasswordResetLink falló:', e.code || e.message);
    return;
  }

  if (!smtpUser.value() || !smtpPass.value()) {
    if (isEmulator()) console.log(`[DEV] Enlace para ${primaryEmail}: ${link}`);
    else console.log('SMTP no configurado en producción, correo no enviado.');
    return;
  }

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: sanitizeSecretValue(smtpUser.value()), pass: sanitizeSecretValue(smtpPass.value()) },
  });
  await transporter.sendMail({
    from: `"Oncuidar" <${sanitizeSecretValue(smtpUser.value())}>`,
    to: backupEmail,
    subject: 'Recupera tu acceso a Oncuidar',
    text: [
      'Hola,',
      '',
      'Recibimos una solicitud para recuperar tu acceso a Oncuidar.',
      '',
      `Tu correo principal registrado es: ${primaryEmail}`,
      '',
      'Para restablecer tu contraseña, abre este enlace:',
      link,
      '',
      'Si no fuiste tú, ignora este mensaje.',
      '',
      'Equipo Oncuidar',
    ].join('\n'),
  });
}

// Registra el HMAC del correo de respaldo. Los clientes no escriben el hash.
exports.registerRecoveryEmail = onCall(
  { secrets: [backupHmac], region: 'southamerica-west1' },
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Inicia sesión nuevamente.');
    const raw = typeof request.data?.email === 'string' ? request.data.email : '';
    if (raw.length > 254 || !EMAIL_REGEX.test(raw.trim())) {
      throw new HttpsError('invalid-argument', 'Correo inválido.');
    }
    await db.collection('users').doc(request.auth.uid).set(
      { correo_respaldo_hash: hmacBackupEmail(raw) },
      { merge: true },
    );
    return { ok: true };
  },
);

// Pública. Anti-enumeración: SIEMPRE responde { ok: true }. Busca por HMAC,
// cae a SHA-256 legacy (y migra a HMAC), rate-limit 60 s, envía la
// recuperación al correo de respaldo.
exports.recoverByBackupEmail = onCall(
  { region: 'southamerica-west1', secrets: [backupHmac, smtpUser, smtpPass, continueUrl] },
  async (request) => {
    const raw = typeof request.data?.email === 'string' ? request.data.email : '';
    if (raw.length > 254 || !EMAIL_REGEX.test(raw.trim())) {
      throw new HttpsError('invalid-argument', 'Correo inválido.');
    }
    const backupEmail = normalizeBackupEmail(raw);
    const hmacHash = hmacBackupEmail(raw);

    try {
      const cooldownRef = db.collection('recoveryCooldowns').doc(hmacHash);
      const cooldownSnap = await cooldownRef.get();
      if (cooldownSnap.exists) {
        const lastSent = cooldownSnap.data().lastSentAt?.toMillis?.() ?? 0;
        if (Date.now() - lastSent < 60_000) return { ok: true };
      }

      let snap = await db
        .collection('users')
        .where('correo_respaldo_hash', '==', hmacHash)
        .limit(1)
        .get();
      let usedLegacy = false;
      if (snap.empty) {
        const legacyHash = hashBackupEmailLegacy(raw);
        snap = await db
          .collection('users')
          .where('correo_respaldo_hash', '==', legacyHash)
          .limit(1)
          .get();
        usedLegacy = !snap.empty;
      }

      if (!snap.empty) {
        const userDoc = snap.docs[0];
        const primary = userDoc.data().email;

        if (primary && normalizeBackupEmail(primary) === backupEmail) {
          return { ok: true };
        }

        if (primary) {
          await sendRecoveryMail(backupEmail, primary);

          if (usedLegacy) {
            await userDoc.ref.set({ correo_respaldo_hash: hmacHash }, { merge: true });
          }
          await cooldownRef.set({ lastSentAt: admin.firestore.FieldValue.serverTimestamp() });
        }
      }
    } catch (e) {
      console.error('recoverByBackupEmail error interno:', e);
    }
    return { ok: true };
  },
);

// ── Claves de datos del cliente (getOrCreateDataKey) ──
// Formato v3: { v: 3, c: ciphertext base64 } sellado por Cloud KMS.
// El AES local (formato iv) queda SOLO para migrar docs legacy y en emulador.
const kms = new KeyManagementServiceClient();
const ref = (uid) => db.collection('recoveryKeys').doc(uid);

function kmsResource() {
  return sanitizeKmsResource(kmsKeyResource.value());
}

function key() {
  const k = Buffer.from(master.value(), 'base64');
  if (k.length !== 32) throw Error('Invalid recovery master key');
  return k;
}

function sealLegacy(data) {
  const iv = crypto.randomBytes(12);
  const c = crypto.createCipheriv('aes-256-gcm', key(), iv);
  const ciphertext = Buffer.concat([c.update(data), c.final()]);
  return {
    iv: iv.toString('base64'),
    tag: c.getAuthTag().toString('base64'),
    ciphertext: ciphertext.toString('base64'),
  };
}

function openLegacy(x) {
  const d = crypto.createDecipheriv('aes-256-gcm', key(), Buffer.from(x.iv, 'base64'));
  d.setAuthTag(Buffer.from(x.tag, 'base64'));
  return Buffer.concat([
    d.update(Buffer.from(x.ciphertext, 'base64')),
    d.final(),
  ]);
}

async function sealKms(data) {
  const res = kmsResource();
  if (!res) {
    throw new HttpsError(
      'failed-precondition',
      'Configuración de cifrado inválida: ONCUIDAR_KMS_KEY_RESOURCE no es un resource name de Cloud KMS válido.',
    );
  }
  const [r] = await kms.encrypt({ name: res, plaintext: data });
  return { v: 3, c: r.ciphertext.toString('base64') };
}

async function openStored(x) {
  if (x.v === 3) {
    const res = kmsResource();
    if (!res) throw new Error('KMS no configurado (no se puede descifrar recoveryKeys v3)');
    const [dec] = await kms.decrypt({ name: res, ciphertext: Buffer.from(x.c, 'base64') });
    return dec.plaintext;
  }
  if (x.iv) return openLegacy(x);
  throw Error('Formato de clave de recuperación desconocido');
}

// Nunca sellar contenido nuevo con AES local fuera del emulador.
async function sealNew(data) {
  const res = kmsResource();
  if (!res) {
    if (isEmulator()) return sealLegacy(data);
    throw new HttpsError('internal', 'KMS no configurado');
  }
  return sealKms(data);
}

const auth = (request) => {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Inicia sesión nuevamente.');
};

exports.getOrCreateDataKey = onCall(
  { secrets: [master, kmsKeyResource], region: 'southamerica-west1' },
  async (request) => {
    auth(request);
    const r = ref(request.auth.uid);
    const old = await r.get();
    if (old.exists) {
      const oldData = old.data();
      const plain = await openStored(oldData);
      if (oldData.iv) {
        await r.set({ ...(await sealNew(plain)), createdAt: oldData.createdAt }, { merge: true });
      }
      return { dataKey: plain.toString('base64') };
    }
    const data = crypto.randomBytes(32);
    await r.set({
      ...(await sealNew(data)),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { dataKey: data.toString('base64') };
  },
);