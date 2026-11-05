-- SOUH4IL-DEV — Phase 1 Schema (Staging Database Deployment)
-- Defines append-only audit tables and decoupled outbox delivery queue

CREATE TABLE IF NOT EXISTS `souh4il_dev_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `action` varchar(50) NOT NULL,
  `executor_source` int(11) DEFAULT NULL,
  `executor_name` varchar(100) NOT NULL,
  `executor_license` varchar(50) NOT NULL,
  `target_source` int(11) DEFAULT NULL,
  `target_name` varchar(100) DEFAULT NULL,
  `target_license` varchar(50) DEFAULT NULL,
  `details` longtext DEFAULT NULL,
  `status` enum('SUCCESS','REJECTED','INTRUSION_ALERT') NOT NULL DEFAULT 'SUCCESS',
  `previous_hash` varchar(64) NOT NULL,
  `hash` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_action` (`action`),
  KEY `idx_executor` (`executor_license`),
  KEY `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `souh4il_dev_logs_archive` LIKE `souh4il_dev_logs`;

CREATE TABLE IF NOT EXISTS `souh4il_dev_outbox` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `log_id` bigint(20) unsigned NOT NULL,
  `destination` varchar(100) NOT NULL,
  `payload` longtext NOT NULL,
  `signature` varchar(64) NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `status` enum('PENDING','SENT','FAILED') NOT NULL DEFAULT 'PENDING',
  `last_error` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_log` (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

