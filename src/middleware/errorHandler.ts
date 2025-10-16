// src/middleware/errorHandler.ts

import { Request, Response, NextFunction } from 'express';
import { Prisma } from '@prisma/client';
import { ZodError } from 'zod';

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  _next: NextFunction
) => {
  // Log detailed error information
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error('❌ ERROR OCCURRED');
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error('📍 Endpoint:', req.method, req.path);
  console.error('📦 Body:', JSON.stringify(req.body, null, 2));
  console.error('🔑 Headers:', {
    'content-type': req.headers['content-type'],
    'authorization': req.headers.authorization ? 'Present' : 'Missing'
  });
  console.error('❗ Error Name:', err.name);
  console.error('❗ Error Message:', err.message);
  console.error('📚 Stack Trace:', err.stack);
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // Handle Prisma errors
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    console.error('🗄️  PRISMA ERROR DETAILS:');
    console.error('Code:', err.code);
    console.error('Meta:', err.meta);
    
    switch (err.code) {
      case 'P2002':
        return res.status(400).json({
          success: false,
          message: 'A record with this value already exists',
          error: 'Duplicate entry',
          field: err.meta?.target,
          ...(process.env.NODE_ENV === 'development' && {
            details: err.message
          })
        });
      
      case 'P2025':
        return res.status(404).json({
          success: false,
          message: 'Record not found',
          error: 'Not found',
          ...(process.env.NODE_ENV === 'development' && {
            details: err.message
          })
        });
      
      case 'P2003':
        return res.status(400).json({
          success: false,
          message: 'Foreign key constraint failed',
          error: 'Invalid reference',
          field: err.meta?.field_name,
          ...(process.env.NODE_ENV === 'development' && {
            details: err.message
          })
        });
      
      case 'P1001':
        return res.status(500).json({
          success: false,
          message: 'Cannot connect to database',
          error: 'Database connection failed',
          hint: 'Check if MySQL is running and DATABASE_URL is correct',
          ...(process.env.NODE_ENV === 'development' && {
            details: err.message
          })
        });
      
      default:
        return res.status(400).json({
          success: false,
          message: 'Database operation failed',
          error: err.code,
          ...(process.env.NODE_ENV === 'development' && {
            details: err.message,
            meta: err.meta
          })
        });
    }
  }

  // Handle Prisma initialization errors
  if (err instanceof Prisma.PrismaClientInitializationError) {
    console.error('🚨 DATABASE CONNECTION ERROR');
    return res.status(500).json({
      success: false,
      message: 'Cannot connect to database',
      error: 'Database initialization failed',
      hint: 'Check if MySQL is running and DATABASE_URL in .env is correct',
      steps: [
        '1. Verify MySQL is running',
        '2. Check DATABASE_URL in .env file',
        '3. Run: npm run db:migrate',
        '4. Run: npx prisma generate'
      ],
      ...(process.env.NODE_ENV === 'development' && {
        details: err.message
      })
    });
  }

  // Handle Prisma validation errors
  if (err instanceof Prisma.PrismaClientValidationError) {
    console.error('⚠️  PRISMA VALIDATION ERROR');
    return res.status(400).json({
      success: false,
      message: 'Invalid data provided',
      error: 'Validation failed',
      hint: 'Check your request data matches the schema',
      ...(process.env.NODE_ENV === 'development' && {
        details: err.message
      })
    });
  }

  // Handle Zod validation errors
  if (err instanceof ZodError) {
    console.error('📋 VALIDATION ERROR:', err.errors);
    return res.status(400).json({
      success: false,
      message: 'Validation error',
      error: 'Invalid input',
      errors: err.errors.map(e => ({
        field: e.path.join('.'),
        message: e.message,
        code: e.code
      })),
      ...(process.env.NODE_ENV === 'development' && {
        details: err.errors
      })
    });
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Invalid token',
      error: 'Authentication failed',
      hint: 'Login again to get a new token'
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Token expired',
      error: 'Authentication expired',
      hint: 'Use refresh token to get a new access token'
    });
  }

  // Handle multer file upload errors
  if (err.name === 'MulterError') {
    return res.status(400).json({
      success: false,
      message: 'File upload error',
      error: err.message,
      code: err.code
    });
  }

  // Handle syntax errors (invalid JSON)
  if (err instanceof SyntaxError && 'body' in err) {
    return res.status(400).json({
      success: false,
      message: 'Invalid JSON in request body',
      error: 'Syntax error',
      hint: 'Check that your JSON is properly formatted'
    });
  }

  // Development: Return full error details
  if (process.env.NODE_ENV === 'development') {
    return res.status(err.status || 500).json({
      success: false,
      message: err.message || 'Internal server error',
      error: err.name,
      stack: err.stack,
      details: err
    });
  }

  // Production: Return generic error
  return res.status(err.status || 500).json({
    success: false,
    message: 'An unexpected error occurred',
    error: 'Internal server error',
    requestId: req.headers['x-request-id'] || 'N/A'
  });
};

// Async error wrapper - wrap async route handlers with this
export const asyncHandler = (fn: any) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// 404 Handler
export const notFoundHandler = (req: Request, res: Response) => {
  console.error('🔍 404 NOT FOUND:', req.method, req.path);
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    error: '404 Not Found',
    endpoint: `${req.method} ${req.path}`,
    hint: 'Check API documentation at /api-docs'
  });
};