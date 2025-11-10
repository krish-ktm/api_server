import { PrismaClient, Prisma } from '@prisma/client';

/**
 * This script migrates quiz data from the old schema (where quizzes were linked to topics)
 * to the new schema (where quizzes are linked to quiz groups which are linked to products).
 * 
 * Run this script after applying the schema migration.
 */

const prisma = new PrismaClient();

async function migrateQuizzes() {
  try {
    console.log('Starting quiz migration...');

    // 1. Get all topics with their quizzes and product information
    const topicsWithQuizzes = await prisma.topic.findMany({
      include: {
        quizzes: true,
        product: true,
      },
    });

    console.log(`Found ${topicsWithQuizzes.length} topics with quizzes to migrate`);

    // 2. For each topic, create a quiz group and migrate quizzes
    for (const topic of topicsWithQuizzes) {
      if (topic.quizzes.length === 0) {
        console.log(`Topic ${topic.id} (${topic.name}) has no quizzes, skipping`);
        continue;
      }

      console.log(`Migrating ${topic.quizzes.length} quizzes from topic: ${topic.name}`);

      // Create a quiz group for this topic
      // We need to use prisma.$queryRaw or a different approach since the schema is changing
      const quizGroup = await prisma.$queryRaw`
        INSERT INTO quiz_groups (id, product_id, name, description, \`order\`, is_active, created_at, updated_at)
        VALUES (UUID(), ${topic.productId}, ${`${topic.name} Quizzes`}, ${`Quizzes for ${topic.name}`}, ${topic.order}, 1, NOW(), NOW())
        RETURNING id, name
      `;
      
      const quizGroupId = Array.isArray(quizGroup) && quizGroup.length > 0 ? quizGroup[0].id : null;
      
      if (!quizGroupId) {
        console.error(`Failed to create quiz group for topic: ${topic.name}`);
        continue;
      }
      
      console.log(`Created quiz group: ${quizGroupId} for topic: ${topic.name}`);

      // Migrate each quiz to the new quiz group
      for (const quiz of topic.quizzes) {
        // Handle JSON fields properly
        const options = quiz.options as Prisma.JsonValue;
        const companyTags = quiz.companyTags as Prisma.JsonValue | null;
        
        // Use raw SQL query to insert the quiz
        await prisma.$queryRaw`
          INSERT INTO quizzes (
            id, quiz_group_id, question, options, correct_answer, 
            explanation, level, company_tags, created_at, updated_at
          )
          VALUES (
            UUID(), ${quizGroupId}, ${quiz.question}, ${JSON.stringify(options)}, 
            ${quiz.correctAnswer}, ${quiz.explanation || null}, ${quiz.level}, 
            ${companyTags ? JSON.stringify(companyTags) : null}, NOW(), NOW()
          )
        `;
      }

      console.log(`Migrated ${topic.quizzes.length} quizzes to quiz group: ${quizGroupId}`);
    }

    console.log('Quiz migration completed successfully!');
  } catch (error) {
    console.error('Error during quiz migration:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

migrateQuizzes()
  .then(() => console.log('Migration completed successfully'))
  .catch((error) => {
    console.error('Migration failed:', error);
    process.exit(1);
  });
