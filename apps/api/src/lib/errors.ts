export class AppError extends Error {
  constructor(
    message: string,
    public readonly statusCode = 400,
    public readonly code = 'BAD_REQUEST',
    public readonly details?: unknown
  ) {
    super(message);
  }
}

export const notFound = (message = 'Not found') => new AppError(message, 404, 'NOT_FOUND');
export const forbidden = (message = 'Forbidden') => new AppError(message, 403, 'FORBIDDEN');
export const unauthorized = (message = 'Unauthorized') => new AppError(message, 401, 'UNAUTHORIZED');
export const conflict = (message = 'Conflict') => new AppError(message, 409, 'CONFLICT');
