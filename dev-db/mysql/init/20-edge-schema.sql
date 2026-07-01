USE querypod_lab;

CREATE TABLE `order` (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  `group` VARCHAR(64) NOT NULL,
  notes TEXT NULL,
  inserted_at DATETIME NOT NULL
);

CREATE TABLE json_documents (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  doc_key VARCHAR(64) NOT NULL,
  payload JSON NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_json_documents_doc_key (doc_key)
);

CREATE TABLE temporal_edges (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  label_name VARCHAR(64) NOT NULL,
  due_date DATE NULL,
  happened_at DATETIME NULL,
  created_ts TIMESTAMP NULL,
  updated_ts TIMESTAMP NULL
);

CREATE TABLE org_nodes (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  parent_id BIGINT NULL,
  node_name VARCHAR(128) NOT NULL,
  depth_level INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_org_nodes_parent
    FOREIGN KEY (parent_id) REFERENCES org_nodes(id)
);

CREATE TABLE large_events (
  id BIGINT PRIMARY KEY,
  category_name VARCHAR(32) NOT NULL,
  event_name VARCHAR(128) NOT NULL,
  event_meta JSON NOT NULL,
  created_at DATETIME NOT NULL
);

INSERT INTO `order` (`group`, notes, inserted_at) VALUES
  ('alpha', 'Reserved identifiers fixture', '2024-03-01 08:00:00'),
  ('beta', 'Second row', '2024-03-01 08:05:00');

INSERT INTO json_documents (doc_key, payload, created_at) VALUES
  ('settings', JSON_OBJECT('enabled', true, 'threshold', 42, 'tags', JSON_ARRAY('db', 'ui')), '2024-03-04 10:00:00'),
  ('profile', JSON_OBJECT('nested', JSON_OBJECT('level', 2), 'null_field', CAST(NULL AS JSON)), '2024-03-05 11:00:00');

INSERT INTO temporal_edges (label_name, due_date, happened_at, created_ts, updated_ts) VALUES
  ('leap-day', '2024-02-29', '2024-02-29 23:59:59', '2024-02-29 23:59:59', '2024-03-01 00:00:00'),
  ('epoch-near', '1970-01-02', '1970-01-02 00:00:01', '1970-01-02 00:00:01', '1970-01-03 00:00:01'),
  ('future-nullable', '2099-12-31', NULL, NULL, NULL);

INSERT INTO org_nodes (id, parent_id, node_name, depth_level) VALUES
  (1, NULL, 'root', 0),
  (2, 1, 'engineering', 1),
  (3, 2, 'query-engine', 2),
  (4, 1, 'design', 1);

INSERT INTO large_events (id, category_name, event_name, event_meta, created_at)
SELECT
  ones.n + tens.n * 10 + hundreds.n * 100 + 1,
  CASE MOD(ones.n + tens.n * 10 + hundreds.n * 100 + 1, 4)
    WHEN 0 THEN 'audit'
    WHEN 1 THEN 'sync'
    WHEN 2 THEN 'query'
    ELSE 'user'
  END,
  CONCAT('event-', LPAD(ones.n + tens.n * 10 + hundreds.n * 100 + 1, 4, '0')),
  JSON_OBJECT(
    'batch',
    FLOOR((ones.n + tens.n * 10 + hundreds.n * 100) / 100),
    'important',
    MOD(ones.n + tens.n * 10 + hundreds.n * 100 + 1, 10) = 0,
    'ordinal',
    ones.n + tens.n * 10 + hundreds.n * 100 + 1
  ),
  TIMESTAMP('2024-04-01 00:00:00') + INTERVAL (ones.n + tens.n * 10 + hundreds.n * 100 + 1) MINUTE
FROM
  (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS ones
  CROSS JOIN
  (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS tens
  CROSS JOIN
  (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS hundreds;
