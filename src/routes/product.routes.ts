// src/routes/product.routes.ts

import { Router, Request, Response } from 'express';
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
router.get('/', authenticate, asyncHandler(async (req: Request, res: Response): Promise<any> => {
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
router.get('/:productId/topics', authenticate, asyncHandler(async (req: Request, res: Response): Promise<any> => {
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

/**
 * @route   GET /api/v1/products/:productId/qna/:qnaId
 * @desc    Get single Q&A details
 * @access  Private
 */
router.get('/:productId/qna/:qnaId', authenticate, asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { productId, qnaId } = req.params;
  const userId = req.user!.userId;
  const userRole = req.user!.role;

  if (userRole !== Role.ADMIN && userRole !== Role.MASTER_ADMIN) {
    const hasAccess = await prisma.userProduct.findUnique({
      where: { userId_productId: { userId, productId } }
    });

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access to this product is denied'
      });
    }
  }

  const qna = await prisma.qnA.findUnique({
    where: { id: qnaId },
    include: {
      topic: {
        select: {
          id: true,
          name: true,
          productId: true,
          product: {
            select: {
              id: true,
              name: true
            }
          }
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

  if (qna.topic.productId !== productId) {
    return res.status(400).json({
      success: false,
      message: 'Q&A does not belong to this product'
    });
  }

  const isBookmarked = await prisma.bookmark.findFirst({
    where: {
      userId,
      qnaId
    }
  });

  res.json({
    success: true,
    data: {
      ...qna,
      isBookmarked: !!isBookmarked
    }
  });
}));

/**
 * @route   GET /api/v1/products/:productId/qna
 * @desc    Get Q&A for a product with filtering and pagination
 * @access  Private
 */
router.get('/:productId/qna', authenticate, asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { productId } = req.params;
  const userId = req.user!.userId;
  const userRole = req.user!.role;

  const { company, topic, level, page = '1', limit = '10' } = req.query;
  const skip = (parseInt(page as string) - 1) * parseInt(limit as string);
  const take = parseInt(limit as string);

  if (userRole !== Role.ADMIN && userRole !== Role.MASTER_ADMIN) {
    const hasAccess = await prisma.userProduct.findUnique({
      where: { userId_productId: { userId, productId } }
    });

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access to this product is denied'
      });
    }
  }

  const whereClause: any = {
    topic: { productId }
  };

  if (topic) {
    whereClause.topicId = topic as string;
  }

  if (level) {
    whereClause.level = (level as string).toUpperCase();
  }

  if (company) {
    whereClause.companyTags = {
      path: '$',
      array_contains: company
    };
  }

  const [qnaList, total] = await Promise.all([
    prisma.qnA.findMany({
      where: whereClause,
      include: {
        topic: {
          select: {
            id: true,
            name: true
          }
        }
      },
      skip,
      take,
      orderBy: { createdAt: 'desc' }
    }),
    prisma.qnA.count({ where: whereClause })
  ]);

  res.json({
    success: true,
    data: {
      qna: qnaList,
      pagination: {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        total,
        totalPages: Math.ceil(total / parseInt(limit as string))
      }
    }
  });
}));

/**
 * @route   GET /api/v1/products/:productId/quizzes/:quizId
 * @desc    Get single quiz details (without correct answer until submitted)
 * @access  Private
 */
router.get('/:productId/quizzes/:quizId', authenticate, asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { productId, quizId } = req.params;
  const userId = req.user!.userId;
  const userRole = req.user!.role;

  if (userRole !== Role.ADMIN && userRole !== Role.MASTER_ADMIN) {
    const hasAccess = await prisma.userProduct.findUnique({
      where: { userId_productId: { userId, productId } }
    });

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access to this product is denied'
      });
    }
  }

  const quiz = await prisma.quiz.findUnique({
    where: { id: quizId },
    include: {
      topic: {
        select: {
          id: true,
          name: true,
          productId: true,
          product: { select: { id: true, name: true } }
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

  if ((quiz as any).productId !== productId) {
    return res.status(400).json({
      success: false,
      message: 'Quiz does not belong to this product'
    });
  }

  const userAttempts = await prisma.quizAttempt.findMany({
    where: {
      userId,
      quizId
    },
    orderBy: { createdAt: 'desc' },
    take: 5
  });

  const hasAttempted = userAttempts.length > 0;
  const lastAttempt = userAttempts[0] || null;

  res.json({
    success: true,
    data: {
      id: quiz.id,
      question: quiz.question,
      options: quiz.options,
      level: quiz.level,
      companyTags: quiz.companyTags,
      topic: quiz.topic,
      correctAnswer: hasAttempted ? quiz.correctAnswer : undefined,
      explanation: hasAttempted ? quiz.explanation : undefined,
      userAttempts: userAttempts.length,
      lastAttempt,
      hasAttempted
    }
  });
}));

/**
 * @route   GET /api/v1/products/:productId/quizzes
 * @desc    Get quizzes for a product with filtering
 * @access  Private
 */
router.get('/:productId/quizzes', authenticate, asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { productId } = req.params;
  const userId = req.user!.userId;
  const userRole = req.user!.role;

  const { company, topic, level } = req.query;

  if (userRole !== Role.ADMIN && userRole !== Role.MASTER_ADMIN) {
    const hasAccess = await prisma.userProduct.findUnique({
      where: { userId_productId: { userId, productId } }
    });

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access to this product is denied'
      });
    }
  }

  const whereClause: any = {
    topic: { productId }
  };

  if (topic) {
    whereClause.topicId = topic as string;
  }

  if (level) {
    whereClause.level = (level as string).toUpperCase();
  }

  if (company) {
    whereClause.companyTags = {
      path: '$',
      array_contains: company
    };
  }

  const quizzes = await prisma.quiz.findMany({
    where: whereClause,
    include: {
      topic: {
        select: {
          id: true,
          name: true
        }
      }
    },
    orderBy: { createdAt: 'desc' }
  });

  const quizzesWithAttempts = await Promise.all(
    quizzes.map(async (quiz) => {
      const userAttempts = await prisma.quizAttempt.findMany({
        where: {
          quizId: quiz.id,
          userId
        },
        orderBy: { createdAt: 'desc' },
        take: 1
      });

      return {
        ...quiz,
        correctAnswer: undefined,
        userAttempted: userAttempts.length > 0,
        lastAttempt: userAttempts[0] || null
      };
    })
  );

  res.json({
    success: true,
    data: quizzesWithAttempts
  });
}));

