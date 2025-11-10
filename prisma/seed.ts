// prisma/seed.ts

import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...');

  // Create Master Admin
  const masterAdminEmail = process.env.MASTER_ADMIN_EMAIL || 'admin@example.com';
  const masterAdminPassword = process.env.MASTER_ADMIN_PASSWORD || 'Admin123!';

  const existingAdmin = await prisma.user.findUnique({
    where: { email: masterAdminEmail }
  });

  if (!existingAdmin) {
    const passwordHash = await bcrypt.hash(masterAdminPassword, 10);

    await prisma.user.create({
      data: {
        name: 'Master Admin',
        email: masterAdminEmail,
        passwordHash,
        role: 'MASTER_ADMIN'
      }
    });

    console.log('✅ Master Admin created');
    console.log(`   Email: ${masterAdminEmail}`);
    console.log(`   Password: ${masterAdminPassword}`);
  } else {
    console.log('ℹ️  Master Admin already exists');
  }

  // Create Sample Product: Interview Prep
  const interviewPrep = await prisma.product.upsert({
    where: { slug: 'interview-prep' },
    update: {},
    create: {
      name: 'Interview Prep',
      slug: 'interview-prep',
      description: 'Prepare for technical interviews with top companies',
      isActive: true
    }
  });

  console.log('✅ Product created: Interview Prep');

  // Create Topics
  const jsTopic = await prisma.topic.upsert({
    where: { id: 'js-basics-topic' },
    update: {},
    create: {
      id: 'js-basics-topic',
      productId: interviewPrep.id,
      name: 'JavaScript Basics',
      description: 'Core JavaScript concepts and fundamentals',
      order: 1
    }
  });

  const dsTopic = await prisma.topic.upsert({
    where: { id: 'data-structures-topic' },
    update: {},
    create: {
      id: 'data-structures-topic',
      productId: interviewPrep.id,
      name: 'Data Structures',
      description: 'Arrays, Linked Lists, Trees, and Graphs',
      order: 2
    }
  });

  console.log('✅ Topics created');

  // Create Sample Q&A
  await prisma.qnA.createMany({
    data: [
      {
        topicId: jsTopic.id,
        question: 'What is hoisting in JavaScript?',
        answer: 'Hoisting is JavaScript\'s default behavior of moving declarations to the top of the current scope. Variables declared with var and function declarations are hoisted.',
        level: 'INTERMEDIATE',
        companyTags: ['amazon', 'google', 'microsoft']
      },
      {
        topicId: jsTopic.id,
        question: 'Explain the difference between let, const, and var',
        answer: 'var is function-scoped and hoisted. let and const are block-scoped. const cannot be reassigned after declaration, while let can be.',
        level: 'BEGINNER',
        companyTags: ['tcs', 'infosys', 'wipro']
      },
      {
        topicId: dsTopic.id,
        question: 'What is the time complexity of binary search?',
        answer: 'Binary search has a time complexity of O(log n) as it divides the search space in half with each iteration.',
        level: 'INTERMEDIATE',
        companyTags: ['amazon', 'microsoft', 'google']
      }
    ],
    skipDuplicates: true
  });

  console.log('✅ Sample Q&A created');

  // Create Sample Quiz Groups
  const jsQuizGroup = await prisma.quizGroup.create({
    data: {
      productId: interviewPrep.id,
      name: 'JavaScript Quizzes',
      description: 'Test your JavaScript knowledge with these quizzes',
      order: 1,
      isActive: true
    }
  });

  const dsQuizGroup = await prisma.quizGroup.create({
    data: {
      productId: interviewPrep.id,
      name: 'Data Structures Quizzes',
      description: 'Test your Data Structures knowledge with these quizzes',
      order: 2,
      isActive: true
    }
  });

  console.log('✅ Sample quiz groups created');

  // Create Sample Quizzes
  await prisma.quiz.createMany({
    data: [
      {
        quizGroupId: jsQuizGroup.id,
        question: 'Which of the following is NOT a primitive data type in JavaScript?',
        options: ['String', 'Number', 'Array', 'Boolean'],
        correctAnswer: 'Array',
        explanation: 'Array is an object type, not a primitive. The primitive types are: string, number, boolean, null, undefined, symbol, and bigint.',
        level: 'BEGINNER',
        companyTags: ['amazon', 'flipkart']
      },
      {
        quizGroupId: jsQuizGroup.id,
        question: 'What will be the output of: console.log(typeof null)?',
        options: ['null', 'undefined', 'object', 'number'],
        correctAnswer: 'object',
        explanation: 'This is a known JavaScript quirk. typeof null returns "object" due to a bug in the original JavaScript implementation.',
        level: 'INTERMEDIATE',
        companyTags: ['google', 'microsoft']
      },
      {
        quizGroupId: dsQuizGroup.id,
        question: 'Which data structure uses LIFO (Last In First Out)?',
        options: ['Queue', 'Stack', 'Array', 'Tree'],
        correctAnswer: 'Stack',
        explanation: 'A stack follows LIFO principle where the last element added is the first one to be removed.',
        level: 'BEGINNER',
        companyTags: ['tcs', 'cognizant', 'infosys']
      }
    ],
    skipDuplicates: true
  });

  console.log('✅ Sample quizzes created');

  // Create Sample PDFs
  await prisma.pDF.createMany({
    data: [
      {
        topicId: jsTopic.id,
        title: 'JavaScript ES6+ Features Guide',
        description: 'Comprehensive guide covering modern JavaScript features',
        fileUrl: 'https://example.com/js-es6-guide.pdf',
        fileSize: 2048576
      },
      {
        topicId: dsTopic.id,
        title: 'Data Structures Cheat Sheet',
        description: 'Quick reference for common data structures and their operations',
        fileUrl: 'https://example.com/ds-cheat-sheet.pdf',
        fileSize: 1024000
      }
    ],
    skipDuplicates: true
  });

  console.log('✅ Sample PDFs created');

  console.log('\n🎉 Database seeded successfully!\n');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
