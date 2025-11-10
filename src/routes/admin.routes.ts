// src/routes/admin.routes.ts

import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, authorize } from '../middleware/auth';
import { z } from 'zod';

const router = Router();
const prisma = new PrismaClient();

// Apply authentication to all admin routes
router.use(authenticate);

// ============= VALIDATION SCHEMAS =============

const userProductSchema = z.object({
  userId: z.string().uuid(),
  productId: z.string().uuid()
});

const productSchema = z.object({
  name: z.string().min(1),
  slug: z.string().min(1),
  description: z.string().optional(),
  isActive: z.boolean().optional()
});

const topicSchema = z.object({
  productId: z.string().uuid(),
  name: z.string().min(1),
  description: z.string().optional(),
  order: z.number().int().optional()
});

const qnaSchema = z.object({
  topicId: z.string().uuid(),
  question: z.string().min(1),
  answer: z.string().min(1),
  exampleCode: z.string().optional(),
  level: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']).optional(),
  companyTags: z.array(z.string()).optional()
});

const quizGroupSchema = z.object({
  productId: z.string().uuid(),
  name: z.string().min(1),
  description: z.string().optional(),
  order: z.number().int().optional(),
  isActive: z.boolean().optional()
});

const quizSchema = z.object({
  quizGroupId: z.string().uuid(),
  question: z.string().min(1),
  options: z.array(z.string()).min(2),
  correctAnswer: z.string().min(1),
  explanation: z.string().optional(),
  level: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']).optional(),
  companyTags: z.array(z.string()).optional()
});

const pdfSchema = z.object({
  topicId: z.string().uuid(),
  title: z.string().min(1),
  description: z.string().optional(),
  fileUrl: z.string().url(),
  fileSize: z.number().int().optional()
});

// ============= USER MANAGEMENT =============

/**
 * @route   GET /api/v1/admin/users
 * @desc    List all users with pagination and filtering
 * @access  Admin, Master Admin
 */
router.get('/users', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<void> => {
  try {
    const { role, page = '1', limit = '10' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);
    const take = parseInt(limit as string);

    const whereClause: any = {};
    if (role) {
      whereClause.role = (role as string).toUpperCase();
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where: whereClause,
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          createdAt: true,
          _count: {
            select: {
              userProducts: true,
              quizAttempts: true
            }
          }
        },
        skip,
        take,
        orderBy: { createdAt: 'desc' }
      }),
      prisma.user.count({ where: whereClause })
    ]);

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          page: parseInt(page as string),
          limit: parseInt(limit as string),
          total,
          totalPages: Math.ceil(total / take)
        }
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   GET /api/v1/admin/users/:id
 * @desc    Get single user details
 * @access  Admin, Master Admin
 */
router.get('/users/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
        updatedAt: true,
        userProducts: {
          include: {
            product: {
              select: {
                id: true,
                name: true,
                slug: true
              }
            }
          }
        },
        _count: {
          select: {
            quizAttempts: true,
            bookmarks: true,
            progress: true
          }
        }
      }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   PUT /api/v1/admin/users/:id/role
 * @desc    Change user role
 * @access  Admin, Master Admin
 */
