USE querypod_lab;

CREATE INDEX idx_projects_status ON projects (status);
CREATE INDEX idx_activity_logs_happened_at ON activity_logs (happened_at);
CREATE INDEX idx_temporal_edges_due_date ON temporal_edges (due_date);
CREATE INDEX idx_large_events_category_created ON large_events (category_name, created_at);

CREATE VIEW active_project_overview AS
SELECT
  p.id,
  p.slug,
  p.title,
  p.status,
  u.display_name AS owner_name,
  COUNT(pm.user_id) AS member_count
FROM projects p
JOIN users u ON u.id = p.owner_user_id
LEFT JOIN project_members pm ON pm.project_id = p.id
GROUP BY p.id, p.slug, p.title, p.status, u.display_name;
