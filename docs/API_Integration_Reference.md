# API Integration & Reference

A complete reference for integrating with the QnA PROD REST API.

---

## 1. Overview
The API is a versioned, **JSON-only** HTTP interface built with Express + TypeScript and secured by **JWT Bearer** authentication.

* Base path: `https://<domain>/api/v1`  
* All successful responses use HTTP `200/201` and the envelope:

```json
{
  "success": true,
  "message": "<human-readable message>",
  "data": { /* payload */ }
}
```
* Errors always include `success: false` and a descriptive `message`.
* Time values are ISO-8601 strings (`YYYY-MM-DDTHH:mm:ss.sssZ`).

---

## 2. Authentication
The API issues a short-lived **access token** and a long-lived **refresh token**.
Send the access token in the request header:

```
Authorization: Bearer <ACCESS_TOKEN>
```

### Common error response
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

### Endpoints
| Method | Path | Description | Public/Private |
| ------ | ---- | ----------- | -------------- |
| POST | `/auth/register` | Register a new user | Public |
| POST | `/auth/login` | Obtain tokens | Public |
| POST | `/auth/refresh` | Re-issue access token | Public |
| POST | `/auth/logout` | Invalidate refresh token | Private |
| POST | `/auth/forgot-password` | Request password-reset link | Public |
| POST | `/auth/reset-password` | Reset password | Public |

#### Example – Login
Request:
```bash
curl -X POST \ 
  https://<domain>/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
        "email": "john@example.com",
        "password": "secret123"
      }'
```

Successful response (`200`):
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid",
      "name": "John",
      "email": "john@example.com",
      "role": "USER"
    },
    "accessToken": "<JWT>",
    "refreshToken": "<JWT>"
  }
}
```

---

## 3. User Endpoints
| Method | Path | Description |
| ------ | ---- | ----------- |
| GET | `/users/profile` | Current user profile |
| PUT | `/users/profile` | Update profile fields |
| GET | `/users/bookmarks` | List bookmarks |
| POST | `/users/bookmarks` | Add bookmark |
| DELETE | `/users/bookmarks/:bookmarkId` | Remove bookmark |
| GET | `/users/progress` | Progress across topics |
| POST | `/users/progress` | Update topic progress |
| GET | `/users/quiz-attempts` | Paginated attempts |
| GET | `/users/quiz-attempts/:quizId` | Attempts for a quiz |
| GET | `/users/stats` | Aggregated stats |
| PUT | `/users/change-password` | Change own password |

Example – Get Profile
```bash
curl -H "Authorization: Bearer <ACCESS_TOKEN>" \
     https://<domain>/api/v1/users/profile
```

---

## 4. Product & Content Endpoints
Most product routes require that the authenticated user **has been granted access** or holds an `ADMIN`/`MASTER_ADMIN` role.

| Method | Path | Description |
| ------ | ---- | ----------- |
| GET | `/products` | Products list visible to user |
| GET | `/products/:productId/topics` | Topics for a product |
| GET | `/products/:productId/qna` | Filterable Q-and-A list |
| GET | `/products/:productId/qna/:qnaId` | Q-and-A detail |
| GET | `/products/:productId/quizzes` | Filterable quizzes |
| GET | `/products/:productId/quizzes/:quizId` | Quiz detail |
| POST | `/products/:productId/quizzes/:quizId/submit` | Submit answer |
| GET | `/products/:productId/pdfs` | PDFs list |
| GET | `/products/:productId/pdfs/:pdfId` | PDF metadata |

Example – Submit Quiz Answer
```bash
curl -X POST \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  https://<domain>/api/v1/products/1234/quizzes/abcd/submit \
  -d '{
        "selectedAnswer": "A",
        "timeTaken": 32
      }'
