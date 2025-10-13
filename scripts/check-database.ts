// scripts/check-database.ts
// Run with: npx tsx scripts/check-database.ts

import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
});

interface CheckResult {
  name: string;
  status: 'PASS' | 'FAIL' | 'WARN';
  message: string;
  details?: any;
}

const results: CheckResult[] = [];

function printResult(result: CheckResult) {
  const icons = { PASS: '✓', FAIL: '✗', WARN: '⚠' };
  const colors = { 
    PASS: '\x1b[32m', // Green
    FAIL: '\x1b[31m', // Red
    WARN: '\x1b[33m'  // Yellow
  };
  const reset = '\x1b[0m';
  
  console.log(`${colors[result.status]}${icons[result.status]} ${result.name}${reset}`);
  console.log(`  ${result.message}`);
  if (result.details) {
    console.log(`  Details:`, result.details);
  }
  console.log('');
}

async function checkEnvironmentVariables() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('1. CHECKING ENVIRONMENT VARIABLES');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // Check DATABASE_URL
  if (process.env.DATABASE_URL) {
    results.push({
      name: 'DATABASE_URL',
      status: 'PASS',
      message: 'Environment variable is set',
      details: process.env.DATABASE_URL.replace(/:[^:@]+@/, ':****@') // Hide password
    });
  } else {
    results.push({
      name: 'DATABASE_URL',
      status: 'FAIL',
      message: 'DATABASE_URL not found in environment',
      details: 'Add DATABASE_URL to your .env file'
    });
  }

  // Check JWT_SECRET
  if (process.env.JWT_SECRET) {
    results.push({
      name: 'JWT_SECRET',
      status: 'PASS',
      message: 'JWT_SECRET is set'
    });
  } else {
    results.push({
      name: 'JWT_SECRET',
      status: 'WARN',
      message: 'JWT_SECRET not set (required for production)'
    });
  }

  // Check PORT
  if (process.env.PORT) {
    results.push({
      name: 'PORT',
      status: 'PASS',
      message: `Server will run on port ${process.env.PORT}`
    });
  } else {
    results.push({
      name: 'PORT',
      status: 'WARN',
      message: 'PORT not set, will default to 3000'
    });
  }

  results.forEach(printResult);
}

async function checkDatabaseConnection() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('2. TESTING DATABASE CONNECTION');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  try {
    await prisma.$connect();
    printResult({
      name: 'Database Connection',
      status: 'PASS',
      message: 'Successfully connected to database'
    });

    // Test query
    const result = await prisma.$queryRaw`SELECT 1 as test`;
    printResult({
      name: 'Database Query',
      status: 'PASS',
      message: 'Successfully executed test query',
      details: result
    });

  } catch (error: any) {
    printResult({
      name: 'Database Connection',
      status: 'FAIL',
      message: 'Failed to connect to database',
      details: {
        error: error.message,
        code: error.code,
        hint: getDatabaseErrorHint(error)
      }
    });
    
    console.log('\x1b[31m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1b[0m');
    console.log('\x1b[31mCONNECTION FAILED - STOPPING HERE\x1b[0m');
    console.log('\x1b[31m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1b[0m\n');
    
    await prisma.$disconnect();
    process.exit(1);
  }
}

async function checkDatabaseSchema() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('3. CHECKING DATABASE SCHEMA');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  try {
    // Check if tables exist
    const tables: any = await prisma.$queryRaw`
      SELECT TABLE_NAME 
      FROM information_schema.TABLES 
      WHERE TABLE_SCHEMA = DATABASE()
    `;

    if (tables.length === 0) {
      printResult({
        name: 'Database Tables',
        status: 'FAIL',
        message: 'No tables found in database',
        details: 'Run: npm run db:migrate or npm run db:push'
      });
      return;
    }

    printResult({
      name: 'Database Tables',
      status: 'PASS',
      message: `Found ${tables.length} tables`,
      details: tables.map((t: any) => t.TABLE_NAME).join(', ')
    });

    // Check required tables
    const requiredTables = [
      'users', 'products', 'topics', 'qna', 
      'quizzes', 'pdfs', 'bookmarks', 'progress', 
      'quiz_attempts', 'refresh_tokens'
    ];

    const existingTables = tables.map((t: any) => t.TABLE_NAME);
    const missingTables = requiredTables.filter(t => !existingTables.includes(t));

    if (missingTables.length === 0) {
      printResult({
        name: 'Required Tables',
        status: 'PASS',
        message: 'All required tables exist'
      });
    } else {
      printResult({
        name: 'Required Tables',
        status: 'WARN',
        message: `Missing ${missingTables.length} tables`,
        details: missingTables.join(', ')
      });
    }

  } catch (error: any) {
    printResult({
      name: 'Database Schema',
      status: 'FAIL',
      message: 'Failed to check database schema',
      details: error.message
    });
  }
}

