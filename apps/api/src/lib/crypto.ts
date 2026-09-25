import { createCipheriv, createDecipheriv, createHash, randomBytes, timingSafeEqual, createHmac } from 'node:crypto';
import { config } from './config.js';

const key = createHash('sha256').update(config.ENCRYPTION_KEY).digest();
export function encryptJson(value: unknown) {
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(JSON.stringify(value), 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return [iv, tag, encrypted].map(v => v.toString('base64url')).join('.');
}
export function decryptJson<T = unknown>(payload: string): T {
  const [ivB64, tagB64, dataB64] = payload.split('.');
  if (!ivB64 || !tagB64 || !dataB64) throw new Error('Invalid encrypted payload');
  const decipher = createDecipheriv('aes-256-gcm', key, Buffer.from(ivB64, 'base64url'));
  decipher.setAuthTag(Buffer.from(tagB64, 'base64url'));
  return JSON.parse(Buffer.concat([decipher.update(Buffer.from(dataB64, 'base64url')), decipher.final()]).toString('utf8')) as T;
}
export function hmacHex(secret: string, body: string) { return createHmac('sha256', secret).update(body).digest('hex'); }
export function safeEqualHex(a: string, b: string) {
  try { const ab=Buffer.from(a,'hex'), bb=Buffer.from(b,'hex'); return ab.length===bb.length && timingSafeEqual(ab,bb); } catch { return false; }
}
