import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate } from '../middleware/auth';
import { asyncHandler } from '../middleware/errorHandler';
import { z } from 'zod';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticate);

const batchBookmarkCreateSchema = z.object({
  bookmarks: z.array(z.object({
    qnaId: z.string().uuid().optional(),
    pdfId: z.string().uuid().optional()
  }).refine(data => data.qnaId || data.pdfId, {
    message: 'Either qnaId or pdfId is required'
  })).min(1)
});

const batchBookmarkDeleteSchema = z.object({
  bookmarkIds: z.array(z.string().uuid()).min(1)
});

const batchProgressUpdateSchema = z.object({
  progressUpdates: z.array(z.object({
    topicId: z.string().uuid(),
    completionPercent: z.number().min(0).max(100),
    score: z.number().optional()
  })).min(1)
});

router.post('/batch/bookmarks', asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const userId = req.user!.userId;
  const { bookmarks } = batchBookmarkCreateSchema.parse(req.body);

  const results = await Promise.allSettled(
    bookmarks.map(bookmark =>
      prisma.bookmark.create({
        data: {
          userId,
          qnaId: bookmark.qnaId || null,
          pdfId: bookmark.pdfId || null
        }
      })
    )
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.status(201).json({
    success: true,
    message: `Added ${successful} bookmarks, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      created: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        bookmark: bookmarks[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.delete('/batch/bookmarks', asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const userId = req.user!.userId;
  const { bookmarkIds } = batchBookmarkDeleteSchema.parse(req.body);

  const results = await Promise.allSettled(
    bookmarkIds.map(bookmarkId =>
      prisma.bookmark.deleteMany({
        where: {
          id: bookmarkId,
          userId
        }
      })
    )
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Removed ${successful} bookmarks, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      errors: failed.map((r) => ({
        bookmarkId: bookmarkIds[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.post('/batch/progress', asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const userId = req.user!.userId;
  const { progressUpdates } = batchProgressUpdateSchema.parse(req.body);

  const results = await Promise.allSettled(
    progressUpdates.map(update =>
      prisma.progress.upsert({
        where: {
          userId_topicId: {
            userId,
            topicId: update.topicId
          }
        },
        update: {
          completionPercent: update.completionPercent,
          score: update.score || null,
          lastAccessedAt: new Date()
        },
        create: {
          userId,
          topicId: update.topicId,
          completionPercent: update.completionPercent,
          score: update.score || null
        }
      })
    )
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Updated ${successful} progress records, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      updated: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        update: progressUpdates[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

export default router;
