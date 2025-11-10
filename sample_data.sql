-- Sample Data SQL Script for QnA PROD API
-- This script inserts sample data into all tables for testing purposes

-- Clear existing data (optional, uncomment if needed)
-- SET FOREIGN_KEY_CHECKS = 0;
-- TRUNCATE TABLE users;
-- TRUNCATE TABLE products;
-- TRUNCATE TABLE topics;
-- TRUNCATE TABLE quiz_groups;
-- TRUNCATE TABLE quizzes;
-- TRUNCATE TABLE qna;
-- TRUNCATE TABLE pdfs;
-- TRUNCATE TABLE user_products;
-- TRUNCATE TABLE bookmarks;
-- TRUNCATE TABLE progress;
-- TRUNCATE TABLE quiz_attempts;
-- SET FOREIGN_KEY_CHECKS = 1;

-- Insert Users
INSERT INTO users (id, name, email, password_hash, role, created_at, updated_at)
VALUES 
  ('user-1-uuid', 'Regular User', 'user@example.com', '$2b$10$6XtEw94eHZYbGGn0.X9aCOBnX9wVzIBvT7vRaJzwJqRMRMoXnPIWW', 'USER', NOW(), NOW()), -- Password: Password123!
  ('admin-1-uuid', 'Admin User', 'admin@example.com', '$2b$10$6XtEw94eHZYbGGn0.X9aCOBnX9wVzIBvT7vRaJzwJqRMRMoXnPIWW', 'ADMIN', NOW(), NOW()), -- Password: Password123!
  ('master-1-uuid', 'Master Admin', 'master@example.com', '$2b$10$6XtEw94eHZYbGGn0.X9aCOBnX9wVzIBvT7vRaJzwJqRMRMoXnPIWW', 'MASTER_ADMIN', NOW(), NOW()); -- Password: Password123!

-- Insert Products
INSERT INTO products (id, name, slug, description, is_active, created_at, updated_at)
VALUES 
  ('product-1-uuid', 'JavaScript Interview Prep', 'javascript-interview-prep', 'Complete JavaScript interview preparation course', TRUE, NOW(), NOW()),
  ('product-2-uuid', 'Data Structures & Algorithms', 'dsa-course', 'Master data structures and algorithms', TRUE, NOW(), NOW()),
  ('product-3-uuid', 'System Design', 'system-design', 'Learn system design principles and patterns', TRUE, NOW(), NOW());

-- Insert Topics
INSERT INTO topics (id, product_id, name, description, `order`, created_at, updated_at)
VALUES 
  -- JavaScript Topics
  ('topic-js-1-uuid', 'product-1-uuid', 'JavaScript Basics', 'Core JavaScript concepts and fundamentals', 1, NOW(), NOW()),
  ('topic-js-2-uuid', 'product-1-uuid', 'ES6+ Features', 'Modern JavaScript features and syntax', 2, NOW(), NOW()),
  ('topic-js-3-uuid', 'product-1-uuid', 'Async JavaScript', 'Promises, async/await, and callbacks', 3, NOW(), NOW()),
  
  -- DSA Topics
  ('topic-dsa-1-uuid', 'product-2-uuid', 'Arrays & Strings', 'Working with arrays and string manipulation', 1, NOW(), NOW()),
  ('topic-dsa-2-uuid', 'product-2-uuid', 'Linked Lists', 'Singly and doubly linked lists', 2, NOW(), NOW()),
  ('topic-dsa-3-uuid', 'product-2-uuid', 'Trees & Graphs', 'Tree and graph data structures', 3, NOW(), NOW()),
  
  -- System Design Topics
  ('topic-sd-1-uuid', 'product-3-uuid', 'Basics of System Design', 'Fundamental concepts in system design', 1, NOW(), NOW()),
  ('topic-sd-2-uuid', 'product-3-uuid', 'Scalability', 'Designing for scale and performance', 2, NOW(), NOW()),
  ('topic-sd-3-uuid', 'product-3-uuid', 'Microservices', 'Microservice architecture patterns', 3, NOW(), NOW());

-- Insert Quiz Groups
INSERT INTO quiz_groups (id, product_id, name, description, `order`, is_active, created_at, updated_at)
VALUES 
  -- JavaScript Quiz Groups
  ('qg-js-basics-uuid', 'product-1-uuid', 'JavaScript Basics Quizzes', 'Test your knowledge of JavaScript fundamentals', 1, TRUE, NOW(), NOW()),
  ('qg-js-advanced-uuid', 'product-1-uuid', 'Advanced JavaScript Quizzes', 'Challenge yourself with advanced JavaScript concepts', 2, TRUE, NOW(), NOW()),
  
  -- DSA Quiz Groups
  ('qg-dsa-arrays-uuid', 'product-2-uuid', 'Arrays & Strings Quizzes', 'Test your knowledge of array and string algorithms', 1, TRUE, NOW(), NOW()),
  ('qg-dsa-complex-uuid', 'product-2-uuid', 'Complex Data Structures Quizzes', 'Quizzes on trees, graphs, and advanced structures', 2, TRUE, NOW(), NOW()),
  
  -- System Design Quiz Groups
  ('qg-sd-basics-uuid', 'product-3-uuid', 'System Design Basics Quizzes', 'Test your understanding of system design fundamentals', 1, TRUE, NOW(), NOW()),
  ('qg-sd-advanced-uuid', 'product-3-uuid', 'Advanced System Design Quizzes', 'Advanced system design patterns and principles', 2, TRUE, NOW(), NOW());

