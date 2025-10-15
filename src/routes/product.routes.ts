// src/routes/product.routes.ts

import { Router } from 'express';
import { PrismaClient, Role } from '@prisma/client';
import { authenticate } from '../middleware/auth';
import { asyncHandler } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

/**
 * @route   GET /api/v1/products
 * @desc    Get all products a user has access to, or all products for admins
 * @access  Private
 */
router.get('/', authenticate, asyncHandler(async (req, res) => {
  const userId = req.user!.userId;
  const userRole = req.user!.role;

  // Admins and Master Admins get all products
  if (userRole === Role.ADMIN || userRole === Role.MASTER_ADMIN) {
    const allProducts = await prisma.product.findMany({
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        createdAt: true
      }
    });
    return res.json({
      success: true,
      data: allProducts
    });
  }

  // Regular users get only products they have access to
  const userWithProducts = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      userProducts: {
        include: {
          product: {
            select: {
              id: true,
              name: true,
              slug: true,
              description: true,
              createdAt: true
            }
          }
        }
      }
    }
  });

  const products = userWithProducts?.userProducts.map(up => up.product) || [];

  res.json({
    success: true,
    data: products
  });
}));

/**
 * @route   GET /api/v1/products/:productId/topics
 * @desc    Get all topics for a product
 * @access  Private
 */
router.get('/:productId/topics', authenticate, asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const userId = req.user!.userId;
  const userRole = req.user!.role;

  // Admins and Master Admins have access to all topics of any product
  if (userRole === Role.ADMIN || userRole === Role.MASTER_ADMIN) {
    const topics = await prisma.topic.findMany({
        where: { productId },
        select: {
          id: true,
          name: true,
          description: true,
          order: true,
          _count: {
            select: {
              qna: true,
              quizzes: true,
              pdfs: true
            }
          }
        },
        orderBy: { order: 'asc' }
      });
    return res.json({
        success: true,
        data: topics
      });
  }

  // Regular users need to have explicit access to the product
  const hasAccess = await prisma.userProduct.findUnique({
    where: { userId_productId: { userId, productId } }
  });

  if (!hasAccess) {
    return res.status(403).json({
      success: false,
      message: 'Access to this product is denied'
    });
  }

  const topics = await prisma.topic.findMany({
    where: { productId },
    select: {
      id: true,
      name: true,
      description: true,
      order: true,
      _count: {
        select: {
          qna: true,
          quizzes: true,
          pdfs: true
        }
      }
    },
    orderBy: { order: 'asc' }
  });

  res.json({
    success: true,
    data: topics
  });
}));

// ... (keep other routes like qna, quizzes, pdfs the same,
// as they already require authentication and will now be
// implicitly protected by the product access check on topics)

export default router;
