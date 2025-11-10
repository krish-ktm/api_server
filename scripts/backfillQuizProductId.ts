import { PrismaClient } from '@prisma/client';

// Back-fill Quiz.productId for existing rows after making the column required.
// 1. Finds quizzes whose productId is currently NULL
// 2. Fetches the topic -> product relation
// 3. Updates each quiz with the corresponding productId

(async () => {
  const prisma = new PrismaClient();
  console.log('🔄  Starting back-fill for Quiz.productId ...');

  const quizzes = await prisma.quiz.findMany({
    where: {
      productId: null,
    },
    include: {
      topic: {
        select: { productId: true },
      },
    },
  });

  let updated = 0;
  for (const q of quizzes) {
    if (q.topic?.productId) {
      await prisma.quiz.update({
        where: { id: q.id },
        data: { productId: q.topic.productId },
      });
      updated += 1;
    }
  }

  console.log(`✅  Back-fill completed. Updated ${updated} records.`);
  await prisma.$disconnect();
})();
