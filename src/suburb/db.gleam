import gleam/string
import sqlight

const create_queue_sql = "
CREATE TABLE IF NOT EXISTS queues (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  namespace TEXT,
  queue TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(queue, namespace)
);
CREATE INDEX IF NOT EXISTS idx_queues_queue_namespace ON queues (queue, namespace);

CREATE TABLE IF NOT EXISTS queued_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  queue_id INTEGER,
  content TEXT,
  consumed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(queue_id) REFERENCES queues(id)
);

CREATE INDEX IF NOT EXISTS idx_queued_values_queue_id_consumed_at ON queued_values (queue_id, consumed_at);
"

const create_feature_flag_sql = "
CREATE TABLE IF NOT EXISTS feature_flags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  namespace TEXT,
  flag TEXT,
  value TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(flag, namespace)
);
CREATE INDEX IF NOT EXISTS idx_feature_flags_flag_namespace ON feature_flags (flag, namespace);
"

const create_log_sql = "
CREATE TABLE IF NOT EXISTS logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  namespace TEXT,
  source TEXT,
  level TEXT,
  message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_logs_namespace_created_at ON logs (namespace, created_at);
CREATE INDEX IF NOT EXISTS idx_logs_source_created_at ON logs (source, created_at);
CREATE INDEX IF NOT EXISTS idx_logs_level_created_at ON logs (level, created_at);
CREATE INDEX IF NOT EXISTS idx_logs_namespace_source_level_created_at ON logs (namespace, source, level, created_at);
"

pub fn db_connection(database_path: String, f: fn(sqlight.Connection) -> a) {
  use conn <- sqlight.with_connection(database_path)
  let sql =
    string.concat([create_queue_sql, create_feature_flag_sql, create_log_sql])
  let assert Ok(Nil) = sqlight.exec(sql, conn)
  f(conn)
}