router.put('/users/:id/role', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    if (!role || !['USER', 'ADMIN', 'MASTER_ADMIN'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Valid role is required (USER, ADMIN, MASTER_ADMIN)'
      });
    }

    const user = await prisma.user.update({
      where: { id },
      data: { role },
      select: {
        id: true,
        name: true,
        email: true,
        role: true
      }
    });

    res.json({
      success: true,
      message: 'User role updated successfully',
      data: user
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   DELETE /api/v1/admin/users/:id
 * @desc    Delete user
 * @access  Admin, Master Admin
 */
router.delete('/users/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;
    const requesterId = req.user!.userId;

    if (id === requesterId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete your own account'
      });
    }

    await prisma.user.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   GET /api/v1/admin/users/:userId/products
 * @desc    Get all products assigned to a user
 * @access  Admin, Master Admin
 */
router.get('/users/:userId/products', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { userId } = req.params;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true
      }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userProducts = await prisma.userProduct.findMany({
      where: { userId },
      include: {
        product: {
          select: {
            id: true,
            name: true,
            slug: true,
            description: true,
            isActive: true,
            createdAt: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      data: {
        user,
        products: userProducts.map(up => ({
          ...up.product,
          grantedAt: up.createdAt
        }))
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ============= USER-PRODUCT ACCESS =============

/**
 * @route   POST /api/v1/admin/users/grant-product-access
 * @desc    Grant a user access to a product
 * @access  Admin, Master Admin
 */
router.post('/users/grant-product-access', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
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
router.post('/users/revoke-product-access', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
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

// ============= PRODUCTS (Master Admin Only) =============

/**
 * @route   GET /api/v1/admin/products/:id
 * @desc    Get single product details
 * @access  Master Admin
 */
router.get('/products/:id', authorize('MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;

    const product = await prisma.product.findUnique({
      where: { id },
      include: {
        topics: {
          select: {
            id: true,
            name: true,
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
        },
        _count: {
          select: {
            topics: true,
            userAccess: true
          }
        }
      }
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    res.json({
      success: true,
      data: product
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   GET /api/v1/admin/products
 * @desc    Get all products
 * @access  Master Admin
 */
router.get('/products', authorize('MASTER_ADMIN'), async (_req, res): Promise<void> => {
  try {
    const products = await prisma.product.findMany({
      include: {
        _count: {
          select: {
            topics: true,
            userAccess: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      data: products
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   POST /api/v1/admin/products
 * @desc    Create a new product
 * @access  Master Admin
 */
router.post('/products', authorize('MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const data = productSchema.parse(req.body);

    const product = await prisma.product.create({
      data
    });

    res.status(201).json({
      success: true,
      message: 'Product created successfully',
      data: product
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
 * @route   PUT /api/v1/admin/products/:id
 * @desc    Update a product
 * @access  Master Admin
 */
router.put('/products/:id', authorize('MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;
    const data = productSchema.partial().parse(req.body);

    const product = await prisma.product.update({
      where: { id },
      data
    });

    res.json({
      success: true,
      message: 'Product updated successfully',
      data: product
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
 * @route   DELETE /api/v1/admin/products/:id
 * @desc    Delete a product
 * @access  Master Admin
 */
router.delete('/products/:id', authorize('MASTER_ADMIN'), async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.product.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Product deleted successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ============= TOPICS (Admin+) =============

/**
 * @route   GET /api/v1/admin/topics/:id
 * @desc    Get single topic details
 * @access  Admin, Master Admin
 */
router.get('/topics/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;

    const topic = await prisma.topic.findUnique({
      where: { id },
      include: {
        product: {
          select: {
            id: true,
            name: true,
            slug: true
          }
        },
        _count: {
          select: {
            qna: true,
            pdfs: true
          }
        }
      }
    });

    if (!topic) {
      return res.status(404).json({
        success: false,
        message: 'Topic not found'
      });
    }

    res.json({
      success: true,
      data: topic
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   GET /api/v1/admin/topics
 * @desc    Get all topics (optionally filtered by product)
 * @access  Admin, Master Admin
 */
router.get('/topics', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<void> => {
  try {
    const { productId } = req.query;

    const topics = await prisma.topic.findMany({
      where: productId ? { productId: productId as string } : undefined,
      include: {
        product: {
          select: {
            id: true,
            name: true
          }
        },
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
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   POST /api/v1/admin/topics
 * @desc    Create a new topic
 * @access  Admin, Master Admin
 */
router.post('/topics', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const data = topicSchema.parse(req.body);

    const topic = await prisma.topic.create({
      data
    });

    res.status(201).json({
      success: true,
      message: 'Topic created successfully',
      data: topic
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
 * @route   PUT /api/v1/admin/topics/:id
 * @desc    Update a topic
 * @access  Admin, Master Admin
 */
router.put('/topics/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;
    const data = topicSchema.partial().parse(req.body);

    const topic = await prisma.topic.update({
      where: { id },
      data
    });

    res.json({
      success: true,
      message: 'Topic updated successfully',
      data: topic
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
 * @route   DELETE /api/v1/admin/topics/:id
 * @desc    Delete a topic
 * @access  Admin, Master Admin
 */
router.delete('/topics/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.topic.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Topic deleted successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ============= Q&A (Admin+) =============

/**
 * @route   GET /api/v1/admin/qna/:id
 * @desc    Get single Q&A details
 * @access  Admin, Master Admin
 */
router.get('/qna/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;

    const qna = await prisma.qnA.findUnique({
      where: { id },
      include: {
        topic: {
          select: {
            id: true,
            name: true,
            product: {
              select: {
                id: true,
                name: true
              }
            }
          }
        },
        _count: {
          select: {
            bookmarks: true
          }
        }
      }
    });

    if (!qna) {
      return res.status(404).json({
        success: false,
        message: 'Q&A not found'
      });
    }

    res.json({
      success: true,
      data: qna
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   GET /api/v1/admin/qna
 * @desc    Get all Q&A (optionally filtered)
 * @access  Admin, Master Admin
 */
router.get('/qna', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<void> => {
  try {
    const { topicId } = req.query;

    const qna = await prisma.qnA.findMany({
      where: topicId ? { topicId: topicId as string } : undefined,
      include: {
        topic: {
          select: {
            id: true,
            name: true,
            product: {
              select: {
                id: true,
                name: true
              }
            }
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      data: qna
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   POST /api/v1/admin/qna
 * @desc    Create a new Q&A
 * @access  Admin, Master Admin
 */
router.post('/qna', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const data = qnaSchema.parse(req.body);

    const qna = await prisma.qnA.create({
      data
    });

    res.status(201).json({
      success: true,
      message: 'Q&A created successfully',
      data: qna
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
 * @route   PUT /api/v1/admin/qna/:id
 * @desc    Update a Q&A
 * @access  Admin, Master Admin
 */
router.put('/qna/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;
    const data = qnaSchema.partial().parse(req.body);

    const qna = await prisma.qnA.update({
      where: { id },
      data
    });

    res.json({
      success: true,
      message: 'Q&A updated successfully',
      data: qna
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
 * @route   DELETE /api/v1/admin/qna/:id
 * @desc    Delete a Q&A
 * @access  Admin, Master Admin
 */
router.delete('/qna/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.qnA.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Q&A deleted successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ============= QUIZ GROUPS (Admin+) =============

/**
 * @route   GET /api/v1/admin/quiz-groups/:id
 * @desc    Get single quiz group details
 * @access  Admin, Master Admin
 */
router.get('/quiz-groups/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;

    const quizGroup = await prisma.quizGroup.findUnique({
      where: { id },
      include: {
        product: {
          select: {
            id: true,
            name: true,
            slug: true
          }
        },
        _count: {
          select: {
            quizzes: true
          }
        }
      }
    });

    if (!quizGroup) {
      return res.status(404).json({
        success: false,
        message: 'Quiz group not found'
      });
    }

    res.json({
      success: true,
      data: quizGroup
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   GET /api/v1/admin/quiz-groups
 * @desc    Get all quiz groups (optionally filtered by product)
 * @access  Admin, Master Admin
 */
router.get('/quiz-groups', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<void> => {
  try {
    const { productId } = req.query;

    const quizGroups = await prisma.quizGroup.findMany({
      where: productId ? { productId: productId as string } : undefined,
      include: {
        product: {
          select: {
            id: true,
            name: true
          }
        },
        _count: {
          select: {
            quizzes: true
          }
        }
      },
      orderBy: { order: 'asc' }
    });

    res.json({
      success: true,
      data: quizGroups
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   POST /api/v1/admin/quiz-groups
 * @desc    Create a new quiz group
 * @access  Admin, Master Admin
 */
router.post('/quiz-groups', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const data = quizGroupSchema.parse(req.body);

    const quizGroup = await prisma.quizGroup.create({
      data
    });

    res.status(201).json({
      success: true,
      message: 'Quiz group created successfully',
      data: quizGroup
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
 * @route   PUT /api/v1/admin/quiz-groups/:id
 * @desc    Update a quiz group
 * @access  Admin, Master Admin
 */
router.put('/quiz-groups/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;
    const data = quizGroupSchema.partial().parse(req.body);

    const quizGroup = await prisma.quizGroup.update({
      where: { id },
      data
    });

    res.json({
      success: true,
      message: 'Quiz group updated successfully',
      data: quizGroup
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
 * @route   DELETE /api/v1/admin/quiz-groups/:id
 * @desc    Delete a quiz group
 * @access  Admin, Master Admin
 */
router.delete('/quiz-groups/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.quizGroup.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Quiz group deleted successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ============= QUIZZES (Admin+) =============

/**
 * @route   GET /api/v1/admin/quizzes/:id
 * @desc    Get single quiz details
 * @access  Admin, Master Admin
 */
router.get('/quizzes/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;

    const quiz = await prisma.quiz.findUnique({
      where: { id },
      include: {
        quizGroup: {
          select: {
            id: true,
            name: true,
            product: {
              select: {
                id: true,
                name: true
              }
            }
          }
        },
        _count: {
          select: {
            attempts: true
          }
        }
      }
    });

    if (!quiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz not found'
      });
    }

    res.json({
      success: true,
      data: quiz
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   GET /api/v1/admin/quizzes
 * @desc    Get all quizzes (optionally filtered)
 * @access  Admin, Master Admin
 */
router.get('/quizzes', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<void> => {
  try {
    const { quizGroupId, productId } = req.query;
    
    const whereClause: any = {};
    
    if (quizGroupId) {
      whereClause.quizGroupId = quizGroupId as string;
    } else if (productId) {
      whereClause.quizGroup = { productId: productId as string };
    }

    const quizzes = await prisma.quiz.findMany({
      where: whereClause,
      include: {
        quizGroup: {
          select: {
            id: true,
            name: true,
            product: {
              select: {
                id: true,
                name: true
              }
            }
          }
        },
        _count: {
          select: {
            attempts: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      data: quizzes
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   POST /api/v1/admin/quizzes
 * @desc    Create a new quiz
 * @access  Admin, Master Admin
 */
router.post('/quizzes', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const data = quizSchema.parse(req.body);

    const quiz = await prisma.quiz.create({
      data
    });

    res.status(201).json({
      success: true,
      message: 'Quiz created successfully',
      data: quiz
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
 * @route   PUT /api/v1/admin/quizzes/:id
 * @desc    Update a quiz
 * @access  Admin, Master Admin
 */
router.put('/quizzes/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;
    const data = quizSchema.partial().parse(req.body);

    const quiz = await prisma.quiz.update({
      where: { id },
      data
    });

    res.json({
      success: true,
      message: 'Quiz updated successfully',
      data: quiz
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
 * @route   DELETE /api/v1/admin/quizzes/:id
 * @desc    Delete a quiz
 * @access  Admin, Master Admin
 */
router.delete('/quizzes/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.quiz.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Quiz deleted successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ============= PDFs (Admin+) =============

/**
 * @route   GET /api/v1/admin/pdfs/:id
 * @desc    Get single PDF details
 * @access  Admin, Master Admin
 */
router.get('/pdfs/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;

    const pdf = await prisma.pDF.findUnique({
      where: { id },
      include: {
        topic: {
          select: {
            id: true,
            name: true,
            product: {
              select: {
                id: true,
                name: true
              }
            }
          }
        },
        _count: {
          select: {
            bookmarks: true
          }
        }
      }
    });

    if (!pdf) {
      return res.status(404).json({
        success: false,
        message: 'PDF not found'
      });
    }

    res.json({
      success: true,
      data: pdf
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   GET /api/v1/admin/pdfs
 * @desc    Get all PDFs (optionally filtered)
 * @access  Admin, Master Admin
 */
router.get('/pdfs', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<void> => {
  try {
    const { topicId } = req.query;

    const pdfs = await prisma.pDF.findMany({
      where: topicId ? { topicId: topicId as string } : undefined,
      include: {
        topic: {
          select: {
            id: true,
            name: true,
            product: {
              select: {
                id: true,
                name: true
              }
            }
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      data: pdfs
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

/**
 * @route   POST /api/v1/admin/pdfs
 * @desc    Create a new PDF
 * @access  Admin, Master Admin
 */
router.post('/pdfs', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const data = pdfSchema.parse(req.body);

    const pdf = await prisma.pDF.create({
      data
    });

    res.status(201).json({
      success: true,
      message: 'PDF created successfully',
      data: pdf
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
 * @route   PUT /api/v1/admin/pdfs/:id
 * @desc    Update a PDF
 * @access  Admin, Master Admin
 */
router.put('/pdfs/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res): Promise<any> => {
  try {
    const { id } = req.params;
    const data = pdfSchema.partial().parse(req.body);

    const pdf = await prisma.pDF.update({
      where: { id },
      data
    });

    res.json({
      success: true,
      message: 'PDF updated successfully',
      data: pdf
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
 * @route   DELETE /api/v1/admin/pdfs/:id
 * @desc    Delete a PDF
 * @access  Admin, Master Admin
 */
router.delete('/pdfs/:id', authorize('ADMIN', 'MASTER_ADMIN'), async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.pDF.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'PDF deleted successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ============= ANALYTICS (Master Admin Only) =============

/**
 * @route   GET /api/v1/admin/analytics
 * @desc    Get platform analytics
 * @access  Master Admin
 */
router.get('/analytics', authorize('MASTER_ADMIN'), async (_req, res): Promise<void> => {
  try {
    const [userCount, productCount, totalQnA, totalQuizzes, totalPDFs, quizAttempts] = await Promise.all([
      prisma.user.count(),
      prisma.product.count(),
      prisma.qnA.count(),
      prisma.quiz.count(),
      prisma.pDF.count(),
      prisma.quizAttempt.findMany()
    ]);

    const correctAttempts = quizAttempts.filter(a => a.isCorrect).length;
    const overallAccuracy = quizAttempts.length > 0
      ? (correctAttempts / quizAttempts.length) * 100
      : 0;

    const usersByRole = await prisma.user.groupBy({
      by: ['role'],
      _count: true
    });

    const recentActivity = await prisma.quizAttempt.findMany({
      take: 10,
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            name: true,
            email: true
          }
        },
        quiz: {
          select: {
            question: true,
            topic: {
              select: {
                name: true,
                product: {
                  select: {
                    name: true
                  }
                }
              }
            }
          }
        }
      }
    });

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers: userCount,
          totalProducts: productCount,
          totalQnA,
          totalQuizzes,
          totalPDFs
        },
        usersByRole: usersByRole.reduce((acc, item) => {
          acc[item.role] = item._count;
          return acc;
        }, {} as Record<string, number>),
        quizStatistics: {
          totalAttempts: quizAttempts.length,
          correctAttempts,
          overallAccuracy: Math.round(overallAccuracy * 100) / 100
        },
        recentActivity
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

export default router;
