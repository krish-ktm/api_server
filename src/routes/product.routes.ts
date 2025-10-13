// src/routes/product.routes.ts

import { Router } from 'express';
import { PrismaClient, Prisma } from '@prisma/client';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

/**
 * @route   GET /api/v1/products
 * @desc    Get all products
 * @access  Public
 */
router.get('/', async (req, res) => {
  try {
    const products = await prisma.product.findMany({
      where: { isActive: true },
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        createdAt: true
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      data: products
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   GET /api/v1/products/:productId/topics
 * @desc    Get all topics for a product
 * @access  Public
 */
router.get('/:productId/topics', async (req, res) => {
  try {
    const { productId } = req.params;

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
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   GET /api/v1/products/:productId/qna
 * @desc    Get Q&A for a product (with optional company filter)
 * @access  Private
 * @query   ?company=amazon&topic=topicId&level=intermediate
 */
router.get('/:productId/qna', authenticate, async (req, res) => {
  try {
    const { productId } = req.params;
    const { company, topic, level } = req.query;

    // Build where clause
    const where: any = {
      topic: {
        productId
      }
    };

    if (topic) {
      where.topicId = topic as string;
    }

    if (level) {
      where.level = level as string;
    }

    // Get all Q&A first
    let qnaList = await prisma.qnA.findMany({
      where,
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

    // Filter by company if specified
    if (company) {
      const companyLower = (company as string).toLowerCase();
      qnaList = qnaList.filter(qna => {
        if (!qna.companyTags) return false;
        const tags = qna.companyTags as string[];
        return tags.some(tag => tag.toLowerCase() === companyLower);
      });
    }

    res.json({
      success: true,
      data: qnaList,
      count: qnaList.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   GET /api/v1/products/:productId/quizzes
 * @desc    Get quizzes for a product (with optional company filter)
 * @access  Private
 * @query   ?company=google&topic=topicId&level=advanced&limit=10
 */
router.get('/:productId/quizzes', authenticate, async (req, res) => {
  try {
    const { productId } = req.params;
    const { company, topic, level, limit } = req.query;

    const where: any = {
      topic: {
        productId
      }
    };

    if (topic) {
      where.topicId = topic as string;
    }

    if (level) {
      where.level = level as string;
    }

    let quizzes = await prisma.quiz.findMany({
      where,
      include: {
        topic: {
          select: {
            id: true,
            name: true
          }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: limit ? parseInt(limit as string) : undefined
    });

    // Filter by company if specified
    if (company) {
      const companyLower = (company as string).toLowerCase();
      quizzes = quizzes.filter(quiz => {
        if (!quiz.companyTags) return false;
        const tags = quiz.companyTags as string[];
        return tags.some(tag => tag.toLowerCase() === companyLower);
      });
    }

    // Don't send correct answers to frontend
    const sanitizedQuizzes = quizzes.map(quiz => ({
      id: quiz.id,
      topicId: quiz.topicId,
      question: quiz.question,
      options: quiz.options,
      level: quiz.level,
      companyTags: quiz.companyTags,
      topic: quiz.topic
    }));

    res.json({
      success: true,
      data: sanitizedQuizzes,
      count: sanitizedQuizzes.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   POST /api/v1/products/:productId/quizzes/:quizId/submit
 * @desc    Submit quiz answer
 * @access  Private
 */
router.post('/:productId/quizzes/:quizId/submit', authenticate, async (req, res) => {
  try {
    const { quizId } = req.params;
    const { selectedAnswer, timeTaken } = req.body;
    const userId = req.user!.userId;

    // Get quiz
    const quiz = await prisma.quiz.findUnique({
      where: { id: quizId }
    });

    if (!quiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz not found'
      });
    }

    // Check answer
    const isCorrect = quiz.correctAnswer === selectedAnswer;

    // Save attempt
    await prisma.quizAttempt.create({
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
      data: {
        isCorrect,
        correctAnswer: quiz.correctAnswer,
        explanation: quiz.explanation
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   GET /api/v1/products/:productId/pdfs
 * @desc    Get PDFs for a product
 * @access  Private
 */
router.get('/:productId/pdfs', authenticate, async (req, res) => {
  try {
    const { productId } = req.params;
    const { topic } = req.query;

    const where: any = {
      topic: {
        productId
      }
    };

    if (topic) {
      where.topicId = topic as string;
    }

    const pdfs = await prisma.pDF.findMany({
      where,
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
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

export default router;