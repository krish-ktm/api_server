-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Nov 06, 2025 at 06:51 AM
-- Server version: 11.8.3-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u286264826_QndAProd`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`u286264826_ROOTQndAProd`@`127.0.0.1` PROCEDURE `GetProductStats` (IN `productId` VARCHAR(191))   BEGIN
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
END$$

CREATE DEFINER=`u286264826_ROOTQndAProd`@`127.0.0.1` PROCEDURE `GetUserProgress` (IN `userId` VARCHAR(191))   BEGIN
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
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bookmarks`
--

CREATE TABLE `bookmarks` (
  `id` varchar(191) NOT NULL,
  `user_id` varchar(191) NOT NULL,
  `qna_id` varchar(191) DEFAULT NULL,
  `pdf_id` varchar(191) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bookmarks`
--

INSERT INTO `bookmarks` (`id`, `user_id`, `qna_id`, `pdf_id`, `created_at`) VALUES
('f9246a84-eb7b-4dd0-8e62-577bec0cf9b2', 'b58b1020-6b47-4ef2-9b87-2e5252544e56', 'b7487516-8572-4c80-be1c-f685e0459c60', NULL, '2025-10-17 06:17:49.635');

-- --------------------------------------------------------

--
-- Table structure for table `pdfs`
--

CREATE TABLE `pdfs` (
  `id` varchar(191) NOT NULL,
  `topic_id` varchar(191) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` text DEFAULT NULL,
  `file_url` varchar(191) NOT NULL,
  `file_size` int(11) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updated_at` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pdfs`
--

INSERT INTO `pdfs` (`id`, `topic_id`, `title`, `description`, `file_url`, `file_size`, `created_at`, `updated_at`) VALUES
('8eb72da2-a93d-11f0-9137-271803c7df05', 'topic-js-001', 'JavaScript ES6+ Features Guide', 'Comprehensive guide covering modern JavaScript features including arrow functions, destructuring, promises, async/await, and more.', 'https://example.com/js-es6-guide.pdf', 2048576, '2025-10-14 20:37:10.095', '2025-10-14 20:37:10.095'),
('8eb72efb-a93d-11f0-9137-271803c7df05', 'topic-js-001', 'JavaScript Interview Questions - Top 100', 'Most commonly asked JavaScript interview questions with detailed answers and code examples.', 'https://example.com/js-top-100.pdf', 3145728, '2025-10-14 20:37:10.095', '2025-10-14 20:37:10.095'),
('8eb72fa7-a93d-11f0-9137-271803c7df05', 'topic-ds-001', 'Data Structures Cheat Sheet', 'Quick reference for common data structures including arrays, linked lists, stacks, queues, trees, and graphs with their operations and complexities.', 'https://example.com/ds-cheat-sheet.pdf', 1024000, '2025-10-14 20:37:10.095', '2025-10-14 20:37:10.095'),
('8eb73013-a93d-11f0-9137-271803c7df05', 'topic-algo-001', 'Algorithm Design Patterns', 'Essential algorithm design patterns and problem-solving techniques for coding interviews.', 'https://example.com/algo-patterns.pdf', 4194304, '2025-10-14 20:37:10.095', '2025-10-14 20:37:10.095');

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` varchar(191) NOT NULL,
  `name` varchar(191) NOT NULL,
  `slug` varchar(191) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updated_at` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `name`, `slug`, `description`, `is_active`, `created_at`, `updated_at`) VALUES
('a3ae5c77-a960-11f0-9137-271803c7df05', 'Interview Prep', 'interview-prep', 'Prepare for technical interviews with top companies', 1, '2025-10-14 20:37:10.082', '2025-10-15 00:48:31.038'),
('e52d0b1d-fb85-4710-b3ce-3120221bba0c', 'DSA Testing', 'DSA-prep', NULL, 1, '2025-10-16 05:14:12.789', '2025-10-16 05:14:12.789');

-- --------------------------------------------------------

--
-- Table structure for table `progress`
--

