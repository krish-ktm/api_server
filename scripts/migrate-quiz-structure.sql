-- SQL Migration Script for Quiz Structure Changes
-- This script modifies the database structure to separate quizzes from topics
-- and allow multiple quizzes under one product

-- 1. Create the quiz_groups table
CREATE TABLE IF NOT EXISTS `quiz_groups` (
  `id` VARCHAR(191) NOT NULL,
  `product_id` VARCHAR(191) NOT NULL,
  `name` VARCHAR(191) NOT NULL,
  `description` TEXT NULL,
  `order` INTEGER NOT NULL DEFAULT 0,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  
  PRIMARY KEY (`id`),
  INDEX `quiz_groups_product_id_idx` (`product_id`),
  CONSTRAINT `quiz_groups_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 2. Create a temporary table to store quiz data
CREATE TEMPORARY TABLE IF NOT EXISTS `temp_quizzes` (
  `id` VARCHAR(191) NOT NULL,
  `topic_id` VARCHAR(191) NOT NULL,
  `question` TEXT NOT NULL,
  `options` JSON NOT NULL,
  `correct_answer` VARCHAR(191) NOT NULL,
  `explanation` TEXT NULL,
  `level` ENUM('BEGINNER', 'INTERMEDIATE', 'ADVANCED') NOT NULL DEFAULT 'BEGINNER',
  `company_tags` JSON NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`)
);

-- 3. Copy all existing quiz data to the temporary table
INSERT INTO `temp_quizzes`
SELECT * FROM `quizzes`;

-- 4. Create quiz groups for each topic that has quizzes
INSERT INTO `quiz_groups` (`id`, `product_id`, `name`, `description`, `order`, `is_active`, `created_at`, `updated_at`)
SELECT 
  UUID() as id,
  t.product_id,
  CONCAT(t.name, ' Quizzes') as name,
  CONCAT('Quizzes for ', t.name) as description,
  t.order,
  TRUE as is_active,
  NOW() as created_at,
  NOW() as updated_at
FROM 
  `topics` t
WHERE 
  EXISTS (SELECT 1 FROM `quizzes` q WHERE q.topic_id = t.id)
GROUP BY 
  t.id, t.product_id, t.name, t.order;

-- 5. Create a mapping table to track which quiz group corresponds to which topic
CREATE TEMPORARY TABLE IF NOT EXISTS `topic_to_quiz_group` (
  `topic_id` VARCHAR(191) NOT NULL,
  `quiz_group_id` VARCHAR(191) NOT NULL,
  PRIMARY KEY (`topic_id`)
);

-- 6. Populate the mapping table
INSERT INTO `topic_to_quiz_group` (`topic_id`, `quiz_group_id`)
SELECT 
  t.id as topic_id,
  qg.id as quiz_group_id
FROM 
  `topics` t
JOIN 
  `quiz_groups` qg ON qg.name = CONCAT(t.name, ' Quizzes') AND qg.product_id = t.product_id
WHERE 
  EXISTS (SELECT 1 FROM `quizzes` q WHERE q.topic_id = t.id);

-- 7. Add the quiz_group_id column to the quizzes table
ALTER TABLE `quizzes` ADD COLUMN `quiz_group_id` VARCHAR(191) NULL;

-- 8. Update the quizzes table with the new quiz_group_id
UPDATE `quizzes` q
JOIN `topic_to_quiz_group` m ON q.topic_id = m.topic_id
SET q.quiz_group_id = m.quiz_group_id;

-- 9. Add the foreign key constraint for quiz_group_id
ALTER TABLE `quizzes` 
  ADD CONSTRAINT `quizzes_quiz_group_id_fkey` 
  FOREIGN KEY (`quiz_group_id`) REFERENCES `quiz_groups` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- 10. Make quiz_group_id NOT NULL after all data is migrated
ALTER TABLE `quizzes` MODIFY COLUMN `quiz_group_id` VARCHAR(191) NOT NULL;

-- 11. Create index on quiz_group_id
CREATE INDEX `quizzes_quiz_group_id_idx` ON `quizzes` (`quiz_group_id`);

-- 12. Drop the topic_id column and its foreign key constraint and index
ALTER TABLE `quizzes` DROP FOREIGN KEY `quizzes_topic_id_fkey`;
DROP INDEX `quizzes_topic_id_idx` ON `quizzes`;
ALTER TABLE `quizzes` DROP COLUMN `topic_id`;

-- 13. Drop the temporary tables
DROP TEMPORARY TABLE IF EXISTS `temp_quizzes`;
DROP TEMPORARY TABLE IF EXISTS `topic_to_quiz_group`;

-- Migration complete
