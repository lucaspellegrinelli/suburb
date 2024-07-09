import gleam/string
import sqlight

const pragma_foreign_keys_sql = "PRAGMA foreign_keys = ON;"

const create_namespaces_sql = "
CREATE TABLE IF NOT EXISTS namespaces (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_namespaces_name ON namespaces (name);
"

const create_queue_sql = "
CREATE TABLE IF NOT EXISTS queues (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  namespace_id INTEGER,
  queue TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(queue, namespace_id),
  FOREIGN KEY(namespace_id) REFERENCES namespaces(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_queues_queue_namespace_id ON queues (queue, namespace_id);
"

const create_queued_values_sql = "
CREATE TABLE IF NOT EXISTS queued_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  queue_id INTEGER,
  content TEXT,
  consumed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(queue_id) REFERENCES queues(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_queued_values_queue_id_consumed_at ON queued_values (queue_id, consumed_at);
"

const create_feature_flag_sql = "
CREATE TABLE IF NOT EXISTS feature_flags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  namespace_id INTEGER,
  flag TEXT,
  value TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(flag, namespace_id),
  FOREIGN KEY(namespace_id) REFERENCES namespaces(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_feature_flags_flag_namespace_id ON feature_flags (flag, namespace_id);
"

const create_log_sql = "
CREATE TABLE IF NOT EXISTS logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  namespace_id INTEGER,
  source TEXT,
  level TEXT,
  message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(namespace_id) REFERENCES namespaces(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_logs_namespace_id_created_at ON logs (namespace_id, created_at);
CREATE INDEX IF NOT EXISTS idx_logs_source_created_at ON logs (source, created_at);
CREATE INDEX IF NOT EXISTS idx_logs_level_created_at ON logs (level, created_at);
CREATE INDEX IF NOT EXISTS idx_logs_namespace_id_source_level_created_at ON logs (namespace_id, source, level, created_at);
"

pub fn db_connection(database_path: String, f: fn(sqlight.Connection) -> a) {
  use conn <- sqlight.with_connection(database_path)
  let sql =
    string.concat([
      pragma_foreign_keys_sql,
      create_queue_sql,
      create_queued_values_sql,
      create_feature_flag_sql,
      create_log_sql,
      create_namespaces_sql,
    ])
  let assert Ok(Nil) = sqlight.exec(sql, conn)
  f(conn)
}
