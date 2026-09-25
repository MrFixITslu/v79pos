import { describe, expect, it } from 'vitest';
import { AppError, conflict, forbidden, notFound, unauthorized } from './errors.js';

describe('application errors', () => {
  it('preserves explicit status, code and details', () => {
    const error = new AppError('Invalid input', 422, 'VALIDATION_ERROR', { field: 'sku' });

    expect(error).toBeInstanceOf(Error);
    expect(error.message).toBe('Invalid input');
    expect(error.statusCode).toBe(422);
    expect(error.code).toBe('VALIDATION_ERROR');
    expect(error.details).toEqual({ field: 'sku' });
  });

  it.each([
    [notFound(), 404, 'NOT_FOUND'],
    [forbidden(), 403, 'FORBIDDEN'],
    [unauthorized(), 401, 'UNAUTHORIZED'],
    [conflict(), 409, 'CONFLICT']
  ])('maps helper errors to their HTTP contract', (error, statusCode, code) => {
    expect(error.statusCode).toBe(statusCode);
    expect(error.code).toBe(code);
  });
});
