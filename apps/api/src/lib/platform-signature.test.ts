import { createHash, createHmac } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { verifyPlatformSignature } from './platform-signature.js';

describe('Hub service signature', () => {
  it('accepts a bound recent request and rejects a changed tenant or stale timestamp', () => {
    const secret='one-shared-secret-at-least-thirty-two-characters';
    const body=JSON.stringify({organization:{id:'v79org_123'}});
    const timestamp='1700000000000';
    const digest=createHash('sha256').update(body).digest('hex');
    const signature=createHmac('sha256',secret).update(`POST\n/api/platform/provision\n${timestamp}\n${digest}`).digest('hex');
    const input={method:'POST',pathname:'/api/platform/provision',timestamp,body,signature,secret,now:Number(timestamp)};
    expect(verifyPlatformSignature(input)).toBe(true);
    expect(verifyPlatformSignature({...input,body:body.replace('123','456')})).toBe(false);
    expect(verifyPlatformSignature({...input,now:Number(timestamp)+300_001})).toBe(false);
    expect(verifyPlatformSignature({...input,signature:'not-hex'})).toBe(false);
  });
});
