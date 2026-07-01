USE querypod_lab;

CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  display_name VARCHAR(120) NOT NULL,
  profile_json JSON NULL,
  timezone VARCHAR(64) NOT NULL DEFAULT 'UTC',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  UNIQUE KEY uq_users_email (email)
);

CREATE TABLE projects (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  owner_user_id BIGINT NOT NULL,
  slug VARCHAR(120) NOT NULL,
  title VARCHAR(200) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'active',
  launched_on DATE NULL,
  metadata JSON NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  UNIQUE KEY uq_projects_slug (slug),
  CONSTRAINT fk_projects_owner
    FOREIGN KEY (owner_user_id) REFERENCES users(id)
);

CREATE TABLE project_members (
  project_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  role_name VARCHAR(32) NOT NULL,
  joined_at DATETIME NOT NULL,
  PRIMARY KEY (project_id, user_id),
  CONSTRAINT fk_project_members_project
    FOREIGN KEY (project_id) REFERENCES projects(id),
  CONSTRAINT fk_project_members_user
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE activity_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  project_id BIGINT NOT NULL,
  actor_user_id BIGINT NULL,
  action_name VARCHAR(64) NOT NULL,
  payload JSON NULL,
  happened_at DATETIME NOT NULL,
  CONSTRAINT fk_activity_logs_project
    FOREIGN KEY (project_id) REFERENCES projects(id),
  CONSTRAINT fk_activity_logs_actor
    FOREIGN KEY (actor_user_id) REFERENCES users(id)
);

INSERT INTO users (email, display_name, profile_json, timezone, created_at, updated_at) VALUES
  ('ada@example.com', 'Ada Lovelace', JSON_OBJECT('theme', 'solarized', 'editor', 'vim'), 'UTC', '2024-01-10 09:00:00', '2024-01-10 09:00:00'),
  ('grace@example.com', 'Grace Hopper', JSON_OBJECT('theme', 'light', 'editor', 'emacs'), 'America/New_York', '2024-01-11 10:30:00', '2024-01-11 10:30:00'),
  ('linus@example.com', 'Linus Torvalds', NULL, 'Europe/Helsinki', '2024-01-12 08:15:00', '2024-01-12 08:15:00');

INSERT INTO projects (owner_user_id, slug, title, status, launched_on, metadata, created_at, updated_at) VALUES
  (1, 'querypod-core', 'QueryPod Core', 'active', '2024-02-01', JSON_OBJECT('language', 'dart', 'dbs', JSON_ARRAY('mysql', 'postgres')), '2024-02-01 09:00:00', '2024-02-01 09:00:00'),
  (2, 'driver-lab', 'Driver Lab', 'paused', NULL, JSON_OBJECT('language', 'sql', 'focus', 'metadata'), '2024-02-03 12:00:00', '2024-02-03 12:00:00');

INSERT INTO project_members (project_id, user_id, role_name, joined_at) VALUES
  (1, 1, 'owner', '2024-02-01 09:00:00'),
  (1, 2, 'editor', '2024-02-01 09:30:00'),
  (2, 2, 'owner', '2024-02-03 12:00:00'),
  (2, 3, 'reviewer', '2024-02-03 12:30:00');

INSERT INTO activity_logs (project_id, actor_user_id, action_name, payload, happened_at) VALUES
  (1, 1, 'project_created', JSON_OBJECT('source', 'seed'), '2024-02-01 09:01:00'),
  (1, 2, 'member_joined', JSON_OBJECT('role', 'editor'), '2024-02-01 09:31:00'),
  (2, NULL, 'status_synced', JSON_OBJECT('state', 'paused', 'reason', 'fixture'), '2024-02-03 12:35:00');
