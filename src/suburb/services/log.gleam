import gleam/dynamic
import gleam/list
import gleam/pair
import gleam/string
import sqlight
import suburb/types.{type Log, type ServiceError, ConnectorError, Log}

pub type LogFilters {
  Source(String)
  Level(String)
  FromTime(String)
  UntilTime(String)
}

const add_log = "
  INSERT INTO logs (namespace_id, source, level, message)
  VALUES (
    (SELECT id FROM namespaces WHERE name = ?), ?, ?, ?
  )
  RETURNING source, level, message, created_at;
"

pub fn list(
  conn: sqlight.Connection,
  namespace: String,
  filters: List(LogFilters),
  limit: Int,
) -> Result(List(Log), ServiceError) {
  let where_items =
    list.map(filters, fn(filter) {
      case filter {
        Source(v) -> #("source = ?", sqlight.text(v))
        Level(v) -> #("level = ?", sqlight.text(v))
        FromTime(v) -> #("created_at >= ?", sqlight.text(v))
        UntilTime(v) -> #("created_at <= ?", sqlight.text(v))
      }
    })
    |> list.append([#("namespace = ?", sqlight.text(namespace))])

  let where_keys = list.map(where_items, pair.first)
  let where_values = list.map(where_items, pair.second)

  let where_clause = case list.length(where_items) {
    0 -> ""
    _ -> "WHERE " <> string.join(where_keys, " AND ")
  }

  let sql =
    "SELECT source, level, message, created_at FROM logs JOIN namespaces ON logs.namespace_id = namespaces.id "
    <> where_clause
    <> " ORDER BY created_at DESC LIMIT ?"

  let vars = list.concat([where_values, [sqlight.int(limit)]])

  let query =
    sqlight.query(
      sql,
      on: conn,
      with: vars,
      expecting: dynamic.decode4(
        Log,
        dynamic.element(0, dynamic.string),
        dynamic.element(1, dynamic.string),
        dynamic.element(2, dynamic.string),
        dynamic.element(3, dynamic.string),
      ),
    )

  case query {
    Ok(logs) -> Ok(logs)
    _ -> Error(ConnectorError("Failed to list logs."))
  }
}

pub fn add(
  conn: sqlight.Connection,
  namespace: String,
  source: String,
  level: String,
  message: String,
) -> Result(Log, ServiceError) {
  let query =
    sqlight.query(
      add_log,
      on: conn,
      with: [
        sqlight.text(namespace),
        sqlight.text(source),
        sqlight.text(level),
        sqlight.text(message),
      ],
      expecting: dynamic.decode4(
        Log,
        dynamic.element(0, dynamic.string),
        dynamic.element(1, dynamic.string),
        dynamic.element(2, dynamic.string),
        dynamic.element(3, dynamic.string),
      ),
    )

  case query {
    Ok([l]) -> Ok(l)
    _ -> Error(ConnectorError("Failed to add log."))
  }
}
