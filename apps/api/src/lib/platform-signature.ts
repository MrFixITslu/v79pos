import { createHash, createHmac, timingSafeEqual } from 'node:crypto';

export function verifyPlatformSignature(input: { method: string; pathname: string; timestamp?: string; body?: string; signature?: string; secret: string; now?: number }) {
  const { method, pathname, timestamp = '', body = '', signature = '', secret, now = Date.now() } = input;
  const time = Number(timestamp);
  if (secret.length < 32 || !timestamp || !Number.isFinite(time) || Math.abs(now - time) > 300_000 || !/^[a-f0-9]{64}$/i.test(signature)) return false;
  const digest = createHash('sha256').update(body).digest('hex');
  const expected = createHmac('sha256', secret).update(`${method.toUpperCase()}\n${pathname}\n${timestamp}\n${digest}`).digest();
  return timingSafeEqual(expected, Buffer.from(signature, 'hex'));
}