-- Insert Quizzes
INSERT INTO quizzes (id, quiz_group_id, question, options, correct_answer, explanation, level, company_tags, created_at, updated_at)
VALUES 
  -- JavaScript Basics Quizzes
  ('quiz-js-1-uuid', 'qg-js-basics-uuid', 'Which of the following is NOT a primitive data type in JavaScript?', '["String", "Number", "Array", "Boolean"]', 'Array', 'Array is an object type, not a primitive. The primitive types are: string, number, boolean, null, undefined, symbol, and bigint.', 'BEGINNER', '["Amazon", "Google"]', NOW(), NOW()),
  ('quiz-js-2-uuid', 'qg-js-basics-uuid', 'What will be the output of: console.log(typeof null)?', '["null", "undefined", "object", "number"]', 'object', 'This is a known JavaScript quirk. typeof null returns "object" due to a bug in the original JavaScript implementation.', 'INTERMEDIATE', '["Microsoft", "Facebook"]', NOW(), NOW()),
  ('quiz-js-3-uuid', 'qg-js-basics-uuid', 'Which method is used to add an element to the end of an array?', '["push()", "pop()", "shift()", "unshift()"]', 'push()', 'The push() method adds one or more elements to the end of an array and returns the new length of the array.', 'BEGINNER', '["Amazon", "TCS"]', NOW(), NOW()),
  
  -- Advanced JavaScript Quizzes
  ('quiz-js-4-uuid', 'qg-js-advanced-uuid', 'What is the output of: console.log(0.1 + 0.2 === 0.3)?', '["true", "false", "undefined", "error"]', 'false', 'Due to floating-point precision issues in JavaScript, 0.1 + 0.2 actually equals 0.30000000000000004, not exactly 0.3.', 'INTERMEDIATE', '["Google", "Microsoft"]', NOW(), NOW()),
  ('quiz-js-5-uuid', 'qg-js-advanced-uuid', 'Which of the following is NOT a feature introduced in ES6?', '["let/const", "Promises", "async/await", "Arrow functions"]', 'async/await', 'async/await was introduced in ES2017 (ES8), not ES6 (ES2015).', 'INTERMEDIATE', '["Amazon", "Facebook"]', NOW(), NOW()),
  
  -- DSA Quizzes
  ('quiz-dsa-1-uuid', 'qg-dsa-arrays-uuid', 'What is the time complexity of binary search?', '["O(1)", "O(n)", "O(log n)", "O(n log n)"]', 'O(log n)', 'Binary search divides the search space in half with each iteration, resulting in a logarithmic time complexity.', 'BEGINNER', '["Google", "Microsoft"]', NOW(), NOW()),
  ('quiz-dsa-2-uuid', 'qg-dsa-arrays-uuid', 'Which data structure uses LIFO (Last In First Out)?', '["Queue", "Stack", "Array", "Tree"]', 'Stack', 'A stack follows LIFO principle where the last element added is the first one to be removed.', 'BEGINNER', '["Amazon", "TCS"]', NOW(), NOW()),
  ('quiz-dsa-3-uuid', 'qg-dsa-complex-uuid', 'Which traversal visits the root node first, then the left subtree, then the right subtree?', '["Inorder", "Preorder", "Postorder", "Level order"]', 'Preorder', 'Preorder traversal follows Root-Left-Right pattern.', 'INTERMEDIATE', '["Google", "Microsoft"]', NOW(), NOW()),
  
  -- System Design Quizzes
  ('quiz-sd-1-uuid', 'qg-sd-basics-uuid', 'Which of the following is NOT a CAP theorem component?', '["Consistency", "Availability", "Partition Tolerance", "Scalability"]', 'Scalability', 'The CAP theorem states that a distributed system can only provide two of three guarantees: Consistency, Availability, and Partition Tolerance. Scalability is not part of the CAP theorem.', 'INTERMEDIATE', '["Amazon", "Microsoft"]', NOW(), NOW()),
  ('quiz-sd-2-uuid', 'qg-sd-advanced-uuid', 'Which pattern is used to handle high traffic by placing a component between the client and the server?', '["Singleton", "Factory", "Proxy", "Observer"]', 'Proxy', 'The Proxy pattern is commonly used in system design to create a layer between clients and servers, often for load balancing or caching.', 'ADVANCED', '["Google", "Facebook"]', NOW(), NOW());

