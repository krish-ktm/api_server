import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

/**
 * This script executes the SQL migration script for quiz structure changes
 * Use this when Prisma migrate is not available (e.g., on shared hosting)
 */

const prisma = new PrismaClient();

async function executeSqlMigration() {
  try {
    console.log('Starting SQL migration for quiz structure...');

    // Read the SQL migration file
    const sqlFilePath = path.join(__dirname, 'migrate-quiz-structure.sql');
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');

    // Split the SQL content by semicolons to get individual statements
    // This is a simple approach and might not work for all SQL statements
    const statements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0);

    console.log(`Found ${statements.length} SQL statements to execute`);

    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      try {
        console.log(`Executing statement ${i + 1}/${statements.length}...`);
        await prisma.$executeRawUnsafe(statement);
        console.log(`Statement ${i + 1} executed successfully`);
      } catch (error) {
        console.error(`Error executing statement ${i + 1}:`, error);
        console.error('Statement:', statement);
        throw error;
      }
    }

    console.log('SQL migration completed successfully!');
  } catch (error) {
    console.error('Error during SQL migration:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

executeSqlMigration()
  .then(() => console.log('Migration completed successfully'))
  .catch((error) => {
    console.error('Migration failed:', error);
    process.exit(1);
  });
