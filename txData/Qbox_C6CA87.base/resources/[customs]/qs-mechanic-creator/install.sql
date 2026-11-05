-- qs-mechanic-creator — auto-created on resource start; run manually if needed

CREATE TABLE IF NOT EXISTS `mechanic_shops` (
    `shop_id` VARCHAR(64) NOT NULL,
    `data` LONGTEXT NOT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mechanic_configs` (
    `config_key` VARCHAR(64) NOT NULL,
    `data` LONGTEXT NOT NULL,
    PRIMARY KEY (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mechanic_vehicle_mods` (
    `plate` VARCHAR(16) NOT NULL,
    `data` LONGTEXT NOT NULL,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mechanic_vehicle_engines` (
    `plate` VARCHAR(16) NOT NULL,
    `data` LONGTEXT NOT NULL,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mechanic_employees` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `shop_id` VARCHAR(64) NOT NULL,
    `identifier` VARCHAR(80) NOT NULL,
    `name` VARCHAR(128) DEFAULT NULL,
    `grade` INT NOT NULL DEFAULT 0,
    `permissions` LONGTEXT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `shop_employee` (`shop_id`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mechanic_orders` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `shop_id` VARCHAR(64) NOT NULL,
    `plate` VARCHAR(16) DEFAULT NULL,
    `customer_identifier` VARCHAR(80) DEFAULT NULL,
    `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
    `total` INT NOT NULL DEFAULT 0,
    `modifications` LONGTEXT NULL,
    `vehicle_data` LONGTEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mechanic_stashes` (
    `stash_key` VARCHAR(128) NOT NULL,
    `items` LONGTEXT NOT NULL,
    PRIMARY KEY (`stash_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mechanic_engine_stock` (
    `shop_id` VARCHAR(64) NOT NULL,
    `data` LONGTEXT NOT NULL,
    PRIMARY KEY (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mechanic_bills` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `shop_id` VARCHAR(64) DEFAULT NULL,
    `from_identifier` VARCHAR(80) DEFAULT NULL,
    `to_identifier` VARCHAR(80) NOT NULL,
    `amount` INT NOT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
