# 🚀 Multi-Product Learning API

A scalable, database-independent API server for multiple learning products with JWT authentication, role-based access control, and comprehensive content management.

## ✨ Features

- **🔐 Secure Authentication**: JWT-based auth with access & refresh tokens
- **👥 Role-Based Access**: User, Admin, and Master Admin roles
- **📚 Multi-Product Support**: Modular system for multiple learning products
- **🏷️ Company Tag Filtering**: Filter Q&A and quizzes by company tags
- **📊 Progress Tracking**: Track user quiz attempts and topic progress
- **🔖 Bookmarks**: Save Q&A and PDFs for quick access
- **📈 Analytics Dashboard**: Admin analytics for usage insights
- **🗄️ Database Flexibility**: Easy switching between MySQL, PostgreSQL, MongoDB
- **📖 API Documentation**: Auto-generated Swagger docs
- **🐳 Docker Ready**: Containerized deployment

## 🛠️ Tech Stack

- **Backend**: Node.js + Express.js
- **ORM**: Prisma
- **Database**: MySQL (default, switchable)
- **Authentication**: JWT + bcrypt
- **Validation**: Zod
- **Documentation**: Swagger/OpenAPI
- **Deployment**: Docker

## 📋 Prerequisites

- Node.js 18+ 
- MySQL 8.0+ (or PostgreSQL/MongoDB)
- npm or yarn

## 🚀 Quick Start

### 1. Clone and Install

```bash
# Clone the repository
git clone <repository-url>
cd multi-product-learning-api

# Install dependencies
npm install
```

### 2. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

**Key environment variables:**

```env
DATABASE_URL="mysql://username:password@localhost:3306/learning_api"
JWT_SECRET="your-super-secret-jwt-key"
MASTER_ADMIN_EMAIL="admin@example.com"
MASTER_ADMIN_PASSWORD="SecurePassword123!"
```

### 3. Database Setup

```bash
# Generate Prisma Client
npm run db:generate

# Run migrations
npm run db:migrate

# Seed database with sample data
npm run db:seed
```

### 4. Start Development Server

```bash
npm run dev
```

Server will start at `http://localhost:3000`

**Access API Documentation:** `http://localhost:3000/api-docs`

## 🐳 Docker Deployment

### Development with Docker Compose

```bash
# Start all services (MySQL + API)
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

### Production Build

```bash
# Build image
docker build -t learning-api:latest .

# Run container
docker run -p 3000:3000 \
  -e DATABASE_URL="mysql://user:pass@host:3306/db" \
  -e JWT_SECRET="your-secret" \
  learning-api:latest
```

## 📡 API Endpoints

### Authentication (`/api/v1/auth`)

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/register` | Register new user | Public |
| POST | `/login` | Login user | Public |
| POST | `/refresh` | Refresh access token | Public |
| POST | `/logout` | Logout user | Private |

### Users (`/api/v1/users`)

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/profile` | Get user profile | Private |
| PUT | `/profile` | Update profile | Private |
| GET | `/bookmarks` | Get bookmarks | Private |
| POST | `/bookmarks` | Add bookmark | Private |
| DELETE | `/bookmarks/:id` | Remove bookmark | Private |
| GET | `/progress` | Get progress | Private |
| POST | `/progress` | Update progress | Private |
| GET | `/stats` | Get user stats | Private |

### Products (`/api/v1/products`)

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/` | List products | Public |
| GET | `/:productId/topics` | Get topics | Public |
| GET | `/:productId/qna` | Get Q&A | Private |
| GET | `/:productId/quizzes` | Get quizzes | Private |
| POST | `/:productId/quizzes/:quizId/submit` | Submit answer | Private |
| GET | `/:productId/pdfs` | Get PDFs | Private |

**Query Parameters for Filtering:**
- `?company=amazon` - Filter by company tag
- `?topic=topicId` - Filter by topic
- `?level=intermediate` - Filter by difficulty
- `?limit=10` - Limit results