async function checkDatabaseData() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('4. CHECKING DATABASE DATA');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  try {
    // Check users
    const userCount = await prisma.user.count();
    if (userCount === 0) {
      printResult({
        name: 'Users Table',
        status: 'WARN',
        message: 'No users found in database',
        details: 'Run: npm run db:seed'
      });
    } else {
      printResult({
        name: 'Users Table',
        status: 'PASS',
        message: `Found ${userCount} users`
      });

      // Check for admin
      const adminCount = await prisma.user.count({
        where: { role: 'MASTER_ADMIN' }
      });

      if (adminCount === 0) {
        printResult({
          name: 'Admin User',
          status: 'WARN',
          message: 'No MASTER_ADMIN user found',
          details: 'Run: npm run db:seed to create admin user'
        });
      } else {
        const admin = await prisma.user.findFirst({
          where: { role: 'MASTER_ADMIN' },
          select: { email: true }
        });
        printResult({
          name: 'Admin User',
          status: 'PASS',
          message: 'MASTER_ADMIN user exists',
          details: `Email: ${admin?.email}`
        });
      }
    }

    // Check products
    const productCount = await prisma.product.count();
    if (productCount === 0) {
      printResult({
        name: 'Products Table',
        status: 'WARN',
        message: 'No products found',
        details: 'Run: npm run db:seed or create products via admin panel'
      });
    } else {
      printResult({
        name: 'Products Table',
        status: 'PASS',
        message: `Found ${productCount} products`
      });
    }

    // Check topics
    const topicCount = await prisma.topic.count();
    printResult({
      name: 'Topics Table',
      status: topicCount > 0 ? 'PASS' : 'WARN',
      message: `Found ${topicCount} topics`
    });

    // Check Q&A
    const qnaCount = await prisma.qnA.count();
    printResult({
      name: 'Q&A Table',
      status: qnaCount > 0 ? 'PASS' : 'WARN',
      message: `Found ${qnaCount} Q&A entries`
    });

    // Check quizzes
    const quizCount = await prisma.quiz.count();
    printResult({
      name: 'Quizzes Table',
      status: quizCount > 0 ? 'PASS' : 'WARN',
      message: `Found ${quizCount} quizzes`
    });

  } catch (error: any) {
    printResult({
      name: 'Database Data',
      status: 'FAIL',
      message: 'Failed to check database data',
      details: error.message
    });
  }
}

function getDatabaseErrorHint(error: any): string {
  const message = error.message?.toLowerCase() || '';
  
  if (message.includes('econnrefused') || message.includes('connection refused')) {
    return 'MySQL server is not running. Start it with:\n' +
           '  - Windows: services.msc → Start MySQL\n' +
           '  - Mac: brew services start mysql\n' +
           '  - Linux: sudo systemctl start mysql';
  }
  
  if (message.includes('access denied') || message.includes('authentication failed')) {
    return 'Wrong username or password in DATABASE_URL.\n' +
           'Check your .env file and verify MySQL credentials.';
  }
  
  if (message.includes('unknown database')) {
    return 'Database does not exist. Create it with:\n' +
           '  mysql -u root -p -e "CREATE DATABASE learning_api;"';
  }
  
  if (message.includes('timeout')) {
    return 'Connection timed out. Check if:\n' +
           '  - MySQL is running\n' +
           '  - Firewall is not blocking port 3306\n' +
           '  - Host/port in DATABASE_URL is correct';
  }
  
  return 'Check your DATABASE_URL in .env file';
}

async function printSummaryAndRecommendations() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('5. SUMMARY & RECOMMENDATIONS');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  const passCount = results.filter(r => r.status === 'PASS').length;
  const failCount = results.filter(r => r.status === 'FAIL').length;
  const warnCount = results.filter(r => r.status === 'WARN').length;

  console.log(`✓ Passed: ${passCount}`);
  console.log(`✗ Failed: ${failCount}`);
  console.log(`⚠ Warnings: ${warnCount}\n`);

  if (failCount > 0) {
    console.log('\x1b[31m❌ CRITICAL ISSUES FOUND\x1b[0m\n');
    console.log('Fix the failures above before starting the server.\n');
  } else if (warnCount > 0) {
    console.log('\x1b[33m⚠️  WARNINGS FOUND\x1b[0m\n');
    console.log('Server will work but some features may not be available.\n');
    console.log('Recommended actions:');
    console.log('  1. Run: npm run db:seed');
    console.log('  2. This will create sample data and admin user\n');
  } else {
    console.log('\x1b[32m✅ ALL CHECKS PASSED!\x1b[0m\n');
    console.log('Your database is ready. You can start the server with:');
    console.log('  npm run dev\n');
  }

  console.log('For more help, see: DEBUG-GUIDE.md\n');
}

async function main() {
  console.log('\n');
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║                                                            ║');
  console.log('║   🔍 Database Connection Checker                          ║');
  console.log('║                                                            ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('\n');

  try {
    await checkEnvironmentVariables();
    await checkDatabaseConnection();
    await checkDatabaseSchema();
    await checkDatabaseData();
    await printSummaryAndRecommendations();

  } catch (error: any) {
    console.error('\n\x1b[31m❌ UNEXPECTED ERROR:\x1b[0m', error.message);
    console.error(error.stack);
  } finally {
    await prisma.$disconnect();
  }
}

main();