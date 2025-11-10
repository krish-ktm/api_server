# Quiz Structure Migration Guide

This document provides instructions for migrating the quiz structure from being linked to topics to being organized under quiz groups that are directly linked to products.

## Changes Made

1. **Schema Changes**:
   - Created a new `QuizGroup` model that links directly to `Product`
   - Modified the `Quiz` model to link to `QuizGroup` instead of `Topic`
   - Removed the `quizzes` relation from the `Topic` model

2. **Data Migration**:
   - Created a migration script to move existing quizzes to the new structure
   - Each topic with quizzes will have a corresponding quiz group created
   - All quizzes will be moved to their respective quiz groups

## Migration Steps

### Option 1: For environments with full database permissions

#### 1. Apply Schema Changes

Run the Prisma migration to update the database schema:

```bash
npm run db:migrate
```

This will create a new migration file with the schema changes.

#### 2. Migrate Existing Quiz Data

After applying the schema changes, run the quiz migration script:

```bash
npm run migrate:quizzes
```

### Option 2: For restricted environments (like Hostinger)

If you're on a hosting provider that doesn't allow creating shadow databases (like Hostinger), use this alternative approach:

#### 1. Push Schema Changes

Instead of using migrations, push the schema directly:

```bash
npm run db:push:schema
```

**Note**: This will reset your database if there are incompatible changes. Make sure you have a backup of your data if needed.

#### 2. Create Quiz Groups

After pushing the schema changes, create quiz groups and assign quizzes to them:

```bash
npm run create:quiz-groups
```

This script will:
- Create a new quiz group for each product
- Find any quizzes that don't have a quiz group assigned
- Assign those quizzes to the appropriate quiz group
- Maintain all quiz data including questions, options, and correct answers

### 3. Verify Migration

After running the migration, verify that:
- All quizzes are now linked to quiz groups instead of topics
- Quiz groups are correctly linked to products
- All quiz data is preserved

## New Structure Benefits

The new structure provides several benefits:

1. **Separation of Concerns**: Quizzes are now separate from learning topics, allowing for more flexible organization
2. **Multiple Quizzes per Product**: Products can now have multiple quiz groups, each containing related quizzes
3. **Better Organization**: Quiz groups can be organized independently of the topic structure

## API Changes

If you're using the API to access quizzes, note that the endpoints will need to be updated to reflect the new structure. Quizzes are now accessed through quiz groups instead of topics.