CREATE TABLE `progress` (
  `id` varchar(191) NOT NULL,
  `user_id` varchar(191) NOT NULL,
  `topic_id` varchar(191) NOT NULL,
  `completion_percent` int(11) NOT NULL DEFAULT 0,
  `score` double DEFAULT NULL,
  `last_accessed_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updated_at` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `progress`
--

INSERT INTO `progress` (`id`, `user_id`, `topic_id`, `completion_percent`, `score`, `last_accessed_at`, `created_at`, `updated_at`) VALUES
('bedc09d4-3fc5-47d9-bf6d-b56bce2f02da', 'b58b1020-6b47-4ef2-9b87-2e5252544e56', 'topic-js-001', 75, 85.5, '2025-10-17 06:16:43.489', '2025-10-17 06:16:43.489', '2025-10-17 06:16:43.489');

-- --------------------------------------------------------

--
-- Table structure for table `qna`
--

CREATE TABLE `qna` (
  `id` varchar(191) NOT NULL,
  `topic_id` varchar(191) NOT NULL,
  `question` text NOT NULL,
  `answer` text NOT NULL,
  `level` enum('BEGINNER','INTERMEDIATE','ADVANCED') NOT NULL DEFAULT 'BEGINNER',
  `company_tags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`company_tags`)),
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updated_at` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `qna`
--

INSERT INTO `qna` (`id`, `topic_id`, `question`, `answer`, `level`, `company_tags`, `created_at`, `updated_at`) VALUES
('8eb641c6-a93d-11f0-9137-271803c7df05', 'topic-js-001', 'What is hoisting in JavaScript?', 'Hoisting is JavaScript\'s default behavior of moving declarations to the top of the current scope. Variables declared with var and function declarations are hoisted to the top of their scope before code execution.', 'INTERMEDIATE', '[\"amazon\", \"google\", \"microsoft\"]', '2025-10-14 20:37:10.089', '2025-10-14 20:37:10.089'),
('8eb643df-a93d-11f0-9137-271803c7df05', 'topic-js-001', 'Explain the difference between let, const, and var', 'var is function-scoped and hoisted. let and const are block-scoped and not hoisted. const cannot be reassigned after declaration, while let can be reassigned.', 'BEGINNER', '[\"tcs\", \"infosys\", \"wipro\", \"cognizant\"]', '2025-10-14 20:37:10.089', '2025-10-14 20:37:10.089'),
('8eb6449c-a93d-11f0-9137-271803c7df05', 'topic-js-001', 'What is a closure in JavaScript?', 'A closure is a function that has access to variables in its outer (enclosing) lexical scope, even after the outer function has returned. Closures allow data privacy and factory functions.', 'ADVANCED', '[\"google\", \"amazon\", \"facebook\", \"netflix\"]', '2025-10-14 20:37:10.089', '2025-10-14 20:37:10.089'),
('8eb644f8-a93d-11f0-9137-271803c7df05', 'topic-ds-001', 'What is the time complexity of binary search?', 'Binary search has a time complexity of O(log n) as it divides the search space in half with each iteration. This makes it much more efficient than linear search O(n) for sorted arrays.', 'INTERMEDIATE', '[\"amazon\", \"microsoft\", \"google\"]', '2025-10-14 20:37:10.089', '2025-10-14 20:37:10.089'),
('8eb64540-a93d-11f0-9137-271803c7df05', 'topic-ds-001', 'Explain the difference between Stack and Queue', 'Stack follows LIFO (Last In First Out) principle - the last element added is the first to be removed. Queue follows FIFO (First In First Out) principle - the first element added is the first to be removed.', 'BEGINNER', '[\"tcs\", \"infosys\", \"accenture\"]', '2025-10-14 20:37:10.089', '2025-10-14 20:37:10.089'),
('b7487516-8572-4c80-be1c-f685e0459c60', '92df6afd-5411-4fbd-8234-ed095d4c2a2e', 'What is a linked list?', 'Updated answer with more details', 'ADVANCED', '[\"Amazon\",\"Google\"]', '2025-10-16 08:11:10.791', '2025-10-16 08:13:12.191'),
('d6bebea2-5ce8-4f48-bd9c-9392fd6fa967', '92df6afd-5411-4fbd-8234-ed095d4c2a2e', 'What is a hash table?', 'Updated answer with more details', 'ADVANCED', '[\"Facebook\",\"Microsoft\"]', '2025-10-16 08:11:10.791', '2025-10-16 08:13:12.191');

-- --------------------------------------------------------

--
-- Table structure for table `quizzes`
--

CREATE TABLE `quizzes` (
  `id` varchar(191) NOT NULL,
  `topic_id` varchar(191) NOT NULL,
  `question` text NOT NULL,
  `options` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`options`)),
  `correct_answer` varchar(191) NOT NULL,
  `explanation` text DEFAULT NULL,
  `level` enum('BEGINNER','INTERMEDIATE','ADVANCED') NOT NULL DEFAULT 'BEGINNER',
  `company_tags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`company_tags`)),
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updated_at` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `quizzes`
--

INSERT INTO `quizzes` (`id`, `topic_id`, `question`, `options`, `correct_answer`, `explanation`, `level`, `company_tags`, `created_at`, `updated_at`) VALUES
('8eb6c097-a93d-11f0-9137-271803c7df05', 'topic-js-001', 'Which of the following is NOT a primitive data type in JavaScript?', '[\"String\", \"Number\", \"Array\", \"Boolean\"]', 'Array', 'Array is an object type, not a primitive. The primitive types in JavaScript are: string, number, boolean, null, undefined, symbol, and bigint.', 'BEGINNER', '[\"amazon\", \"flipkart\", \"paytm\"]', '2025-10-14 20:37:10.092', '2025-10-14 20:37:10.092'),
('8eb6c23b-a93d-11f0-9137-271803c7df05', 'topic-js-001', 'What will be the output of: console.log(typeof null)?', '[\"null\", \"undefined\", \"object\", \"number\"]', 'object', 'This is a known JavaScript quirk. typeof null returns \"object\" due to a bug in the original JavaScript implementation that was never fixed for backward compatibility.', 'INTERMEDIATE', '[\"google\", \"microsoft\", \"adobe\"]', '2025-10-14 20:37:10.092', '2025-10-14 20:37:10.092'),
('8eb6c30d-a93d-11f0-9137-271803c7df05', 'topic-ds-001', 'Which data structure uses LIFO (Last In First Out)?', '[\"Queue\", \"Stack\", \"Array\", \"Tree\"]', 'Stack', 'A stack follows the LIFO principle where the last element added (pushed) is the first one to be removed (popped). Common operations are push, pop, and peek.', 'BEGINNER', '[\"tcs\", \"cognizant\", \"infosys\", \"wipro\"]', '2025-10-14 20:37:10.092', '2025-10-14 20:37:10.092'),
('8eb6c374-a93d-11f0-9137-271803c7df05', 'topic-ds-001', 'What is the average time complexity of searching in a balanced Binary Search Tree?', '[\"O(1)\", \"O(log n)\", \"O(n)\", \"O(n log n)\"]', 'O(log n)', 'In a balanced BST, the height is log n, and search operations traverse from root to leaf, resulting in O(log n) time complexity. Worst case for unbalanced BST is O(n).', 'INTERMEDIATE', '[\"amazon\", \"google\", \"microsoft\", \"apple\"]', '2025-10-14 20:37:10.092', '2025-10-14 20:37:10.092');

-- --------------------------------------------------------

--
-- Table structure for table `quiz_attempts`
--

CREATE TABLE `quiz_attempts` (
  `id` varchar(191) NOT NULL,
  `user_id` varchar(191) NOT NULL,
  `quiz_id` varchar(191) NOT NULL,
  `selected_answer` varchar(191) NOT NULL,
  `is_correct` tinyint(1) NOT NULL,
  `time_taken` int(11) DEFAULT NULL COMMENT 'Time in seconds',
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `quiz_attempts`
--

INSERT INTO `quiz_attempts` (`id`, `user_id`, `quiz_id`, `selected_answer`, `is_correct`, `time_taken`, `created_at`) VALUES
('0d172f66-a313-4948-b4ec-6a218f73ef66', '8eb4a733-a93d-11f0-9137-271803c7df05', '8eb6c30d-a93d-11f0-9137-271803c7df05', 'Stack', 1, 30, '2025-10-16 05:30:05.925'),
('6848db22-d47c-4230-9a7c-fa09622454bd', '8eb4a733-a93d-11f0-9137-271803c7df05', '8eb6c30d-a93d-11f0-9137-271803c7df05', 'Array', 0, 30, '2025-10-16 05:30:13.169'),
('8bf8444f-e9cd-4480-9359-432a7bd2897a', '8eb4a733-a93d-11f0-9137-271803c7df05', '8eb6c30d-a93d-11f0-9137-271803c7df05', 'Array', 0, 30, '2025-10-16 05:29:41.969');

-- --------------------------------------------------------

--
-- Table structure for table `refresh_tokens`
--

CREATE TABLE `refresh_tokens` (
  `id` varchar(191) NOT NULL,
  `token` varchar(191) NOT NULL,
  `user_id` varchar(191) NOT NULL,
  `expires_at` datetime(3) NOT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `refresh_tokens`
--

INSERT INTO `refresh_tokens` (`id`, `token`, `user_id`, `expires_at`, `created_at`) VALUES
('0e16e0a9-7d97-46f2-99be-eab30b5fea8a', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJiNThiMTAyMC02YjQ3LTRlZjItOWI4Ny0yZTUyNTI1NDRlNTYiLCJpYXQiOjE3NjA2ODYyMzAsImV4cCI6MTc2MTI5MTAzMH0.JxQlZf4OSqRiu9QSnx-ZRcREM7iDdkis2gD148SWu4', 'b58b1020-6b47-4ef2-9b87-2e5252544e56', '2025-10-24 07:30:30.854', '2025-10-17 07:30:30.855'),
('30c7a071-64e8-4799-9771-8a07cdf9e96a', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjEzNDU4OTcsImV4cCI6MTc2MTk1MDY5N30.69GD8R7os5L7l0MUNy9TVXi9RjNMVcBmzwC4CK7i4T', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-31 22:44:57.551', '2025-10-24 22:44:57.553'),
('3c83122b-d887-4395-b6f4-7bd82cb7c42d', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJiNThiMTAyMC02YjQ3LTRlZjItOWI4Ny0yZTUyNTI1NDRlNTYiLCJpYXQiOjE3NjA2ODE3NDEsImV4cCI6MTc2MTI4NjU0MX0.rHRCPNtMoANZ_Rq6_qpCuRDDVgoYAJJ0F3h0VobAkw', 'b58b1020-6b47-4ef2-9b87-2e5252544e56', '2025-10-24 06:15:41.579', '2025-10-17 06:15:41.580'),
('3ea8675b-0a13-449d-b8d5-8521ec4d2447', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA0ODkwNjEsImV4cCI6MTc2MTA5Mzg2MX0.tFSdIJ1U8kbSlpTLGZb4Mtjbczs8VlGEDrmL750KUT', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-22 00:44:21.739', '2025-10-15 00:44:21.741'),
('3f0183d8-de7b-4228-8699-fd46306df9d4', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA0ODM1MjYsImV4cCI6MTc2MTA4ODMyNn0.hJOkntUJMLwtgePoaIBR1sYmgEaIESqiG--SvulyUF', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-21 23:12:06.325', '2025-10-14 23:12:06.327'),
('4fdc8b2c-ea57-41ec-aceb-805c08481450', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA2MDAzNzAsImV4cCI6MTc2MTIwNTE3MH0.t-bkXGq8I9elnLtaT-L82BeV32eNJhfjQTnS-wnOFw', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-23 07:39:30.486', '2025-10-16 07:39:30.487'),
('64eb671c-a655-40f2-b98b-e9e7b97fb44a', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA2MDAzNTAsImV4cCI6MTc2MTIwNTE1MH0.JANllYJw-m4NPCdEKULSzFVb-enhKKFo4KJbtvuSuB', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-23 07:39:10.361', '2025-10-16 07:39:10.363'),
('6ed1d29f-cd1d-4a15-b4ef-5a9d06ff2030', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA0ODczMTcsImV4cCI6MTc2MTA5MjExN30.eJdBoUI9cloU5GCxRu_xf7ugR1yO_5-vfgH4K2G-PW', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-22 00:15:17.092', '2025-10-15 00:15:17.102'),
('715d72d4-083e-473d-be4b-f0496e7d0753', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA1Nzc0NDAsImV4cCI6MTc2MTE4MjI0MH0.o0dash7GJYR1irg4AlyaWm9tszJOj3qlJ2YpFOp5M4', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-23 01:17:20.907', '2025-10-16 01:17:20.913'),
('7902a317-45e9-4fde-81df-bdd7a67d4d7f', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJiNThiMTAyMC02YjQ3LTRlZjItOWI4Ny0yZTUyNTI1NDRlNTYiLCJpYXQiOjE3NjA2ODY0NTksImV4cCI6MTc2MTI5MTI1OX0.MCREzgrlrbBXtckGy4wjteS_8mI51GwLRc6Z_vaTuN', 'b58b1020-6b47-4ef2-9b87-2e5252544e56', '2025-10-24 07:34:19.135', '2025-10-17 07:34:19.137'),
('812e0002-ad1c-4782-b7b1-0c26c789b61a', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA2ODIxNzAsImV4cCI6MTc2MTI4Njk3MH0.bsF38FlL4O3pQ3ZWTg06HPU7i82Rx0zXnSAss5yp7o', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-24 06:22:50.679', '2025-10-17 06:22:50.681'),
('87a0fbb8-b776-4594-9a4f-0775f0d5cc3d', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA2ODY1MzMsImV4cCI6MTc2MTI5MTMzM30.g5qJkXClRqTYFufh_yOm0oIhn1L_TedFkR4ScmTC2Q', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-24 07:35:33.900', '2025-10-17 07:35:33.902'),
('8a0468d0-31b8-4ee5-9e99-7cb1cbb761f2', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA0ODc4NzEsImV4cCI6MTc2MTA5MjY3MX0.cNlcTmcHJoQWSg3dJm9WEK5tQN3vv-Mln-O3DxI-uZ', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-22 00:24:31.788', '2025-10-15 00:24:31.790'),
('9c5f6045-2b95-4d9c-8efc-129fdbea14b9', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA0NzQ2NzQsImV4cCI6MTc2MTA3OTQ3NH0.u-OTUUOXDD1pmTnwVTK4RDxy4aSyVyz2kiNzWmeUiS', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-21 20:44:34.316', '2025-10-14 20:44:34.318'),
('b371c005-9801-482e-8fee-be6cdad89b72', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjEzNDU0NzAsImV4cCI6MTc2MTk1MDI3MH0.hgtRFaBUQd2q4aJH3QnCUgt-qEURbewNlmT8Grlctc', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-31 22:37:50.681', '2025-10-24 22:37:50.682'),
('b3feec9b-7715-4499-a49a-c32fecac1c9c', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA0ODYyNTAsImV4cCI6MTc2MTA5MTA1MH0.G4nV0aT-ImJ3cVSLyrmDu_E08IXaBJCG28uh2zfwrb', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-21 23:57:30.742', '2025-10-14 23:57:30.748'),
('d5b15713-2946-4a90-bc34-31e27354e890', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA0ODM3NzIsImV4cCI6MTc2MTA4ODU3Mn0.YzTstrZtqQEF5rTibaUOdoMPBEHJG0VPMfzUDBUorn', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-21 23:16:12.605', '2025-10-14 23:16:12.606'),
('eb5260ee-6369-47bf-ba35-cbe93147b21a', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJiNThiMTAyMC02YjQ3LTRlZjItOWI4Ny0yZTUyNTI1NDRlNTYiLCJpYXQiOjE3NjA2ODU4ODYsImV4cCI6MTc2MTI5MDY4Nn0.waKkf5PjNoOVH35IS6oC3Lej57WVrWHoq56gb53ioz', 'b58b1020-6b47-4ef2-9b87-2e5252544e56', '2025-10-24 07:24:46.593', '2025-10-17 07:24:46.594'),
('ecd3496d-3855-4ac9-b9e7-92ad545d9777', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA2ODIwNjgsImV4cCI6MTc2MTI4Njg2OH0.hv-Dwjd37jAqcjtlBsj35hB0bnOlY9hHwZnPm-JGzt', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-24 06:21:08.809', '2025-10-17 06:21:08.811'),
('f6a6ea1e-847d-463b-a095-17346f229905', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZWI0YTczMy1hOTNkLTExZjAtOTEzNy0yNzE4MDNjN2RmMDUiLCJpYXQiOjE3NjA1OTE1NzgsImV4cCI6MTc2MTE5NjM3OH0.3XVcDBWtm87Dg6CpOlB0aDYVAzPzEG9P8X7REag1nW', '8eb4a733-a93d-11f0-9137-271803c7df05', '2025-10-23 05:12:58.432', '2025-10-16 05:12:58.440');

-- --------------------------------------------------------

--
-- Table structure for table `topics`
--

CREATE TABLE `topics` (
  `id` varchar(191) NOT NULL,
  `product_id` varchar(191) NOT NULL,
  `name` varchar(191) NOT NULL,
  `description` text DEFAULT NULL,
  `order` int(11) NOT NULL DEFAULT 0,
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updated_at` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `topics`
--

INSERT INTO `topics` (`id`, `product_id`, `name`, `description`, `order`, `created_at`, `updated_at`) VALUES
('3f8f1942-0256-4107-b805-1a8d9ada4a2b', 'e52d0b1d-fb85-4710-b3ce-3120221bba0c', 'Data Structures', 'Learn about arrays, linked lists, trees, and graphs', 1, '2025-10-16 05:18:35.228', '2025-10-16 05:18:35.228'),
('92df6afd-5411-4fbd-8234-ed095d4c2a2e', 'a3ae5c77-a960-11f0-9137-271803c7df05', 'Data Structures', 'Learn about arrays, linked lists, trees, and graphs', 1, '2025-10-16 08:10:56.625', '2025-10-16 08:10:56.625'),
('topic-algo-001', 'a3ae5c77-a960-11f0-9137-271803c7df05', 'Algorithms', 'Sorting, Searching, and Dynamic Programming', 3, '2025-10-14 20:37:10.086', '2025-10-14 20:37:10.086'),
('topic-ds-001', 'a3ae5c77-a960-11f0-9137-271803c7df05', 'Data Structures', 'Arrays, Linked Lists, Trees, and Graphs', 2, '2025-10-14 20:37:10.086', '2025-10-14 20:37:10.086'),
('topic-js-001', 'a3ae5c77-a960-11f0-9137-271803c7df05', 'JavaScript Basics', 'Core JavaScript concepts and fundamentals', 1, '2025-10-14 20:37:10.086', '2025-10-14 20:37:10.086');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` varchar(191) NOT NULL,
  `name` varchar(191) NOT NULL,
  `email` varchar(191) NOT NULL,
  `password_hash` varchar(191) NOT NULL,
  `role` enum('USER','ADMIN','MASTER_ADMIN') NOT NULL DEFAULT 'USER',
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updated_at` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `role`, `created_at`, `updated_at`) VALUES
('8eb4a733-a93d-11f0-9137-271803c7df05', 'Master Admin', 'admin@example.com', '$2a$12$7NrkE69WgSe4uvBYKu2j9uaBEwJXy3TqXj0w0EzkpdcIE2sIUvOGO', 'MASTER_ADMIN', '2025-10-14 20:37:10.078', '2025-10-14 20:44:26.654'),
('b58b1020-6b47-4ef2-9b87-2e5252544e56', 'Test User', 'testuser@example.com', '$2b$10$apDROg0xtm8DiGElNf83t.ImORX76ZRCt62Fi8HMcpB73.tJgzrpy', 'USER', '2025-10-14 22:42:13.385', '2025-10-17 06:15:11.406');

-- --------------------------------------------------------

--
-- Table structure for table `user_products`
--

CREATE TABLE `user_products` (
  `user_id` varchar(191) NOT NULL,
  `product_id` varchar(191) NOT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_products`
--

INSERT INTO `user_products` (`user_id`, `product_id`, `created_at`) VALUES
('b58b1020-6b47-4ef2-9b87-2e5252544e56', 'a3ae5c77-a960-11f0-9137-271803c7df05', '2025-10-15 00:48:54.508');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_user_stats`
-- (See below for the actual view)
--
CREATE TABLE `v_user_stats` (
`user_id` varchar(191)
,`name` varchar(191)
,`email` varchar(191)
,`total_quiz_attempts` bigint(21)
,`correct_answers` decimal(22,0)
,`accuracy_percentage` decimal(28,2)
,`topics_started` bigint(21)
,`avg_completion` decimal(14,4)
,`total_bookmarks` bigint(21)
);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookmarks`
--
ALTER TABLE `bookmarks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `bookmarks_user_id_qna_id_key` (`user_id`,`qna_id`),
  ADD UNIQUE KEY `bookmarks_user_id_pdf_id_key` (`user_id`,`pdf_id`),
  ADD KEY `idx_bookmarks_user_id` (`user_id`),
  ADD KEY `idx_bookmarks_qna_id` (`qna_id`),
  ADD KEY `idx_bookmarks_pdf_id` (`pdf_id`);

--
-- Indexes for table `pdfs`
--
ALTER TABLE `pdfs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pdfs_topic_id_idx` (`topic_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `products_slug_key` (`slug`);

--
-- Indexes for table `progress`
--
ALTER TABLE `progress`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `progress_user_id_topic_id_key` (`user_id`,`topic_id`),
  ADD KEY `idx_progress_user_id` (`user_id`),
  ADD KEY `idx_progress_topic_id` (`topic_id`);

--
-- Indexes for table `qna`
--
ALTER TABLE `qna`
  ADD PRIMARY KEY (`id`),
  ADD KEY `qna_topic_id_idx` (`topic_id`);

--
-- Indexes for table `quizzes`
--
ALTER TABLE `quizzes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `quizzes_topic_id_idx` (`topic_id`);

--
-- Indexes for table `quiz_attempts`
--
ALTER TABLE `quiz_attempts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_quiz_attempts_user_id` (`user_id`),
  ADD KEY `idx_quiz_attempts_quiz_id` (`quiz_id`),
  ADD KEY `quiz_attempts_user_id_quiz_id_idx` (`user_id`,`quiz_id`);

--
-- Indexes for table `refresh_tokens`
--
ALTER TABLE `refresh_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `refresh_tokens_token_key` (`token`),
  ADD KEY `idx_refresh_tokens_user_id` (`user_id`);

--
-- Indexes for table `topics`
--
ALTER TABLE `topics`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_topics_product_id` (`product_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_key` (`email`);

--
-- Indexes for table `user_products`
--
ALTER TABLE `user_products`
  ADD PRIMARY KEY (`user_id`,`product_id`),
  ADD KEY `user_products_product_id_fkey` (`product_id`);

-- --------------------------------------------------------

--
-- Structure for view `v_user_stats`
--
DROP TABLE IF EXISTS `v_user_stats`;

CREATE ALGORITHM=UNDEFINED DEFINER=`u286264826_ROOTQndAProd`@`127.0.0.1` SQL SECURITY DEFINER VIEW `v_user_stats`  AS SELECT `u`.`id` AS `user_id`, `u`.`name` AS `name`, `u`.`email` AS `email`, count(distinct `qa`.`id`) AS `total_quiz_attempts`, sum(case when `qa`.`is_correct` then 1 else 0 end) AS `correct_answers`, round(sum(case when `qa`.`is_correct` then 1 else 0 end) * 100.0 / count(`qa`.`id`),2) AS `accuracy_percentage`, count(distinct `p`.`topic_id`) AS `topics_started`, avg(`p`.`completion_percent`) AS `avg_completion`, count(distinct `b`.`id`) AS `total_bookmarks` FROM (((`users` `u` left join `quiz_attempts` `qa` on(`u`.`id` = `qa`.`user_id`)) left join `progress` `p` on(`u`.`id` = `p`.`user_id`)) left join `bookmarks` `b` on(`u`.`id` = `b`.`user_id`)) WHERE `u`.`role` = 'USER' GROUP BY `u`.`id`, `u`.`name`, `u`.`email` ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookmarks`
--
ALTER TABLE `bookmarks`
  ADD CONSTRAINT `bookmarks_pdf_id_fkey` FOREIGN KEY (`pdf_id`) REFERENCES `pdfs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `bookmarks_qna_id_fkey` FOREIGN KEY (`qna_id`) REFERENCES `qna` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `bookmarks_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `pdfs`
--
ALTER TABLE `pdfs`
  ADD CONSTRAINT `pdfs_topic_id_fkey` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `progress`
--
ALTER TABLE `progress`
  ADD CONSTRAINT `progress_topic_id_fkey` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `progress_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `qna`
--
ALTER TABLE `qna`
  ADD CONSTRAINT `qna_topic_id_fkey` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `quizzes`
--
ALTER TABLE `quizzes`
  ADD CONSTRAINT `quizzes_topic_id_fkey` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `quiz_attempts`
--
ALTER TABLE `quiz_attempts`
  ADD CONSTRAINT `quiz_attempts_quiz_id_fkey` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `quiz_attempts_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `refresh_tokens`
--
ALTER TABLE `refresh_tokens`
  ADD CONSTRAINT `refresh_tokens_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `topics`
--
ALTER TABLE `topics`
  ADD CONSTRAINT `topics_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `user_products`
--
ALTER TABLE `user_products`
  ADD CONSTRAINT `user_products_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `user_products_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
