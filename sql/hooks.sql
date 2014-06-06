CREATE TABLE `hooks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `service` varchar(100) DEFAULT NULL COMMENT 'サービス名',
  `label` varchar(255) DEFAULT NULL COMMENT 'ラベル',
  `channel_id` varchar(100) DEFAULT NULL COMMENT 'チャンネルID',
  `botname` varchar(100) DEFAULT NULL COMMENT 'ボットの名前',
  `token` varchar(10) DEFAULT NULL COMMENT 'トークン',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  INDEX token_idx(`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT="フック設定";
