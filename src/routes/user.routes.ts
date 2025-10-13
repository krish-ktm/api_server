// src/routes/user.routes.ts

import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

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
router.post('/bookmarks', authenticate, async (req, res) => {
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

export default router;