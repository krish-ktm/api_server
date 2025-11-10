import { PrismaClient } from '@prisma/client';

/**
 * This script creates quiz groups for each product and assigns quizzes to them.
 * Use this after the schema has been updated and topic_id has been removed from quizzes.
 */

const prisma = new PrismaClient();

async function createQuizGroups() {
  try {
    console.log('Starting quiz group creation...');

    // 1. Get all products
    const products = await prisma.product.findMany();
    console.log(`Found ${products.length} products`);

    // 2. For each product, create a default quiz group
    for (const product of products) {
      console.log(`Creating quiz group for product: ${product.name}`);
      
      // Create a quiz group using raw SQL
      const quizGroupResult = await prisma.$queryRaw`
        INSERT INTO quiz_groups (id, product_id, name, description, \`order\`, is_active, created_at, updated_at)
        VALUES (UUID(), ${product.id}, ${`${product.name} Quizzes`}, ${`Default quiz group for ${product.name}`}, 1, 1, NOW(), NOW())
        RETURNING id
      `;
      
      // Extract the quiz group ID
      const quizGroupId = Array.isArray(quizGroupResult) && quizGroupResult.length > 0 ? quizGroupResult[0].id : null;
      
      if (!quizGroupId) {
        console.error(`Failed to create quiz group for product: ${product.name}`);
        continue;
      }
      
      console.log(`Created quiz group: ${quizGroupId} for product: ${product.name}`);
      
      // 3. Find all quizzes that don't have a quiz group assigned
      const quizzesWithoutGroupResult = await prisma.$queryRaw`
        SELECT id FROM quizzes WHERE quiz_group_id IS NULL
      `;
      
      const quizzesWithoutGroup = Array.isArray(quizzesWithoutGroupResult) ? quizzesWithoutGroupResult : [];
      console.log(`Found ${quizzesWithoutGroup.length} quizzes without a group`);
      
      // 4. Update each quiz to belong to this quiz group
      if (quizzesWithoutGroup.length > 0) {
        await prisma.$executeRaw`
          UPDATE quizzes SET quiz_group_id = ${quizGroupId} WHERE quiz_group_id IS NULL
        `;
        
        console.log(`Assigned ${quizzesWithoutGroup.length} quizzes to quiz group: ${quizGroupId}`);
      }
    }

    console.log('Quiz group creation completed successfully!');
  } catch (error) {
    console.error('Error during quiz group creation:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

createQuizGroups()
  .then(() => console.log('Process completed successfully'))
  .catch((error) => {
    console.error('Process failed:', error);
    process.exit(1);
  });
