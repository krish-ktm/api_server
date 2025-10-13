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

// ============= PRODUCTS =============

const productSchema = z.object({
  name: z.string().min(1),
  slug: z.string().min(1),
  description: z.string().optional()
});

router.get('/products', async (req, res) => {
  try {
    const products = await prisma.product.findMany({
      include: {
        _count: {
          select: {
            topics: true
          }
        }
      }
    });

    res.json({ success: true, data: products });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

router.post('/products', authorize('MASTER_ADMIN'), async (req, res) => {
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

router.put('/products/:id', authorize('MASTER_ADMIN'), async (req, res) => {
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
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

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

// ============= TOPICS =============

const topicSchema = z.object({
  productId: z.string(),
  name: z.string().min(1),
  description: z.string().optional(),
  order: z.number().int().default(0)
});

router.post('/topics', async (req, res) => {
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

router.put('/topics/:id', async (req, res) => {
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
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

router.delete('/topics/:id', async (req, res) => {
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

// ============= Q&A =============

const qnaSchema = z.object({
  topicId: z.string(),
  question: z.string().min(1),
  answer: z.string().min(1),
  level: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']),
  companyTags: z.array(z.string()).optional()
});

router.post('/qna', async (req, res) => {
  try {
    const data = qnaSchema.parse(req.body);

    const qna = await prisma.qnA.create({
      data: {
        ...data,
        companyTags: data.companyTags || []
      }
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

router.put('/qna/:id', async (req, res) => {
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
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

router.delete('/qna/:id', async (req, res) => {
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

// ============= QUIZZES =============

const quizSchema = z.object({
  topicId: z.string(),
  question: z.string().min(1),
  options: z.array(z.string()).min(2),
  correctAnswer: z.string(),
  explanation: z.string().optional(),
  level: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']),
  companyTags: z.array(z.string()).optional()
});

router.post('/quizzes', async (req, res) => {
  try {
    const data = quizSchema.parse(req.body);

    const quiz = await prisma.quiz.create({
      data: {
        ...data,
        companyTags: data.companyTags || []
      }
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

router.put('/quizzes/:id', async (req, res) => {
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
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

router.delete('/quizzes/:id', async (req, res) => {
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

// ============= PDFS =============

const pdfSchema = z.object({
  topicId: z.string(),
  title: z.string().min(1),
  description: z.string().optional(),
  fileUrl: z.string().url(),
  fileSize: z.number().int().optional()
});

router.post('/pdfs', async (req, res) => {
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

router.put('/pdfs/:id', async (req, res) => {
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
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

router.delete('/pdfs/:id', async (req, res) => {
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

// ============= ANALYTICS (MASTER ADMIN ONLY) =============

router.get('/analytics', authorize('MASTER_ADMIN'), async (req, res) => {
  try {
    const [
      totalUsers,
      totalProducts,
      totalQuizAttempts,
      recentUsers
    ] = await Promise.all([
      prisma.user.count(),
      prisma.product.count(),
      prisma.quizAttempt.count(),
      prisma.user.findMany({
        take: 5,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          createdAt: true
        }
      })
    ]);

    res.json({
      success: true,
      data: {
        totalUsers,
        totalProducts,
        totalQuizAttempts,
        recentUsers
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

export default router;