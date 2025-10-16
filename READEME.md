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
- **🗄️ Database**: MySQL with Prisma ORM
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
JWT_ACCESS_EXPIRY="15m"
JWT_REFRESH_EXPIRY="7d"
PORT="3000"
CORS_ORIGIN="*"
RATE_LIMIT_WINDOW_MS="900000"
RATE_LIMIT_MAX_REQUESTS="100"
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
|---|---|---|---|
| POST | `/api/v1/auth/register` | Register new user | Public |
| POST | `/api/v1/auth/login` | Login user | Public |
| POST | `/api/v1/auth/refresh` | Refresh access token | Public |
| POST | `/api/v1/auth/logout` | Logout user | Private |

### Users (`/api/v1/users`)

| Method | Endpoint | Description | Access |
|---|---|---|---|
| GET | `/api/v1/users/profile` | Get user profile | Private |
| PUT | `/api/v1/users/profile` | Update profile | Private |
| GET | `/api/v1/users/bookmarks` | Get bookmarks | Private |
| POST | `/api/v1/users/bookmarks` | Add bookmark | Private |
| DELETE | `/api/v1/users/bookmarks/:bookmarkId` | Remove bookmark | Private |
| GET | `/api/v1/users/progress` | Get progress | Private |
| POST | `/api/v1/users/progress` | Update progress | Private |
| GET | `/api/v1/users/stats` | Get user stats | Private |

### Products (`/api/v1/products`)

| Method | Endpoint | Description | Access |
|---|---|---|---|
| GET | `/api/v1/products/` | List accessible products | Private |
| GET | `/api/v1/products/:productId/topics` | Get topics | Private |
| GET | `/api/v1/products/:productId/qna` | Get Q&A (paginated) | Private |
| GET | `/api/v1/products/:productId/quizzes` | Get quizzes | Private |
| POST | `/api/v1/products/:productId/quizzes/:quizId/submit` | Submit answer | Private |
| GET | `/api/v1/products/:productId/pdfs` | Get PDFs | Private |

**Query Parameters for Filtering:**
- `?company=amazon` - Filter by company tag
- `?topic=topicId` - Filter by topic
- `?level=intermediate` - Filter by difficulty
- `?page=1` - Page number for pagination
- `?limit=10` - Number of items per page

### Admin (`/api/v1/admin`)

#### User-Product Access
| Method | Endpoint | Description | Access |
|---|---|---|---|
| POST | `/api/v1/admin/users/grant-product-access` | Grant product access | Admin, Master Admin |
| POST | `/api/v1/admin/users/revoke-product-access` | Revoke product access | Admin, Master Admin |

#### Products
| Method | Endpoint | Description | Access |
|---|---|---|---|
| GET | `/api/v1/admin/products` | List all products | Master Admin |
| POST | `/api/v1/admin/products` | Create product | Master Admin |
| PUT | `/api/v1/admin/products/:id` | Update product | Master Admin |
| DELETE | `/api/v1/admin/products/:id` | Delete product | Master Admin |

#### Topics
| Method | Endpoint | Description | Access |
|---|---|---|---|
| GET | `/api/v1/admin/topics?productId=<id>` | List topics | Admin, Master Admin |
| POST | `/api/v1/admin/topics` | Create topic | Admin, Master Admin |
| PUT | `/api/v1/admin/topics/:id` | Update topic | Admin, Master Admin |
| DELETE | `/api/v1/admin/topics/:id` | Delete topic | Admin, Master Admin |

#### Q&A
| Method | Endpoint | Description | Access |
|---|---|---|---|
| GET | `/api/v1/admin/qna?topicId=<id>` | List Q&A | Admin, Master Admin |
| POST | `/api/v1/admin/qna` | Create Q&A | Admin, Master Admin |
| PUT | `/api/v1/admin/qna/:id` | Update Q&A | Admin, Master Admin |
| DELETE | `/api/v1/admin/qna/:id` | Delete Q&A | Admin, Master Admin |

#### Quizzes
| Method | Endpoint | Description | Access |
|---|---|---|---|
| GET | `/api/v1/admin/quizzes?topicId=<id>` | List quizzes | Admin, Master Admin |
| POST | `/api/v1/admin/quizzes` | Create quiz | Admin, Master Admin |
| PUT | `/api/v1/admin/quizzes/:id` | Update quiz | Admin, Master Admin |
| DELETE | `/api/v1/admin/quizzes/:id` | Delete quiz | Admin, Master Admin |

#### PDFs
| Method | Endpoint | Description | Access |
|---|---|---|---|
| GET | `/api/v1/admin/pdfs?topicId=<id>` | List PDFs | Admin, Master Admin |
| POST | `/api/v1/admin/pdfs` | Create PDF | Admin, Master Admin |
| PUT | `/api/v1/admin/pdfs/:id` | Update PDF | Admin, Master Admin |
| DELETE | `/api/v1/admin/pdfs/:id` | Delete PDF | Admin, Master Admin |

#### Analytics
| Method | Endpoint | Description | Access |
|---|---|---|---|
| GET | `/api/v1/admin/analytics` | View platform analytics | Master Admin |

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
# Get Amazon interview questions (page 2, 5 items per page)
GET /api/v1/products/interview-prep-id/qna?company=amazon&level=intermediate&page=2&limit=5
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

## 🎯 Product Access Control

The API uses a product access control system:

- **Regular Users**: Can only access products explicitly granted to them via `UserProduct` relation
- **Admins & Master Admins**: Have access to all products automatically
- Access is checked on all product-related endpoints (topics, Q&A, quizzes, PDFs)

**Granting Access:**
```bash
POST /api/v1/admin/users/grant-product-access
{
  "userId": "user-uuid",
  "productId": "product-uuid"
}
```

## 📊 Database Schema

```
users ──┬─► bookmarks ──┬─► qna
        │               └─► pdfs
        ├─► progress ──► topics ──► products
        ├─► quiz_attempts ──► quizzes
        ├─► refresh_tokens
        └─► user_products ──► products

products ──► topics ──┬─► qna
                      ├─► quizzes
                      └─► pdfs
```

## 🛡️ Security Features

- **Password Hashing**: bcrypt with 10 salt rounds
- **JWT Tokens**: Separate access (15m) & refresh tokens (7d)
- **Token Storage**: Refresh tokens stored in database with expiry
- **Rate Limiting**: 100 requests per 15 minutes
- **Helmet**: Security headers enabled
- **CORS**: Configurable origin restrictions
- **Role-Based Access**: USER, ADMIN, MASTER_ADMIN roles
- **Input Validation**: Zod schema validation on all inputs

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
|---|---|
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
