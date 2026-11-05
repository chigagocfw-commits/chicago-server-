CREATE TABLE IF NOT EXISTS `rental_history` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `vehicle_model` varchar(50) NOT NULL,
    `price` int(11) NOT NULL DEFAULT 0,
    `deposit` int(11) NOT NULL DEFAULT 0,
    `plate` varchar(20) NOT NULL,
    `rent_time` datetime NOT NULL,
    `return_time` datetime DEFAULT NULL,
    `refund` int(11) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