```
Expected response:
```json
{
  "success": true,
  "message": "Correct answer!",
  "data": {
    "isCorrect": true,
    "correctAnswer": "A",
    "explanation": "Option A is correct because …",
    "attempt": { /* attempt object */ }
  }
}
```

---

## 5. Admin Endpoints
Requires `role === ADMIN` or `MASTER_ADMIN` depending on section. Supply the **access token** of an admin account.

### User Management
| Method | Path | Description | Role |
| ------ | ---- | ----------- | ---- |
| GET | `/admin/users` | List users (paginate/filter) | Admin+ |
| GET | `/admin/users/:id` | User detail | Admin+ |
| PUT | `/admin/users/:id/role` | Change role | Admin+ |
| DELETE | `/admin/users/:id` | Delete user | Admin+ |
| GET | `/admin/users/:userId/products` | Products assigned | Admin+ |
| POST | `/admin/users/grant-product-access` | Grant product to user | Admin+ |
| POST | `/admin/users/revoke-product-access` | Revoke product | Admin+ |

### Product CRUD (Master Admin)
| Method | Path | Description |
| ------ | ---- | ----------- |
| GET | `/admin/products` | List all products |
| GET | `/admin/products/:id` | Product detail |
| POST | `/admin/products` | Create product |
| PUT | `/admin/products/:id` | Update product |
| DELETE | `/admin/products/:id` | Delete product |

### Topic CRUD (Admin+)
| Method | Path | Description |
| ------ | ---- | ----------- |
| GET | `/admin/topics` | List topics (filterable) |
| GET | `/admin/topics/:id` | Topic detail |
| POST | `/admin/topics` | Create topic |
| PUT | `/admin/topics/:id` | Update topic |
| DELETE | `/admin/topics/:id` | Delete topic |

### Q&A / Quiz / PDF Admin routes
Refer to route names; pattern mirrors `GET /admin/qna`, `/admin/quizzes`, `/admin/pdfs` etc. Each supports full CRUD.

---

## 6. Pagination & Filtering
List routes accept the standard query parameters:
* `page` – 1-based page number (default 1)
* `limit` – items per page (default 10)

Domain-specific filters (e.g. `company`, `topic`, `level`) are shown in the route description.
Successful responses wrap pagination info:
```json
{
  "success": true,
  "data": {
    "items": [ /* … */ ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 87,
      "totalPages": 9
    }
  }
}
```

---

## 7. Webhook / Future Extensions
There are currently no webhooks. Contact the backend team for bespoke integrations.

---

## 8. Postman Collection
A ready-made collection is provided in the repo at `postman_collection.json`.
Import it into Postman to explore every endpoint with example requests.

---

## 9. Database Schema Overview
Below is a high-level look at the relational model (Prisma schema). Use this to understand object shapes returned by the API.

| Entity | Table (DB) | Primary Key | Notable Fields | Relationships |
| ------ | ---------- | ----------- | -------------- | ------------- |
| **User** | `users` | `id` (UUID) | `name`, `email`, `role`, timestamps | 1-N `bookmarks`, `progress`, `quiz_attempts`, `refresh_tokens`; M-N `products` via `user_products` |
| **Product** | `products` | `id` | `name`, `slug`, `description`, `is_active` | 1-N **topics**; M-N **users** via `user_products` |
| **Topic** | `topics` | `id` | `product_id`, `name`, `order` | Belongs to **product**; 1-N **qna**, **quizzes**, **pdfs**, **progress** |
| **QnA** | `qna` | `id` | `topic_id`, `question`, `answer`, `level`, `company_tags` | Belongs to **topic**; 1-N **bookmarks** |
| **Quiz** | `quizzes` | `id` | `topic_id`, `question`, `options[]`, `correct_answer`, `level`, `company_tags` | Belongs to **topic**; 1-N **quiz_attempts** |
| **PDF** | `pdfs` | `id` | `topic_id`, `title`, `file_url`, `file_size` | Belongs to **topic**; 1-N **bookmarks** |
| **Bookmark** | `bookmarks` | `id` | `user_id`, `qna_id?`, `pdf_id?` | Belongs to **user** and either **qna** or **pdf** |
| **Progress** | `progress` | `id` | `user_id`, `topic_id`, `completion_percent`, `score` | Belongs to **user** & **topic** |
| **QuizAttempt** | `quiz_attempts` | `id` | `user_id`, `quiz_id`, `selected_answer`, `is_correct`, `time_taken` | Belongs to **user** & **quiz** |
| **UserProduct** | `user_products` | Composite (`user_id`,`product_id`) | access join table | Links **users** ↔ **products** |
| **RefreshToken** | `refresh_tokens` | `id` | `user_id`, `token`, `expires_at` | Belongs to **user** |
| **PasswordResetToken** | `password_reset_tokens` | `id` | `user_id`, `token`, `expires_at` | Belongs to **user** |

### Enumerations
* `Role`: `USER`, `ADMIN`, `MASTER_ADMIN`
* `DifficultyLevel`: `BEGINNER`, `INTERMEDIATE`, `ADVANCED`

### ER Diagram (simplified)
```
User--<Bookmark
User--<Progress
User--<QuizAttempt
User--<RefreshToken
User--<PasswordResetToken
User--<UserProduct>--Product--<Topic--<QnA
                                 |--<Quiz--<QuizAttempt
                                 |--<PDF
```

---

## 10. Changelog
See `CHANGELOG.md` (if present) or Git history for endpoint evolution.

---

### Happy Integrating! 🙌
