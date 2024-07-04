import gleam/string
import sqlight

const database_path = "suburb.db"

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

pub fn db_connection(f: fn(sqlight.Connection) -> a) {
  use conn <- sqlight.with_connection(database_path)
  let sql = string.concat([create_queue_sql, create_feature_flag_sql])
  let assert Ok(Nil) = sqlight.exec(sql, conn)
  f(conn)
}