/**
 * @route   POST /api/v1/products/:productId/quizzes/:quizId/submit
 * @desc    Submit quiz answer
 * @access  Private
 */
router.post('/:productId/quizzes/:quizId/submit', authenticate, asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { productId, quizId } = req.params;
  const userId = req.user!.userId;
  const userRole = req.user!.role;
  const { selectedAnswer, timeTaken } = req.body;

  if (!selectedAnswer) {
    return res.status(400).json({
      success: false,
      message: 'Selected answer is required'
    });
  }

  if (userRole !== Role.ADMIN && userRole !== Role.MASTER_ADMIN) {
    const hasAccess = await prisma.userProduct.findUnique({
      where: { userId_productId: { userId, productId } }
    });

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access to this product is denied'
      });
    }
  }

  const quiz = await prisma.quiz.findUnique({
    where: { id: quizId },
    include: {
      topic: { select: { productId: true } }
    }
  });

  if (!quiz) {
    return res.status(404).json({
      success: false,
      message: 'Quiz not found'
    });
  }

  if ((quiz as any).productId !== productId) {
    return res.status(400).json({
      success: false,
      message: 'Quiz does not belong to this product'
    });
  }

  const isCorrect = selectedAnswer === quiz.correctAnswer;

  const attempt = await prisma.quizAttempt.create({
    data: {
      userId,
      quizId,
      selectedAnswer,
      isCorrect,
      timeTaken: timeTaken || null
    }
  });

  res.json({
    success: true,
    message: isCorrect ? 'Correct answer!' : 'Incorrect answer',
    data: {
      isCorrect,
      correctAnswer: quiz.correctAnswer,
      explanation: quiz.explanation,
      attempt
    }
  });
}));

/**
 * @route   GET /api/v1/products/:productId/pdfs/:pdfId
 * @desc    Get single PDF details
 * @access  Private
 */
router.get('/:productId/pdfs/:pdfId', authenticate, asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { productId, pdfId } = req.params;
  const userId = req.user!.userId;
  const userRole = req.user!.role;

  if (userRole !== Role.ADMIN && userRole !== Role.MASTER_ADMIN) {
    const hasAccess = await prisma.userProduct.findUnique({
      where: { userId_productId: { userId, productId } }
    });

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access to this product is denied'
      });
    }
  }

  const pdf = await prisma.pDF.findUnique({
    where: { id: pdfId },
    include: {
      topic: {
        select: {
          id: true,
          name: true,
          productId: true,
          product: {
            select: {
              id: true,
              name: true
            }
          }
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

  if (pdf.topic.productId !== productId) {
    return res.status(400).json({
      success: false,
      message: 'PDF does not belong to this product'
    });
  }

  const isBookmarked = await prisma.bookmark.findFirst({
    where: {
      userId,
      pdfId
    }
  });

  res.json({
    success: true,
    data: {
      ...pdf,
      isBookmarked: !!isBookmarked
    }
  });
}));

/**
 * @route   GET /api/v1/products/:productId/pdfs
 * @desc    Get PDFs for a product
 * @access  Private
 */
router.get('/:productId/pdfs', authenticate, asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { productId } = req.params;
  const userId = req.user!.userId;
  const userRole = req.user!.role;
  const { topic } = req.query;

  if (userRole !== Role.ADMIN && userRole !== Role.MASTER_ADMIN) {
    const hasAccess = await prisma.userProduct.findUnique({
      where: { userId_productId: { userId, productId } }
    });

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access to this product is denied'
      });
    }
  }

  const whereClause: any = {
    topic: { productId }
  };

  if (topic) {
    whereClause.topicId = topic as string;
  }

  const pdfs = await prisma.pDF.findMany({
    where: whereClause,
    include: {
      topic: {
        select: {
          id: true,
          name: true
        }
      }
    },
    orderBy: { createdAt: 'desc' }
  });

  res.json({
    success: true,
    data: pdfs
  });
}));

export default router;
