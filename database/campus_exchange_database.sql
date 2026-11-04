-- ============================================================
-- CAMPUS EXCHANGE - COMPLETE MYSQL DATABASE
-- Compatible with MySQL 8.0+
-- Storage engine: InnoDB | Character set: utf8mb4
--
-- IMPORTANT:
-- This script creates a fresh database. If campus_exchange already
-- exists, its contents are NOT dropped. Existing tables may cause
-- "already exists" errors. Back up your data before modifying it.
-- ============================================================

CREATE DATABASE IF NOT EXISTS campus_exchange
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE campus_exchange;

-- ------------------------------------------------------------
-- MEMBER 1: USER MANAGEMENT & AUTHENTICATION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS departments (
  department_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  department_name VARCHAR(100) NOT NULL,
  department_code VARCHAR(20) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_departments_name (department_name),
  UNIQUE KEY uq_departments_code (department_code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
  user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  department_id INT UNSIGNED NULL,
  student_id VARCHAR(30) NULL,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NULL,
  profile_image VARCHAR(500) NULL,
  bio TEXT NULL,
  account_status ENUM('pending','active','blocked','deactivated')
    NOT NULL DEFAULT 'pending',
  email_verified_at DATETIME NULL,
  last_login_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_users_student_id (student_id),
  UNIQUE KEY uq_users_email (email),
  UNIQUE KEY uq_users_phone (phone),
  KEY idx_users_department (department_id),
  KEY idx_users_status (account_status),
  CONSTRAINT fk_users_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS roles (
  role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_roles_name (role_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_roles (
  user_id INT UNSIGNED NOT NULL,
  role_id INT UNSIGNED NOT NULL,
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_user_roles_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_user_roles_role
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_verifications (
  verification_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  verification_type ENUM('college_email','student_id') NOT NULL,
  verification_value VARCHAR(255) NOT NULL,
  document_url VARCHAR(500) NULL,
  verification_status ENUM('pending','verified','rejected')
    NOT NULL DEFAULT 'pending',
  reviewed_by INT UNSIGNED NULL,
  rejection_reason VARCHAR(500) NULL,
  verified_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_verifications_user (user_id),
  KEY idx_verifications_status (verification_status),
  CONSTRAINT fk_verifications_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_verifications_reviewer
    FOREIGN KEY (reviewed_by) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS refresh_tokens (
  token_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  token_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_refresh_token_hash (token_hash),
  KEY idx_refresh_user_expiry (user_id, expires_at),
  CONSTRAINT fk_refresh_tokens_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- MEMBER 2: PRODUCT MANAGEMENT & MARKETPLACE
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS categories (
  category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parent_id INT UNSIGNED NULL,
  category_name VARCHAR(100) NOT NULL,
  description TEXT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_category_parent_name (parent_id, category_name),
  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
  product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  seller_id INT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  product_name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  product_condition ENUM('new','like_new','good','fair')
    NOT NULL DEFAULT 'good',
  listing_type ENUM('sale','borrow','exchange','donate')
    NOT NULL DEFAULT 'sale',
  product_status ENUM('available','reserved','sold','borrowed','removed')
    NOT NULL DEFAULT 'available',
  location_description VARCHAR(255) NULL,
  published_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_products_seller (seller_id),
  KEY idx_products_category_status (category_id, product_status),
  KEY idx_products_type_status (listing_type, product_status),
  KEY idx_products_price (price),
  KEY idx_products_created (created_at),
  FULLTEXT KEY ft_products_search (product_name, description),
  CONSTRAINT chk_products_price_nonnegative CHECK (price >= 0),
  CONSTRAINT fk_products_seller
    FOREIGN KEY (seller_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS product_images (
  image_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  image_url VARCHAR(500) NOT NULL,
  display_order INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_product_images_product (product_id),
  CONSTRAINT fk_product_images_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS wishlists (
  wishlist_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_wishlists_user (user_id),
  CONSTRAINT fk_wishlists_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS wishlist_items (
  wishlist_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (wishlist_id, product_id),
  KEY idx_wishlist_items_product (product_id),
  CONSTRAINT fk_wishlist_items_wishlist
    FOREIGN KEY (wishlist_id) REFERENCES wishlists(wishlist_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_wishlist_items_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- MEMBER 3: REQUESTS, TRANSACTIONS, PAYMENTS, CHAT & REVIEWS
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS purchase_requests (
  purchase_request_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  buyer_id INT UNSIGNED NOT NULL,
  request_type ENUM('purchase','exchange','donation') NOT NULL DEFAULT 'purchase',
  request_message TEXT NULL,
  offered_product_id BIGINT UNSIGNED NULL,
  request_status ENUM('pending','accepted','rejected','cancelled')
    NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_purchase_product_status (product_id, request_status),
  KEY idx_purchase_buyer (buyer_id),
  CONSTRAINT chk_purchase_not_own_product CHECK (buyer_id > 0),
  CONSTRAINT fk_purchase_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_purchase_buyer
    FOREIGN KEY (buyer_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_purchase_offered_product
    FOREIGN KEY (offered_product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS borrow_requests (
  borrow_request_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  borrower_id INT UNSIGNED NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  request_message TEXT NULL,
  request_status ENUM('pending','accepted','rejected','cancelled','returned')
    NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_borrow_product_status (product_id, request_status),
  KEY idx_borrow_borrower (borrower_id),
  CONSTRAINT chk_borrow_dates CHECK (end_date >= start_date),
  CONSTRAINT fk_borrow_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_borrow_borrower
    FOREIGN KEY (borrower_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS transactions (
  transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  purchase_request_id BIGINT UNSIGNED NULL,
  borrow_request_id BIGINT UNSIGNED NULL,
  buyer_id INT UNSIGNED NOT NULL,
  seller_id INT UNSIGNED NOT NULL,
  transaction_type ENUM('purchase','borrow','exchange','donation') NOT NULL,
  transaction_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  transaction_status ENUM('pending','confirmed','completed','cancelled')
    NOT NULL DEFAULT 'pending',
  completed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_transaction_purchase_request (purchase_request_id),
  UNIQUE KEY uq_transaction_borrow_request (borrow_request_id),
  KEY idx_transactions_buyer_status (buyer_id, transaction_status),
  KEY idx_transactions_seller_status (seller_id, transaction_status),
  CONSTRAINT chk_transaction_one_request CHECK (
    (purchase_request_id IS NOT NULL AND borrow_request_id IS NULL)
    OR
    (purchase_request_id IS NULL AND borrow_request_id IS NOT NULL)
  ),
  CONSTRAINT chk_transaction_amount CHECK (transaction_amount >= 0),
  CONSTRAINT chk_transaction_parties CHECK (buyer_id <> seller_id),
  CONSTRAINT fk_transaction_purchase_request
    FOREIGN KEY (purchase_request_id)
    REFERENCES purchase_requests(purchase_request_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_transaction_borrow_request
    FOREIGN KEY (borrow_request_id)
    REFERENCES borrow_requests(borrow_request_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_transaction_buyer
    FOREIGN KEY (buyer_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_transaction_seller
    FOREIGN KEY (seller_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
  payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  transaction_id BIGINT UNSIGNED NOT NULL,
  payer_id INT UNSIGNED NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_method ENUM('upi','cash','other') NOT NULL,
  payment_reference VARCHAR(150) NULL,
  payment_status ENUM('pending','confirmed','failed','refunded')
    NOT NULL DEFAULT 'pending',
  confirmed_by INT UNSIGNED NULL,
  paid_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_payments_transaction (transaction_id),
  KEY idx_payments_payer (payer_id),
  CONSTRAINT chk_payment_amount CHECK (amount >= 0),
  CONSTRAINT fk_payments_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_payments_payer
    FOREIGN KEY (payer_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_payments_confirmer
    FOREIGN KEY (confirmed_by) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pickup_details (
  pickup_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  transaction_id BIGINT UNSIGNED NOT NULL,
  pickup_location VARCHAR(255) NOT NULL,
  scheduled_at DATETIME NULL,
  pickup_status ENUM('pending','scheduled','completed','cancelled')
    NOT NULL DEFAULT 'pending',
  handover_qr_token_hash VARCHAR(255) NULL,
  qr_expires_at DATETIME NULL,
  qr_verified_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_pickup_transaction (transaction_id),
  CONSTRAINT fk_pickup_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS conversations (
  conversation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  buyer_id INT UNSIGNED NOT NULL,
  seller_id INT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_conversation_product_buyer_seller
    (product_id, buyer_id, seller_id),
  KEY idx_conversations_buyer (buyer_id),
  KEY idx_conversations_seller (seller_id),
  CONSTRAINT chk_conversation_parties CHECK (buyer_id <> seller_id),
  CONSTRAINT fk_conversations_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_conversations_buyer
    FOREIGN KEY (buyer_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_conversations_seller
    FOREIGN KEY (seller_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS messages (
  message_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversation_id BIGINT UNSIGNED NOT NULL,
  sender_id INT UNSIGNED NOT NULL,
  message_content TEXT NOT NULL,
  message_type ENUM('text','image') NOT NULL DEFAULT 'text',
  sent_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  read_at DATETIME NULL,
  KEY idx_messages_conversation_time (conversation_id, sent_at),
  KEY idx_messages_sender (sender_id),
  CONSTRAINT fk_messages_conversation
    FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_messages_sender
    FOREIGN KEY (sender_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reviews (
  review_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  transaction_id BIGINT UNSIGNED NOT NULL,
  reviewer_id INT UNSIGNED NOT NULL,
  reviewee_id INT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  comment TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_review_transaction_reviewer (transaction_id, reviewer_id),
  KEY idx_reviews_reviewee (reviewee_id),
  CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT chk_review_parties CHECK (reviewer_id <> reviewee_id),
  CONSTRAINT fk_reviews_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reviews_reviewer
    FOREIGN KEY (reviewer_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reviews_reviewee
    FOREIGN KEY (reviewee_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- MEMBER 4: SMART FEATURES & ADMIN
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS need_requests (
  need_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  description TEXT NULL,
  budget DECIMAL(10,2) NULL,
  need_status ENUM('open','fulfilled','cancelled') NOT NULL DEFAULT 'open',
  fulfilled_by_product_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_needs_user_status (user_id, need_status),
  KEY idx_needs_category_status (category_id, need_status),
  CONSTRAINT chk_need_budget CHECK (budget IS NULL OR budget >= 0),
  CONSTRAINT fk_needs_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_needs_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_needs_fulfilled_product
    FOREIGN KEY (fulfilled_by_product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
  notification_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  notification_type VARCHAR(50) NULL,
  related_entity_type VARCHAR(50) NULL,
  related_entity_id BIGINT UNSIGNED NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_notifications_user_read_time (user_id, is_read, created_at),
  CONSTRAINT fk_notifications_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reports (
  report_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reporter_id INT UNSIGNED NOT NULL,
  target_type ENUM('user','product') NOT NULL,
  target_id BIGINT UNSIGNED NOT NULL,
  reason VARCHAR(150) NOT NULL,
  description TEXT NULL,
  report_status ENUM('pending','reviewed','resolved','dismissed')
    NOT NULL DEFAULT 'pending',
  reviewed_by INT UNSIGNED NULL,
  admin_notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at DATETIME NULL,
  KEY idx_reports_status_time (report_status, created_at),
  KEY idx_reports_target (target_type, target_id),
  CONSTRAINT fk_reports_reporter
    FOREIGN KEY (reporter_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reports_reviewer
    FOREIGN KEY (reviewed_by) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE SET NULL
  -- target_id is polymorphic (users or products); validate in application code.
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trust_scores (
  trust_score_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  score DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  completed_transactions INT UNSIGNED NOT NULL DEFAULT 0,
  positive_reviews INT UNSIGNED NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_trust_scores_user (user_id),
  CONSTRAINT chk_trust_score_range CHECK (score BETWEEN 0 AND 100),
  CONSTRAINT fk_trust_scores_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reuse_activities (
  activity_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  transaction_id BIGINT UNSIGNED NOT NULL,
  activity_type ENUM('purchased','borrowed','exchanged','donated') NOT NULL,
  estimated_carbon_saved DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_reuse_user_time (user_id, created_at),
  KEY idx_reuse_transaction (transaction_id),
  CONSTRAINT chk_carbon_saved CHECK (estimated_carbon_saved >= 0),
  CONSTRAINT fk_reuse_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reuse_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reuse_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS search_history (
  search_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  search_query VARCHAR(255) NOT NULL,
  filters JSON NULL,
  searched_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_search_user_time (user_id, searched_at),
  CONSTRAINT fk_search_history_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- INITIAL REFERENCE DATA
-- Safe to run more than once.
-- ------------------------------------------------------------

INSERT INTO roles (role_name)
VALUES ('student'), ('admin')
ON DUPLICATE KEY UPDATE role_name = VALUES(role_name);

INSERT INTO categories (category_name, description)
VALUES
  ('Books', 'Textbooks, reference books and study materials'),
  ('Electronics', 'Laptops, phones, calculators and accessories'),
  ('Furniture', 'Desks, chairs and storage items'),
  ('Clothing', 'Clothes, shoes and accessories'),
  ('Sports Equipment', 'Sports and fitness equipment'),
  ('Stationery', 'Notebooks, pens and other stationery'),
  ('Other', 'Items that do not fit another category')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- ------------------------------------------------------------
-- OPTIONAL SAMPLE DATA
-- Uncomment and replace values before using.
-- NEVER use these placeholder credentials in production.
-- Generate a real bcrypt hash in your Node.js application.
-- ------------------------------------------------------------

-- INSERT INTO departments (department_name, department_code)
-- VALUES ('Computer Science', 'CSE'), ('Electronics', 'ECE');

-- INSERT INTO users
-- (department_id, student_id, full_name, email, password_hash, account_status)
-- VALUES
-- (1, 'STU001', 'Sample Student', 'student@example.edu',
--  '$2b$12$REPLACE_WITH_A_REAL_BCRYPT_HASH', 'active');

-- INSERT INTO user_roles (user_id, role_id)
-- SELECT u.user_id, r.role_id
-- FROM users u JOIN roles r ON r.role_name = 'student'
-- WHERE u.email = 'student@example.edu';

-- ------------------------------------------------------------
-- VERIFICATION QUERIES
-- Run after executing the script.
-- ------------------------------------------------------------

SHOW TABLES;

SELECT
  TABLE_NAME,
  TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME;

-- Example: view all categories
SELECT category_id, category_name
FROM categories
WHERE is_active = TRUE
ORDER BY category_name;

-- Example: list available products with seller and category
SELECT
  p.product_id,
  p.product_name,
  p.price,
  p.listing_type,
  p.product_condition,
  u.full_name AS seller_name,
  c.category_name
FROM products p
JOIN users u ON u.user_id = p.seller_id
JOIN categories c ON c.category_id = p.category_id
WHERE p.product_status = 'available'
ORDER BY p.created_at DESC;