-- Insert Q&A
INSERT INTO qna (id, topic_id, question, answer, example_code, level, company_tags, created_at, updated_at)
VALUES 
  -- JavaScript Basics Q&A
  ('qna-js-1-uuid', 'topic-js-1-uuid', 'What is hoisting in JavaScript?', 'Hoisting is JavaScript\'s default behavior of moving declarations to the top of the current scope. Variables declared with var and function declarations are hoisted.', 'console.log(x); // undefined\nvar x = 5;\n\n// The above code behaves as:\nvar x;\nconsole.log(x); // undefined\nx = 5;', 'BEGINNER', '["Amazon", "Google"]', NOW(), NOW()),
  ('qna-js-2-uuid', 'topic-js-1-uuid', 'Explain the difference between let, const, and var', 'var is function-scoped and hoisted. let and const are block-scoped. const cannot be reassigned after declaration, while let can be.', 'var x = 1;\nlet y = 2;\nconst z = 3;\n\n// var can be redeclared\nvar x = 4; // Valid\n\n// let cannot be redeclared in the same scope\n// let y = 5; // SyntaxError\n\n// const cannot be reassigned\n// z = 6; // TypeError', 'BEGINNER', '["Microsoft", "TCS"]', NOW(), NOW()),
  
  -- ES6+ Features Q&A
  ('qna-js-3-uuid', 'topic-js-2-uuid', 'What are arrow functions and how do they differ from regular functions?', 'Arrow functions are a concise syntax for writing functions in JavaScript. They don\'t have their own this, arguments, super, or new.target bindings. They cannot be used as constructors and are always anonymous.', 'const regularFunc = function(a, b) {\n  return a + b;\n};\n\nconst arrowFunc = (a, b) => a + b;\n\n// this binding difference\nconst obj = {\n  value: 42,\n  regularMethod: function() {\n    console.log(this.value); // 42\n  },\n  arrowMethod: () => {\n    console.log(this.value); // undefined\n  }\n};', 'INTERMEDIATE', '["Amazon", "Facebook"]', NOW(), NOW()),
  
  -- DSA Q&A
  ('qna-dsa-1-uuid', 'topic-dsa-1-uuid', 'What is the time complexity of searching an element in a sorted array using binary search?', 'The time complexity of binary search is O(log n) because the algorithm divides the search space in half with each iteration.', 'function binarySearch(arr, target) {\n  let left = 0;\n  let right = arr.length - 1;\n  \n  while (left <= right) {\n    const mid = Math.floor((left + right) / 2);\n    \n    if (arr[mid] === target) {\n      return mid;\n    } else if (arr[mid] < target) {\n      left = mid + 1;\n    } else {\n      right = mid - 1;\n    }\n  }\n  \n  return -1;\n}', 'BEGINNER', '["Google", "Microsoft"]', NOW(), NOW()),
  ('qna-dsa-2-uuid', 'topic-dsa-2-uuid', 'What is a linked list and what are its advantages over arrays?', 'A linked list is a linear data structure where elements are stored in nodes, and each node points to the next node in the sequence. Advantages over arrays include dynamic size, efficient insertions/deletions at any position, and no need for contiguous memory allocation.', 'class Node {\n  constructor(data) {\n    this.data = data;\n    this.next = null;\n  }\n}\n\nclass LinkedList {\n  constructor() {\n    this.head = null;\n  }\n  \n  append(data) {\n    const newNode = new Node(data);\n    \n    if (!this.head) {\n      this.head = newNode;\n      return;\n    }\n    \n    let current = this.head;\n    while (current.next) {\n      current = current.next;\n    }\n    \n    current.next = newNode;\n  }\n}', 'INTERMEDIATE', '["Amazon", "Microsoft"]', NOW(), NOW()),
  
  -- System Design Q&A
  ('qna-sd-1-uuid', 'topic-sd-1-uuid', 'What is the CAP theorem?', 'The CAP theorem states that a distributed system can only provide two of three guarantees simultaneously: Consistency (all nodes see the same data at the same time), Availability (every request receives a response), and Partition tolerance (the system continues to operate despite network partitions).', NULL, 'INTERMEDIATE', '["Amazon", "Google"]', NOW(), NOW()),
  ('qna-sd-2-uuid', 'topic-sd-2-uuid', 'Explain horizontal vs. vertical scaling', 'Horizontal scaling (scaling out) means adding more machines to your resource pool, distributing the load across multiple servers. Vertical scaling (scaling up) means adding more power (CPU, RAM) to an existing machine. Horizontal scaling is typically more resilient but may introduce complexity with data consistency, while vertical scaling is simpler but has hardware limits.', NULL, 'BEGINNER', '["Microsoft", "Facebook"]', NOW(), NOW());