### Admin (`/api/v1/admin`)

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET/POST/PUT/DELETE | `/products` | Manage products | Master Admin |
| GET/POST/PUT/DELETE | `/topics` | Manage topics | Admin+ |
| GET/POST/PUT/DELETE | `/qna` | Manage Q&A | Admin+ |
| GET/POST/PUT/DELETE | `/quizzes` | Manage quizzes | Admin+ |
| GET/POST/PUT/DELETE | `/pdfs` | Manage PDFs | Admin+ |
| GET | `/analytics` | View analytics | Master Admin |

## 🔑 Authentication Flow

### 1. Register/Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {...},
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}
```

### 2. Use Access Token
```bash
curl -X GET http://localhost:3000/api/v1/users/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 3. Refresh Token
```bash
curl -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "YOUR_REFRESH_TOKEN"}'
```

## 🎯 Example Usage

### Get Q&A by Company

```bash
# Get Amazon interview questions
GET /api/v1/products/interview-prep-id/qna?company=amazon&level=intermediate
```

### Submit Quiz Answer

```bash
POST /api/v1/products/product-id/quizzes/quiz-id/submit
{
  "selectedAnswer": "Option B",
  "timeTaken": 45
}
```

### Add Bookmark

```bash
POST /api/v1/users/bookmarks
{
  "qnaId": "qna-uuid"
}
```

## 🔄 Switching Databases

### PostgreSQL

```env
# Update .env
DATABASE_URL="postgresql://user:password@localhost:5432/learning_api"
```

```prisma
// Update prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

```bash
npm run db:migrate
```

### MongoDB

```env
DATABASE_URL="mongodb://user:password@localhost:27017/learning_api"
```

```prisma
datasource db {
  provider = "mongodb"
  url      = env("DATABASE_URL")
}
```

## 📊 Database Schema

```
users ──┐
        ├─► bookmarks ──► qna
        ├─► progress ──► topics ──► products
        └─► quiz_attempts ──► quizzes
```

## 🛡️ Security Features

- **Password Hashing**: bcrypt with salt rounds
- **JWT Tokens**: Separate access & refresh tokens
- **Rate Limiting**: Prevents brute force attacks
- **Helmet**: Security headers
- **CORS**: Configurable origin restrictions
- **Role-Based Access**: Fine-grained permissions

## 📈 Production Deployment

### Railway / Render

1. Connect GitHub repository
2. Set environment variables
3. Deploy automatically

### VPS (Ubuntu)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Clone and deploy
git clone <repo>
cd multi-product-learning-api
docker-compose up -d
```

## 🧪 Testing

```bash
# Run tests (add your test suite)
npm test

# Test API endpoints
npm run test:api
```

## 📝 Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm start` | Start production server |
| `npm run db:generate` | Generate Prisma Client |
| `npm run db:push` | Push schema to database |
| `npm run db:migrate` | Run migrations |
| `npm run db:seed` | Seed database |
| `npm run db:studio` | Open Prisma Studio |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

## 📄 License

MIT License - feel free to use in your projects!

## 💡 Tips

- **Use Prisma Studio** for database visualization: `npm run db:studio`
- **Check Swagger docs** for all endpoints: `/api-docs`
- **Monitor logs** in production for debugging
- **Regular backups** of your database
- **Use environment-specific configs** for dev/staging/production

## 🐛 Troubleshooting

### Database Connection Issues
```bash
# Test connection
npx prisma db pull
```

### JWT Token Errors
- Verify `JWT_SECRET` is set
- Check token expiry times
- Ensure Authorization header format: `Bearer <token>`

### Migration Issues
```bash
# Reset database (⚠️ destroys data)
npx prisma migrate reset
```

## 📞 Support

For issues and questions:
- Open GitHub issue
- Check documentation at `/api-docs`
- Review Prisma docs: https://www.prisma.io/docs

---

**Built with ❤️ for scalable learning platforms**