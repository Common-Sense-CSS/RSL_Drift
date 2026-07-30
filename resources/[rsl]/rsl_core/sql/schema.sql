-- RSL Drift Framework — database schema
-- Applied automatically on resource start (see modules/player/player_data_s.lua),
-- kept here as well for reference / manual setup.

CREATE TABLE IF NOT EXISTS `rsl_players` (
    `identifier`   VARCHAR(60) NOT NULL,
    `name`         VARCHAR(128) NOT NULL DEFAULT 'Driver',
    `cash`         INT UNSIGNED NOT NULL DEFAULT 0,
    `xp`           INT UNSIGNED NOT NULL DEFAULT 0,
    `level`        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `data`         LONGTEXT NOT NULL DEFAULT ('{}'),
    `created_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    `last_seen_at` DATETIME(3) NULL DEFAULT NULL,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rsl_vehicles` (
    `id`               CHAR(36) NOT NULL,
    `owner_identifier` VARCHAR(60) NOT NULL,
    `model`            VARCHAR(64) NOT NULL,
    `plate`            VARCHAR(12) NOT NULL,
    `garage_id`        VARCHAR(64) NOT NULL,
    `stored`           TINYINT(1) NOT NULL DEFAULT 1,
    `mods`             LONGTEXT NOT NULL DEFAULT ('{}'),
    `tuning`           LONGTEXT NOT NULL DEFAULT ('{}'),
    `xp`               INT UNSIGNED NOT NULL DEFAULT 0,
    `level`            SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `created_at`       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at`       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_plate` (`plate`),
    KEY `idx_owner` (`owner_identifier`),
    CONSTRAINT `fk_vehicle_owner` FOREIGN KEY (`owner_identifier`) REFERENCES `rsl_players` (`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rsl_drift_scores` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `zone_id`       VARCHAR(64) NOT NULL,
    `identifier`    VARCHAR(60) NOT NULL,
    `vehicle_id`    CHAR(36) NULL DEFAULT NULL,
    `score`         INT UNSIGNED NOT NULL DEFAULT 0,
    `max_combo`     INT UNSIGNED NOT NULL DEFAULT 0,
    `top_speed`     FLOAT NOT NULL DEFAULT 0,
    `duration_ms`   INT UNSIGNED NOT NULL DEFAULT 0,
    `replay_data`   LONGTEXT NULL DEFAULT NULL,
    `created_at`    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    KEY `idx_zone_score` (`zone_id`, `score` DESC),
    KEY `idx_identifier` (`identifier`),
    CONSTRAINT `fk_score_player` FOREIGN KEY (`identifier`) REFERENCES `rsl_players` (`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
