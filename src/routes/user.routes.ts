// src/routes/user.routes.ts

import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate } from '../middleware/auth';
import bcrypt from 'bcrypt';
import { z } from 'zod';

const router = Router();
const prisma = new PrismaClient();

const changePasswordSchema = z.object({
  currentPassword: z.string(),
  newPassword: z.string().min(8)
});

/**
 * @route   GET /api/v1/users/profile
 * @desc    Get user profile
 * @access  Private
 */
router.get('/profile', authenticate, async (req, res) => {
  try {
    const userId = req.user!.userId;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true
      }
    });

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   PUT /api/v1/users/profile
 * @desc    Update user profile
 * @access  Private
 */
router.put('/profile', authenticate, async (req, res) => {
  try {
    const userId = req.user!.userId;
    const { name } = req.body;

    const user = await prisma.user.update({
      where: { id: userId },
      data: { name },
      select: {
        id: true,
        name: true,
        email: true,
        role: true
      }
    });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   GET /api/v1/users/bookmarks
 * @desc    Get user bookmarks
 * @access  Private
 */
router.get('/bookmarks', authenticate, async (req, res) => {
  try {
    const userId = req.user!.userId;

    const bookmarks = await prisma.bookmark.findMany({
      where: { userId },
      include: {
        qna: {
          include: {
            topic: {
              select: {
                id: true,
                name: true
              }
            }
          }
        },
        pdf: {
          include: {
            topic: {
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
      data: bookmarks
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   POST /api/v1/users/bookmarks
 * @desc    Add bookmark
 * @access  Private
 */
router.post('/bookmarks', authenticate, async (req, res): Promise<any> => {
  try {
    const userId = req.user!.userId;
    const { qnaId, pdfId } = req.body;

    if (!qnaId && !pdfId) {
      return res.status(400).json({
        success: false,
        message: 'Either qnaId or pdfId is required'
      });
    }

    const bookmark = await prisma.bookmark.create({
      data: {
        userId,
        qnaId: qnaId || null,
        pdfId: pdfId || null
      }
    });

    res.status(201).json({
      success: true,
      message: 'Bookmark added successfully',
      data: bookmark
    });
  } catch (error: any) {
    if (error.code === 'P2002') {
      return res.status(400).json({
        success: false,
        message: 'Already bookmarked'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   DELETE /api/v1/users/bookmarks/:bookmarkId
 * @desc    Remove bookmark
 * @access  Private
 */
router.delete('/bookmarks/:bookmarkId', authenticate, async (req, res) => {
  try {
    const userId = req.user!.userId;
    const { bookmarkId } = req.params;

    await prisma.bookmark.deleteMany({
      where: {
        id: bookmarkId,
        userId
      }
    });

    res.json({
      success: true,
      message: 'Bookmark removed successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   GET /api/v1/users/progress
 * @desc    Get user progress across all topics
 * @access  Private
 */
router.get('/progress', authenticate, async (req, res) => {
  try {
    const userId = req.user!.userId;

    const progress = await prisma.progress.findMany({
      where: { userId },
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
      orderBy: { lastAccessedAt: 'desc' }
    });

    res.json({
      success: true,
      data: progress
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   GET /api/v1/users/stats
 * @desc    Get user statistics (quiz attempts, accuracy, etc.)
 * @access  Private
 */
router.get('/stats', authenticate, async (req, res) => {
  try {
    const userId = req.user!.userId;

    // Get quiz attempts
    const attempts = await prisma.quizAttempt.findMany({
      where: { userId }
    });

    const totalAttempts = attempts.length;
    const correctAttempts = attempts.filter(a => a.isCorrect).length;
    const accuracy = totalAttempts > 0 ? (correctAttempts / totalAttempts) * 100 : 0;

    // Get average time
    const attemptsWithTime = attempts.filter(a => a.timeTaken !== null);
    const avgTime = attemptsWithTime.length > 0
      ? attemptsWithTime.reduce((sum, a) => sum + (a.timeTaken || 0), 0) / attemptsWithTime.length
      : 0;

    // Get progress overview
    const progressData = await prisma.progress.findMany({
      where: { userId },
      select: {
        completionPercent: true
      }
    });

    const avgProgress = progressData.length > 0
      ? progressData.reduce((sum, p) => sum + p.completionPercent, 0) / progressData.length
      : 0;

    res.json({
      success: true,
      data: {
        quizAttempts: {
          total: totalAttempts,
          correct: correctAttempts,
          accuracy: Math.round(accuracy * 100) / 100
        },
        avgTimePerQuiz: Math.round(avgTime),
        overallProgress: Math.round(avgProgress * 100) / 100,
        topicsStarted: progressData.length
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
 * @route   POST /api/v1/users/progress
 * @desc    Update topic progress
 * @access  Private
 */
router.post('/progress', authenticate, async (req, res) => {
  try {
    const userId = req.user!.userId;
    const { topicId, completionPercent, score } = req.body;

    const progress = await prisma.progress.upsert({
      where: {
        userId_topicId: {
          userId,
          topicId
        }
      },
      update: {
        completionPercent: completionPercent || 0,
        score: score || null,
        lastAccessedAt: new Date()
      },
      create: {
        userId,
        topicId,
        completionPercent: completionPercent || 0,
        score: score || null
      }
    });

    res.json({
      success: true,
      message: 'Progress updated successfully',
      data: progress
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

/**
 * @route   GET /api/v1/users/quiz-attempts
 * @desc    Get user's quiz attempt history with filtering and pagination
 * @access  Private
 */
router.get('/quiz-attempts', authenticate, async (req, res) => {
  try {
    const userId = req.user!.userId;
    const { productId, topicId, isCorrect, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);
    const take = parseInt(limit as string);

    const whereClause: any = { userId };

    if (isCorrect !== undefined) {
      whereClause.isCorrect = isCorrect === 'true';
    }

    if (topicId) {
      whereClause.quiz = {
        topicId: topicId as string
      };
    } else if (productId) {
      whereClause.quiz = {
        topic: {
          productId: productId as string
        }
      };
    }

    const [attempts, total] = await Promise.all([
      prisma.quizAttempt.findMany({
        where: whereClause,
        include: {
          quiz: {
            select: {
              id: true,
              question: true,
              correctAnswer: true,
              explanation: true,
              level: true,
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
            }
          }
        },
        skip,
        take,
        orderBy: { createdAt: 'desc' }
      }),
      prisma.quizAttempt.count({ where: whereClause })
    ]);

    const correctCount = await prisma.quizAttempt.count({
      where: { ...whereClause, isCorrect: true }
    });

    res.json({
      success: true,
      data: {
        attempts,
        pagination: {
          page: parseInt(page as string),
          limit: parseInt(limit as string),
          total,
          totalPages: Math.ceil(total / take)
        },
        stats: {
          totalAttempts: total,
          correctAttempts: correctCount,
          accuracy: total > 0 ? Math.round((correctCount / total) * 10000) / 100 : 0
        }
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
 * @route   GET /api/v1/users/quiz-attempts/:quizId
 * @desc    Get user's attempts for a specific quiz
 * @access  Private
 */
router.get('/quiz-attempts/:quizId', authenticate, async (req, res) => {
  try {
    const userId = req.user!.userId;
    const { quizId } = req.params;

    const attempts = await prisma.quizAttempt.findMany({
      where: {
        userId,
        quizId
      },
      include: {
        quiz: {
          select: {
            id: true,
            question: true,
            options: true,
            correctAnswer: true,
            explanation: true,
            level: true,
            companyTags: true,
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
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    const totalAttempts = attempts.length;
    const correctAttempts = attempts.filter(a => a.isCorrect).length;
    const bestTime = attempts.filter(a => a.timeTaken !== null).reduce((min, a) => {
      return a.timeTaken! < min ? a.timeTaken! : min;
    }, Infinity);

    res.json({
      success: true,
      data: {
        attempts,
        stats: {
          totalAttempts,
          correctAttempts,
          bestTime: bestTime === Infinity ? null : bestTime,
          lastAttempt: attempts[0] || null
        }
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
 * @route   PUT /api/v1/users/change-password
 * @desc    Change password (authenticated)
 * @access  Private
 */
router.put('/change-password', authenticate, async (req, res): Promise<any> => {
  try {
    const userId = req.user!.userId;
    const { currentPassword, newPassword } = changePasswordSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const isValidPassword = await bcrypt.compare(currentPassword, user.passwordHash);

    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);

    await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: { passwordHash }
      }),
      prisma.refreshToken.deleteMany({
        where: { userId }
      })
    ]);

    res.json({
      success: true,
      message: 'Password changed successfully. Please login again with your new password.'
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.errors
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

export default router;