// src/routes/admin.routes.ts

import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, authorize } from '../middleware/auth';
import { z } from 'zod';

const router = Router();
const prisma = new PrismaClient();

// Apply authentication and authorization to all admin routes
router.use(authenticate);
router.use(authorize('ADMIN', 'MASTER_ADMIN'));

// ... (previous admin routes)

// ============= USER-PRODUCT ACCESS =============

const userProductSchema = z.object({
  userId: z.string().uuid(),
  productId: z.string().uuid()
});

/**
 * @route   POST /api/v1/admin/users/grant-product-access
 * @desc    Grant a user access to a product
 * @access  Admin, Master Admin
 */
router.post('/users/grant-product-access', async (req, res) => {
  try {
    const { userId, productId } = userProductSchema.parse(req.body);

    await prisma.userProduct.create({
      data: {
        userId,
        productId
      }
    });

    res.status(201).json({
      success: true,
      message: 'Product access granted successfully'
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.errors
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   POST /api/v1/admin/users/revoke-product-access
 * @desc    Revoke a user\'s access to a product
 * @access  Admin, Master Admin
 */
router.post('/users/revoke-product-access', async (req, res) => {
  try {
    const { userId, productId } = userProductSchema.parse(req.body);

    await prisma.userProduct.delete({
      where: {
        userId_productId: {
          userId,
          productId
        }
      }
    });

    res.json({
      success: true,
      message: 'Product access revoked successfully'
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.errors
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

export default router;