-- Insert PDFs
INSERT INTO pdfs (id, topic_id, title, description, file_url, file_size, created_at, updated_at)
VALUES 
  ('pdf-js-1-uuid', 'topic-js-1-uuid', 'JavaScript Fundamentals Cheat Sheet', 'Quick reference for JavaScript basics and syntax', 'https://example.com/js-fundamentals.pdf', 1024000, NOW(), NOW()),
  ('pdf-js-2-uuid', 'topic-js-2-uuid', 'ES6+ Features Guide', 'Comprehensive guide to modern JavaScript features', 'https://example.com/es6-guide.pdf', 2048000, NOW(), NOW()),
  ('pdf-dsa-1-uuid', 'topic-dsa-1-uuid', 'Data Structures Cheat Sheet', 'Quick reference for common data structures', 'https://example.com/data-structures.pdf', 1536000, NOW(), NOW()),
  ('pdf-sd-1-uuid', 'topic-sd-1-uuid', 'System Design Interview Guide', 'Preparation guide for system design interviews', 'https://example.com/system-design-guide.pdf', 3072000, NOW(), NOW());

-- Grant product access to users
INSERT INTO user_products (user_id, product_id, created_at)
VALUES 
  ('user-1-uuid', 'product-1-uuid', NOW()),
  ('user-1-uuid', 'product-2-uuid', NOW()),
  ('admin-1-uuid', 'product-1-uuid', NOW()),
  ('admin-1-uuid', 'product-2-uuid', NOW()),
  ('admin-1-uuid', 'product-3-uuid', NOW());

-- Insert bookmarks
INSERT INTO bookmarks (id, user_id, qna_id, pdf_id, created_at)
VALUES 
  ('bookmark-1-uuid', 'user-1-uuid', 'qna-js-1-uuid', NULL, NOW()),
  ('bookmark-2-uuid', 'user-1-uuid', NULL, 'pdf-js-1-uuid', NOW()),
  ('bookmark-3-uuid', 'admin-1-uuid', 'qna-dsa-1-uuid', NULL, NOW());

-- Insert progress records
INSERT INTO progress (id, user_id, topic_id, completion_percent, score, last_accessed_at, created_at, updated_at)
VALUES 
  ('progress-1-uuid', 'user-1-uuid', 'topic-js-1-uuid', 75, 85.5, NOW(), NOW(), NOW()),
  ('progress-2-uuid', 'user-1-uuid', 'topic-js-2-uuid', 50, 70.0, NOW(), NOW(), NOW()),
  ('progress-3-uuid', 'user-1-uuid', 'topic-dsa-1-uuid', 30, 65.0, NOW(), NOW(), NOW()),
  ('progress-4-uuid', 'admin-1-uuid', 'topic-js-1-uuid', 100, 95.0, NOW(), NOW(), NOW());

-- Insert quiz attempts
INSERT INTO quiz_attempts (id, user_id, quiz_id, selected_answer, is_correct, time_taken, created_at)
VALUES 
  ('attempt-1-uuid', 'user-1-uuid', 'quiz-js-1-uuid', 'Array', TRUE, 15, NOW()),
  ('attempt-2-uuid', 'user-1-uuid', 'quiz-js-2-uuid', 'object', TRUE, 20, NOW()),
  ('attempt-3-uuid', 'user-1-uuid', 'quiz-js-3-uuid', 'shift()', FALSE, 10, NOW()),
  ('attempt-4-uuid', 'user-1-uuid', 'quiz-dsa-1-uuid', 'O(log n)', TRUE, 25, NOW()),
  ('attempt-5-uuid', 'admin-1-uuid', 'quiz-js-1-uuid', 'Array', TRUE, 8, NOW()),
  ('attempt-6-uuid', 'admin-1-uuid', 'quiz-sd-1-uuid', 'Scalability', TRUE, 18, NOW());

-- Insert refresh tokens (optional)
-- INSERT INTO refresh_tokens (id, token, user_id, expires_at, created_at)
-- VALUES 
--   ('token-1-uuid', 'sample-refresh-token-1', 'user-1-uuid', DATE_ADD(NOW(), INTERVAL 30 DAY), NOW()),
--   ('token-2-uuid', 'sample-refresh-token-2', 'admin-1-uuid', DATE_ADD(NOW(), INTERVAL 30 DAY), NOW());

-- Insert password reset tokens (optional)
-- INSERT INTO password_reset_tokens (id, token, user_id, expires_at, created_at)
-- VALUES 
--   ('reset-1-uuid', 'sample-reset-token-1', 'user-1-uuid', DATE_ADD(NOW(), INTERVAL 1 DAY), NOW());
