-- ════════════════════════════════════════════════════════════════════════
--  OXLYN Advanced Garage System — optional install SQL
--  The resource creates these tables by itself on first start (CREATE TABLE
--  IF NOT EXISTS). Import this file only if you prefer to create them by
--  hand or your database user is not allowed to create tables.
--
--  oxlyn_garages          the garage documents saved by /garageeditor
--  oxlyn_garage_vehicles  per plate: nickname, parked when/where/by whom,
--                         impound record, contract lock
--  oxlyn_garage_settings  the interface theme and park mode rules
--  oxlyn_garage_parked    vehicles left in park mode (/park)
--  oxlyn_garage_contracts audit log of every sale contract
--
--  Vehicle OWNERSHIP stays in your framework's own table (ESX owned_vehicles,
--  QBCore / Qbox player_vehicles). On ESX the resource adds the columns
--  parking and pound to owned_vehicles when they are missing.
-- ════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `oxlyn_garages` (
    `id`         VARCHAR(48) NOT NULL,
    `data`       LONGTEXT    NOT NULL,
    `updated_at` INT         NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `oxlyn_garage_vehicles` (
    `plate`          VARCHAR(16)  NOT NULL,
    `nickname`       VARCHAR(32)  NULL,
    `vtype`          VARCHAR(16)  NULL,
    `stored_at`      INT          NULL,
    `stored_by`      VARCHAR(64)  NULL,
    `last_garage`    VARCHAR(48)  NULL,
    `impound_reason` VARCHAR(128) NULL,
    `impound_fee`    INT          NULL,
    `impound_at`     INT          NULL,
    `impound_by`     VARCHAR(64)  NULL,
    `impound_lot`    VARCHAR(48)  NULL,
    `contract_id`    VARCHAR(40)  NULL,
    `data`           LONGTEXT     NULL,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `oxlyn_garage_settings` (
    `id`         VARCHAR(32) NOT NULL,
    `data`       LONGTEXT    NOT NULL,
    `updated_at` INT         NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `oxlyn_garage_parked` (
    `plate`      VARCHAR(16)  NOT NULL,
    `plate_raw`  VARCHAR(16)  NOT NULL,
    `owner`      VARCHAR(64)  NOT NULL,
    `model`      BIGINT       NOT NULL DEFAULT 0,
    `vtype`      VARCHAR(24)  NOT NULL DEFAULT 'automobile',
    `x`          FLOAT        NOT NULL DEFAULT 0,
    `y`          FLOAT        NOT NULL DEFAULT 0,
    `z`          FLOAT        NOT NULL DEFAULT 0,
    `w`          FLOAT        NOT NULL DEFAULT 0,
    `props`      LONGTEXT     NULL,
    `parked_at`  INT          NOT NULL DEFAULT 0,
    PRIMARY KEY (`plate`),
    KEY `owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `oxlyn_garage_contracts` (
    `id`             VARCHAR(40) NOT NULL,
    `plate`          VARCHAR(16) NOT NULL,
    `seller`         VARCHAR(64) NOT NULL,
    `seller_name`    VARCHAR(64) NULL,
    `buyer`          VARCHAR(64) NOT NULL,
    `buyer_name`     VARCHAR(64) NULL,
    `price`          INT         NOT NULL DEFAULT 0,
    `model`          VARCHAR(64) NULL,
    `label`          VARCHAR(64) NULL,
    `status`         VARCHAR(16) NOT NULL DEFAULT 'pending',
    `created_at`     INT         NULL,
    `expires_at`     INT         NULL,
    `resolved_at`    INT         NULL,
    `refund_pending` TINYINT     NOT NULL DEFAULT 0,
    `data`           LONGTEXT    NULL,
    PRIMARY KEY (`id`),
    KEY `seller` (`seller`),
    KEY `buyer` (`buyer`),
    KEY `status` (`status`),
    KEY `plate_status_created` (`plate`, `status`, `created_at`),
    KEY `status_expires` (`status`, `expires_at`),
    KEY `seller_refund` (`seller`, `refund_pending`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
