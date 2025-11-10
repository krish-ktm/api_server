# TypeScript Errors After Schema Changes

After modifying the Prisma schema to separate quizzes from topics and create the QuizGroup model, you'll encounter TypeScript errors when working with the codebase. This is because the Prisma client types need to be regenerated to match the new schema.

## Common Errors

1. **Property 'quizGroup' does not exist on type 'PrismaClient'**
   - This occurs because the Prisma client doesn't know about the new QuizGroup model

2. **Object literal may only specify known properties, and 'quizGroup' does not exist in type 'QuizInclude'**
   - This happens when trying to include the quizGroup relation in queries

3. **Property 'quizGroupId' does not exist in type 'QuizCreateManyInput'**
   - This occurs when trying to create quizzes with the new quizGroupId field

## How to Fix

### 1. Regenerate Prisma Client

After pushing the schema changes to the database, regenerate the Prisma client:

```bash
npm run db:generate
```

This will update the TypeScript types to match the new schema.

### 2. Restart Your Development Server

After regenerating the Prisma client, restart your development server:

```bash
npm run dev
```

### 3. Update Import Statements (if needed)

If you're using specific imports from the Prisma client, make sure to update them to include any new types:

```typescript
import { PrismaClient, QuizGroup, Quiz } from '@prisma/client';
```

## Temporary Workaround

If you need to work with the code before regenerating the Prisma client, you can use type assertions to bypass TypeScript errors:

```typescript
// Example:
const quizGroup = await (prisma as any).quizGroup.create({
  data: {
    productId,
    name,
    // other fields
  }
});

// Or for including relations:
const quiz = await prisma.quiz.findUnique({
  where: { id },
  include: {
    quizGroup: true as any,
  }
});
```

However, it's strongly recommended to regenerate the Prisma client instead of using these workarounds.

## Additional Notes

- If you're using a CI/CD pipeline, make sure to update it to include the Prisma generate step
- If you're deploying to production, run `prisma generate` as part of your build process
- Consider adding a postinstall script to your package.json to ensure the Prisma client is always up to date:
  ```json
  "postinstall": "prisma generate"
  ```
