# Vercel 500 Error - Complete Fix Guide

## What Was Wrong

Your app was getting 500 errors on Vercel with no logs because:

1. **Server was trying to listen on a port** - Vercel serverless functions don't use `app.listen()`
2. **Multiple Prisma instances** - Each route created its own database connection, exhausting the connection pool
3. **Missing Vercel entry point** - No proper serverless function entry point
4. **Prisma binaries mismatch** - Binary wasn't compiled for Vercel's runtime environment
5. **No error catching** - Silent failures during initialization weren't being logged

## What I Fixed

### 1. Created Singleton Prisma Client (`src/lib/prisma.ts`)
```typescript
// Prevents connection pool exhaustion
const prisma = globalThis.prisma ?? new PrismaClient();
```

### 2. Fixed Server Startup (`src/index.ts`)
- Only calls `app.listen()` in development
- Added comprehensive error logging
- Checks environment variables on startup
- Catches uncaught exceptions

### 3. Created Vercel Entry Point (`api/index.ts`)
- Proper serverless function handler
- Routes all requests through Express app

### 4. Updated Prisma Schema
```prisma
generator client {
  binaryTargets = ["native", "rhel-openssl-1.0.x", "rhel-openssl-3.0.x"]
}
datasource db {
  relationMode = "prisma"
}
```

### 5. Updated All Routes
- All route files now use `import prisma from '../lib/prisma'`
- No more `new PrismaClient()` in routes

## Deploy Instructions

### Step 1: Set Environment Variables in Vercel

Go to your Vercel project settings → Environment Variables and add:

**Required:**
- `DATABASE_URL` - Your MySQL connection string
- `JWT_SECRET` - Your JWT secret key (minimum 32 characters)

**Optional (with defaults):**
- `JWT_ACCESS_EXPIRY=15m`
- `JWT_REFRESH_EXPIRY=7d`
- `CORS_ORIGIN=*` (or your frontend domain)
- `RATE_LIMIT_WINDOW_MS=900000`
- `RATE_LIMIT_MAX_REQUESTS=100`

### Step 2: Deploy

**Option A - Via Git (Recommended):**
```bash
git add .
git commit -m "Fix Vercel deployment issues"
git push
```
Vercel will auto-deploy from your connected repository.

**Option B - Via Vercel CLI:**
```bash
vercel --prod
```

### Step 3: Check Logs

After deploying, check logs to verify:

1. Go to your Vercel project
2. Click on the deployment
3. Click "Functions" tab
4. Click on `/api/index.ts`
5. You should see:
   ```
   Starting application...
   NODE_ENV: production
   DATABASE_URL exists: true
   JWT_SECRET exists: true
   Running in production mode (serverless)
   ```

### Step 4: Test the API

```bash
# Test health endpoint
curl https://your-app.vercel.app/health

# Should return:
{
  "success": true,
  "status": "healthy",
  "timestamp": "2025-10-24T..."
}
```

## Troubleshooting

### Still Getting 500 Error?

**Check 1: Environment Variables**
```bash
# In Vercel dashboard, verify all env vars are set
# Common issue: DATABASE_URL has wrong format or credentials
```

**Check 2: Database Connection**
```bash
# Ensure your database:
# - Accepts connections from Vercel IPs
# - Has correct firewall rules
# - Connection string is correct
```

**Check 3: Prisma Generation**
```bash
# Vercel should run: npm run postinstall (which runs prisma generate)
# Check build logs to confirm this ran successfully
```

**Check 4: Function Logs**
```bash
# In Vercel:
# Project → Deployments → [Your Deployment] → Functions → View Logs
# Look for the startup logs or any error messages
```

### Common Error Messages

**"Cannot find module '@prisma/client'"**
- Solution: Ensure `postinstall` script in package.json runs `prisma generate`
- Check: Vercel build logs show Prisma generation completed

**"Can't reach database server"**
- Solution: Check DATABASE_URL is correct
- Check: Database allows connections from Vercel
- Tip: Use PlanetScale for better serverless compatibility

**"Too many connections"**
- Solution: This fix addresses this with singleton Prisma client
- Check: All routes import from `src/lib/prisma.ts`

**No logs at all**
- Solution: Function might be timing out during initialization
- Check: DATABASE_URL is valid and database is responding

## Important Notes

### MySQL Connection Pooling
For better performance with serverless, consider:
- **PlanetScale** (MySQL-compatible, serverless-optimized)
- **Amazon RDS Proxy** (connection pooling)
- **Connection pooling services**

### Prisma with MySQL on Vercel
```prisma
// Use relationMode = "prisma" for better serverless compatibility
datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
  relationMode = "prisma"
}
```

### File Structure After Fix
```
your-project/
├── api/
│   └── index.ts          # Vercel serverless entry point
├── src/
│   ├── lib/
│   │   └── prisma.ts     # Singleton Prisma client
│   ├── index.ts          # Express app (now serverless-ready)
│   └── routes/           # All updated to use singleton
├── vercel.json           # Vercel configuration
└── package.json          # With postinstall script
```

## Testing Locally Before Deploy

```bash
# 1. Build the project
npm run build

# 2. Set NODE_ENV to production
export NODE_ENV=production  # Mac/Linux
# OR
set NODE_ENV=production     # Windows

# 3. Test the API entry point
node -e "const app = require('./dist/index.js').default; console.log('App exported:', !!app)"

# Should output: App exported: true
```

## Need More Help?

If you're still seeing 500 errors:

1. Share the **Vercel function logs** (the console output)
2. Share the **build logs** from Vercel
3. Confirm your **DATABASE_URL format** (remove sensitive parts):
   ```
   mysql://USER:PASS@HOST:PORT/DATABASE
   ```

The comprehensive logging I added should now show you exactly what's failing during initialization.
