-- =====================================================
-- Multi-Product Learning API - MySQL Database Schema
-- =====================================================

-- Create database
-- CREATE DATABASE IF NOT EXISTS learning_api CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE learning_api;

-- =====================================================
-- USERS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `users` (
  `id` VARCHAR(191) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `role` ENUM('USER', 'ADMIN', 'MASTER_ADMIN') NOT NULL DEFAULT 'USER',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_key` (`email`),
  INDEX `idx_users_email` (`email`),
  INDEX `idx_users_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- REFRESH TOKENS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `refresh_tokens` (
  `id` VARCHAR(191) NOT NULL,
  `token` VARCHAR(500) NOT NULL,
  `user_id` VARCHAR(191) NOT NULL,
  `expires_at` DATETIME(3) NOT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `refresh_tokens_token_key` (`token`),
  INDEX `idx_refresh_tokens_user_id` (`user_id`),
  INDEX `idx_refresh_tokens_expires_at` (`expires_at`),
  CONSTRAINT `fk_refresh_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PRODUCTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `products` (
  `id` VARCHAR(191) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `slug` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `products_slug_key` (`slug`),
  INDEX `idx_products_slug` (`slug`),
  INDEX `idx_products_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- TOPICS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `topics` (
  `id` VARCHAR(191) NOT NULL,
  `product_id` VARCHAR(191) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  INDEX `idx_topics_product_id` (`product_id`),
  INDEX `idx_topics_order` (`order`),
  CONSTRAINT `fk_topics_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Q&A TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `qna` (
  `id` VARCHAR(191) NOT NULL,
  `topic_id` VARCHAR(191) NOT NULL,
  `question` TEXT NOT NULL,
  `answer` TEXT NOT NULL,
  `level` ENUM('BEGINNER', 'INTERMEDIATE', 'ADVANCED') NOT NULL DEFAULT 'BEGINNER',
  `company_tags` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  INDEX `idx_qna_topic_id` (`topic_id`),
  INDEX `idx_qna_level` (`level`),
  CONSTRAINT `fk_qna_topic` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- QUIZZES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `quizzes` (
  `id` VARCHAR(191) NOT NULL,
  `topic_id` VARCHAR(191) NOT NULL,
  `question` TEXT NOT NULL,
  `options` JSON NOT NULL,
  `correct_answer` VARCHAR(255) NOT NULL,
  `explanation` TEXT NULL,
  `level` ENUM('BEGINNER', 'INTERMEDIATE', 'ADVANCED') NOT NULL DEFAULT 'BEGINNER',
  `company_tags` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  INDEX `idx_quizzes_topic_id` (`topic_id`),
  INDEX `idx_quizzes_level` (`level`),
  CONSTRAINT `fk_quizzes_topic` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PDFS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `pdfs` (
  `id` VARCHAR(191) NOT NULL,
  `topic_id` VARCHAR(191) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `file_url` VARCHAR(500) NOT NULL,
  `file_size` INT NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  INDEX `idx_pdfs_topic_id` (`topic_id`),
  CONSTRAINT `fk_pdfs_topic` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- BOOKMARKS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `bookmarks` (
  `id` VARCHAR(191) NOT NULL,
  `user_id` VARCHAR(191) NOT NULL,
  `qna_id` VARCHAR(191) NULL,
  `pdf_id` VARCHAR(191) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `bookmarks_user_id_qna_id_key` (`user_id`, `qna_id`),
  UNIQUE KEY `bookmarks_user_id_pdf_id_key` (`user_id`, `pdf_id`),
  INDEX `idx_bookmarks_user_id` (`user_id`),
  INDEX `idx_bookmarks_qna_id` (`qna_id`),
  INDEX `idx_bookmarks_pdf_id` (`pdf_id`),
  CONSTRAINT `fk_bookmarks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_bookmarks_qna` FOREIGN KEY (`qna_id`) REFERENCES `qna` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_bookmarks_pdf` FOREIGN KEY (`pdf_id`) REFERENCES `pdfs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PROGRESS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `progress` (
  `id` VARCHAR(191) NOT NULL,
  `user_id` VARCHAR(191) NOT NULL,
  `topic_id` VARCHAR(191) NOT NULL,
  `completion_percent` INT NOT NULL DEFAULT 0,
  `score` DOUBLE NULL,
  `last_accessed_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `progress_user_id_topic_id_key` (`user_id`, `topic_id`),
  INDEX `idx_progress_user_id` (`user_id`),
  INDEX `idx_progress_topic_id` (`topic_id`),
  INDEX `idx_progress_last_accessed` (`last_accessed_at`),
  CONSTRAINT `fk_progress_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_progress_topic` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- QUIZ ATTEMPTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS `quiz_attempts` (
  `id` VARCHAR(191) NOT NULL,
  `user_id` VARCHAR(191) NOT NULL,
  `quiz_id` VARCHAR(191) NOT NULL,
  `selected_answer` VARCHAR(255) NOT NULL,
  `is_correct` BOOLEAN NOT NULL,
  `time_taken` INT NULL COMMENT 'Time in seconds',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  INDEX `idx_quiz_attempts_user_quiz` (`user_id`, `quiz_id`),
  INDEX `idx_quiz_attempts_user_id` (`user_id`),
  INDEX `idx_quiz_attempts_quiz_id` (`quiz_id`),
  INDEX `idx_quiz_attempts_created_at` (`created_at`),
  CONSTRAINT `fk_quiz_attempts_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_quiz_attempts_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- SEED DATA
-- =====================================================

-- Insert Master Admin (Password: Admin123!)
INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `role`, `created_at`, `updated_at`)
VALUES (
  UUID(),
  'Master Admin',
  'admin@example.com',
  '$2y$10$3ctfNp./g4d92WaFA7lWHu/10GkuzZlpuIpqODo4.FysvTQz1QK3O',
  'MASTER_ADMIN',
  NOW(3),
  NOW(3)
) ON DUPLICATE KEY UPDATE `id` = `id`;

-- Insert Sample Product: Interview Prep
INSERT INTO `products` (`id`, `name`, `slug`, `description`, `is_active`, `created_at`, `updated_at`)
VALUES (
  'interview-prep-001',
  'Interview Prep',
  'interview-prep',
  'Prepare for technical interviews with top companies',
  TRUE,
  NOW(3),
  NOW(3)
) ON DUPLICATE KEY UPDATE `name` = 'Interview Prep';

-- Insert Topics
INSERT INTO `topics` (`id`, `product_id`, `name`, `description`, `order`, `created_at`, `updated_at`)
VALUES 
  ('topic-js-001', 'interview-prep-001', 'JavaScript Basics', 'Core JavaScript concepts and fundamentals', 1, NOW(3), NOW(3)),
  ('topic-ds-001', 'interview-prep-001', 'Data Structures', 'Arrays, Linked Lists, Trees, and Graphs', 2, NOW(3), NOW(3)),
  ('topic-algo-001', 'interview-prep-001', 'Algorithms', 'Sorting, Searching, and Dynamic Programming', 3, NOW(3), NOW(3))
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Insert Sample Q&A
INSERT INTO `qna` (`id`, `topic_id`, `question`, `answer`, `level`, `company_tags`, `created_at`, `updated_at`)
VALUES 
  (
    UUID(),
    'topic-js-001',
    'What is hoisting in JavaScript?',
    'Hoisting is JavaScript\'s default behavior of moving declarations to the top of the current scope. Variables declared with var and function declarations are hoisted to the top of their scope before code execution.',
    'INTERMEDIATE',
    JSON_ARRAY('amazon', 'google', 'microsoft'),
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-js-001',
    'Explain the difference between let, const, and var',
    'var is function-scoped and hoisted. let and const are block-scoped and not hoisted. const cannot be reassigned after declaration, while let can be reassigned.',
    'BEGINNER',
    JSON_ARRAY('tcs', 'infosys', 'wipro', 'cognizant'),
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-js-001',
    'What is a closure in JavaScript?',
    'A closure is a function that has access to variables in its outer (enclosing) lexical scope, even after the outer function has returned. Closures allow data privacy and factory functions.',
    'ADVANCED',
    JSON_ARRAY('google', 'amazon', 'facebook', 'netflix'),
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-ds-001',
    'What is the time complexity of binary search?',
    'Binary search has a time complexity of O(log n) as it divides the search space in half with each iteration. This makes it much more efficient than linear search O(n) for sorted arrays.',
    'INTERMEDIATE',
    JSON_ARRAY('amazon', 'microsoft', 'google'),
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-ds-001',
    'Explain the difference between Stack and Queue',
    'Stack follows LIFO (Last In First Out) principle - the last element added is the first to be removed. Queue follows FIFO (First In First Out) principle - the first element added is the first to be removed.',
    'BEGINNER',
    JSON_ARRAY('tcs', 'infosys', 'accenture'),
    NOW(3),
    NOW(3)
  );

-- Insert Sample Quizzes
INSERT INTO `quizzes` (`id`, `topic_id`, `question`, `options`, `correct_answer`, `explanation`, `level`, `company_tags`, `created_at`, `updated_at`)
VALUES 
  (
    UUID(),
    'topic-js-001',
    'Which of the following is NOT a primitive data type in JavaScript?',
    JSON_ARRAY('String', 'Number', 'Array', 'Boolean'),
    'Array',
    'Array is an object type, not a primitive. The primitive types in JavaScript are: string, number, boolean, null, undefined, symbol, and bigint.',
    'BEGINNER',
    JSON_ARRAY('amazon', 'flipkart', 'paytm'),
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-js-001',
    'What will be the output of: console.log(typeof null)?',
    JSON_ARRAY('null', 'undefined', 'object', 'number'),
    'object',
    'This is a known JavaScript quirk. typeof null returns "object" due to a bug in the original JavaScript implementation that was never fixed for backward compatibility.',
    'INTERMEDIATE',
    JSON_ARRAY('google', 'microsoft', 'adobe'),
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-ds-001',
    'Which data structure uses LIFO (Last In First Out)?',
    JSON_ARRAY('Queue', 'Stack', 'Array', 'Tree'),
    'Stack',
    'A stack follows the LIFO principle where the last element added (pushed) is the first one to be removed (popped). Common operations are push, pop, and peek.',
    'BEGINNER',
    JSON_ARRAY('tcs', 'cognizant', 'infosys', 'wipro'),
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-ds-001',
    'What is the average time complexity of searching in a balanced Binary Search Tree?',
    JSON_ARRAY('O(1)', 'O(log n)', 'O(n)', 'O(n log n)'),
    'O(log n)',
    'In a balanced BST, the height is log n, and search operations traverse from root to leaf, resulting in O(log n) time complexity. Worst case for unbalanced BST is O(n).',
    'INTERMEDIATE',
    JSON_ARRAY('amazon', 'google', 'microsoft', 'apple'),
    NOW(3),
    NOW(3)
  );

-- Insert Sample PDFs
INSERT INTO `pdfs` (`id`, `topic_id`, `title`, `description`, `file_url`, `file_size`, `created_at`, `updated_at`)
VALUES 
  (
    UUID(),
    'topic-js-001',
    'JavaScript ES6+ Features Guide',
    'Comprehensive guide covering modern JavaScript features including arrow functions, destructuring, promises, async/await, and more.',
    'https://example.com/js-es6-guide.pdf',
    2048576,
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-js-001',
    'JavaScript Interview Questions - Top 100',
    'Most commonly asked JavaScript interview questions with detailed answers and code examples.',
    'https://example.com/js-top-100.pdf',
    3145728,
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-ds-001',
    'Data Structures Cheat Sheet',
    'Quick reference for common data structures including arrays, linked lists, stacks, queues, trees, and graphs with their operations and complexities.',
    'https://example.com/ds-cheat-sheet.pdf',
    1024000,
    NOW(3),
    NOW(3)
  ),
  (
    UUID(),
    'topic-algo-001',
    'Algorithm Design Patterns',
    'Essential algorithm design patterns and problem-solving techniques for coding interviews.',
    'https://example.com/algo-patterns.pdf',
    4194304,
    NOW(3),
    NOW(3)
  );

-- =====================================================
-- VIEWS FOR ANALYTICS (Optional)
-- =====================================================

CREATE OR REPLACE VIEW `v_user_stats` AS
SELECT 
  u.id AS user_id,
  u.name,
  u.email,
  COUNT(DISTINCT qa.id) AS total_quiz_attempts,
  SUM(CASE WHEN qa.is_correct THEN 1 ELSE 0 END) AS correct_answers,
  ROUND(SUM(CASE WHEN qa.is_correct THEN 1 ELSE 0 END) * 100.0 / COUNT(qa.id), 2) AS accuracy_percentage,
  COUNT(DISTINCT p.topic_id) AS topics_started,
  AVG(p.completion_percent) AS avg_completion,
  COUNT(DISTINCT b.id) AS total_bookmarks
FROM users u
LEFT JOIN quiz_attempts qa ON u.id = qa.user_id
LEFT JOIN progress p ON u.id = p.user_id
LEFT JOIN bookmarks b ON u.id = b.user_id
WHERE u.role = 'USER'
GROUP BY u.id, u.name, u.email;

-- =====================================================
-- STORED PROCEDURES (Optional)
-- =====================================================

DELIMITER //

CREATE PROCEDURE `GetUserProgress`(IN userId VARCHAR(191))
BEGIN
  SELECT 
    p.id,
    t.name AS topic_name,
    pr.name AS product_name,
    p.completion_percent,
    p.score,
    p.last_accessed_at
  FROM progress p
  INNER JOIN topics t ON p.topic_id = t.id
  INNER JOIN products pr ON t.product_id = pr.id
  WHERE p.user_id = userId
  ORDER BY p.last_accessed_at DESC;
END //

CREATE PROCEDURE `GetProductStats`(IN productId VARCHAR(191))
BEGIN
  SELECT 
    COUNT(DISTINCT t.id) AS total_topics,
    COUNT(DISTINCT q.id) AS total_qna,
    COUNT(DISTINCT qz.id) AS total_quizzes,
    COUNT(DISTINCT pd.id) AS total_pdfs,
    COUNT(DISTINCT qa.user_id) AS unique_users
  FROM products p
  LEFT JOIN topics t ON p.id = t.product_id
  LEFT JOIN qna q ON t.id = q.topic_id
  LEFT JOIN quizzes qz ON t.id = qz.topic_id
  LEFT JOIN pdfs pd ON t.id = pd.topic_id
  LEFT JOIN quiz_attempts qa ON qz.id = qa.quiz_id
  WHERE p.id = productId;
END //

DELIMITER ;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Additional composite indexes for common queries
CREATE INDEX idx_qna_topic_level ON qna(topic_id, level);
CREATE INDEX idx_quizzes_topic_level ON quizzes(topic_id, level);
CREATE INDEX idx_quiz_attempts_user_created ON quiz_attempts(user_id, created_at);
CREATE INDEX idx_progress_user_completion ON progress(user_id, completion_percent);

-- =====================================================
-- END OF SCHEMA
-- =====================================================

-- Display success message
SELECT 'Database schema created successfully!' AS message;