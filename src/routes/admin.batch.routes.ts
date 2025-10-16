import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, authorize } from '../middleware/auth';
import { z } from 'zod';
import { asyncHandler } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticate);

const batchUserProductSchema = z.object({
  operations: z.array(z.object({
    userId: z.string().uuid(),
    productId: z.string().uuid()
  })).min(1)
});

const batchQnaCreateSchema = z.object({
  items: z.array(z.object({
    topicId: z.string().uuid(),
    question: z.string().min(1),
    answer: z.string().min(1),
    level: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']).optional(),
    companyTags: z.array(z.string()).optional()
  })).min(1)
});

const batchQnaUpdateSchema = z.object({
  updates: z.array(z.object({
    id: z.string().uuid(),
    question: z.string().min(1).optional(),
    answer: z.string().min(1).optional(),
    level: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']).optional(),
    companyTags: z.array(z.string()).optional()
  })).min(1)
});

const batchDeleteSchema = z.object({
  ids: z.array(z.string().uuid()).min(1)
});

const batchQuizCreateSchema = z.object({
  items: z.array(z.object({
    topicId: z.string().uuid(),
    question: z.string().min(1),
    options: z.array(z.string()).min(2),
    correctAnswer: z.string().min(1),
    explanation: z.string().optional(),
    level: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']).optional(),
    companyTags: z.array(z.string()).optional()
  })).min(1)
});

const batchQuizUpdateSchema = z.object({
  updates: z.array(z.object({
    id: z.string().uuid(),
    question: z.string().min(1).optional(),
    options: z.array(z.string()).min(2).optional(),
    correctAnswer: z.string().min(1).optional(),
    explanation: z.string().optional(),
    level: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']).optional(),
    companyTags: z.array(z.string()).optional()
  })).min(1)
});

const batchPdfCreateSchema = z.object({
  items: z.array(z.object({
    topicId: z.string().uuid(),
    title: z.string().min(1),
    description: z.string().optional(),
    fileUrl: z.string().url(),
    fileSize: z.number().int().optional()
  })).min(1)
});

const batchPdfUpdateSchema = z.object({
  updates: z.array(z.object({
    id: z.string().uuid(),
    title: z.string().min(1).optional(),
    description: z.string().optional(),
    fileUrl: z.string().url().optional(),
    fileSize: z.number().int().optional()
  })).min(1)
});

const batchTopicCreateSchema = z.object({
  items: z.array(z.object({
    productId: z.string().uuid(),
    name: z.string().min(1),
    description: z.string().optional(),
    order: z.number().int().optional()
  })).min(1)
});

const batchTopicUpdateSchema = z.object({
  updates: z.array(z.object({
    id: z.string().uuid(),
    name: z.string().min(1).optional(),
    description: z.string().optional(),
    order: z.number().int().optional()
  })).min(1)
});

router.post('/batch/users/grant-product-access', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { operations } = batchUserProductSchema.parse(req.body);

  const results = await Promise.allSettled(
    operations.map(op =>
      prisma.userProduct.create({
        data: {
          userId: op.userId,
          productId: op.productId
        }
      })
    )
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.status(201).json({
    success: true,
    message: `Granted access: ${successful} successful, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      errors: failed.map((r) => ({
        operation: operations[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.post('/batch/users/revoke-product-access', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { operations } = batchUserProductSchema.parse(req.body);

  const results = await Promise.allSettled(
    operations.map(op =>
      prisma.userProduct.delete({
        where: {
          userId_productId: {
            userId: op.userId,
            productId: op.productId
          }
        }
      })
    )
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Revoked access: ${successful} successful, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      errors: failed.map((r) => ({
        operation: operations[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.post('/batch/qna', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { items } = batchQnaCreateSchema.parse(req.body);

  const results = await Promise.allSettled(
    items.map(item => prisma.qnA.create({ data: item }))
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.status(201).json({
    success: true,
    message: `Created ${successful} Q&A items, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      created: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        item: items[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.put('/batch/qna', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { updates } = batchQnaUpdateSchema.parse(req.body);

  const results = await Promise.allSettled(
    updates.map(update => {
      const { id, ...data } = update;
      return prisma.qnA.update({
        where: { id },
        data
      });
    })
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Updated ${successful} Q&A items, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      updated: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        update: updates[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.delete('/batch/qna', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { ids } = batchDeleteSchema.parse(req.body);

  const results = await Promise.allSettled(
    ids.map(id => prisma.qnA.delete({ where: { id } }))
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Deleted ${successful} Q&A items, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      errors: failed.map((r) => ({
        id: ids[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.post('/batch/quizzes', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { items } = batchQuizCreateSchema.parse(req.body);

  const results = await Promise.allSettled(
    items.map(item => prisma.quiz.create({ data: item }))
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.status(201).json({
    success: true,
    message: `Created ${successful} quizzes, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      created: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        item: items[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.put('/batch/quizzes', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { updates } = batchQuizUpdateSchema.parse(req.body);

  const results = await Promise.allSettled(
    updates.map(update => {
      const { id, ...data } = update;
      return prisma.quiz.update({
        where: { id },
        data
      });
    })
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Updated ${successful} quizzes, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      updated: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        update: updates[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.delete('/batch/quizzes', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { ids } = batchDeleteSchema.parse(req.body);

  const results = await Promise.allSettled(
    ids.map(id => prisma.quiz.delete({ where: { id } }))
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Deleted ${successful} quizzes, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      errors: failed.map((r) => ({
        id: ids[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.post('/batch/pdfs', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { items } = batchPdfCreateSchema.parse(req.body);

  const results = await Promise.allSettled(
    items.map(item => prisma.pDF.create({ data: item }))
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.status(201).json({
    success: true,
    message: `Created ${successful} PDFs, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      created: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        item: items[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.put('/batch/pdfs', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { updates } = batchPdfUpdateSchema.parse(req.body);

  const results = await Promise.allSettled(
    updates.map(update => {
      const { id, ...data } = update;
      return prisma.pDF.update({
        where: { id },
        data
      });
    })
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Updated ${successful} PDFs, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      updated: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        update: updates[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.delete('/batch/pdfs', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { ids } = batchDeleteSchema.parse(req.body);

  const results = await Promise.allSettled(
    ids.map(id => prisma.pDF.delete({ where: { id } }))
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Deleted ${successful} PDFs, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      errors: failed.map((r) => ({
        id: ids[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.post('/batch/topics', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { items } = batchTopicCreateSchema.parse(req.body);

  const results = await Promise.allSettled(
    items.map(item => prisma.topic.create({ data: item }))
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.status(201).json({
    success: true,
    message: `Created ${successful} topics, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      created: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        item: items[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

router.put('/batch/topics', authorize('ADMIN', 'MASTER_ADMIN'), asyncHandler(async (req: Request, res: Response): Promise<any> => {
  const { updates } = batchTopicUpdateSchema.parse(req.body);

  const results = await Promise.allSettled(
    updates.map(update => {
      const { id, ...data } = update;
      return prisma.topic.update({
        where: { id },
        data
      });
    })
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected');

  res.json({
    success: true,
    message: `Updated ${successful} topics, ${failed.length} failed`,
    data: {
      successful,
      failed: failed.length,
      updated: results
        .filter(r => r.status === 'fulfilled')
        .map(r => (r as PromiseFulfilledResult<any>).value),
      errors: failed.map((r) => ({
        update: updates[results.indexOf(r)],
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }
  });
}));

export default router;
