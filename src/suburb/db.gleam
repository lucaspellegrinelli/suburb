import sqlight

const database_path = "suburb.db"

const create_queue_sql = "
CREATE TABLE IF NOT EXISTS queues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    queue_name TEXT,
    namespace TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(queue_name, namespace)
);

CREATE TABLE IF NOT EXISTS queued_values (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    queue_id INTEGER,
    content TEXT,
    consumed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(queue_id) REFERENCES queues(id)
);

CREATE INDEX IF NOT EXISTS idx_queues_queue_name_namespace ON queues (queue_name, namespace);
CREATE INDEX IF NOT EXISTS idx_queued_values_queue_id_consumed_at ON queued_values (queue_id, consumed_at);
"

pub fn db_connection(f: fn(sqlight.Connection) -> a) {
  use conn <- sqlight.with_connection(database_path)
  let assert Ok(Nil) = sqlight.exec(create_queue_sql, conn)
  f(conn)
}
