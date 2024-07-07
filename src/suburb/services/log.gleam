import gleam/dynamic
import gleam/list
import gleam/result
import gleam/string
import sqlight
import suburb/types.{type Log, type ServiceError, ConnectorError, Log}

pub type LogFilters {
  Namespace(String)
  Source(String)
  Level(String)
  FromTime(String)
  UntilTime(String)
}

const add_log = "
  INSERT INTO logs (namespace, source, level, message)
  VALUES (?, ?, ?, ?)
  RETURNING namespace, source, level, message, created_at;
"

pub fn list(
  conn: sqlight.Connection,
  filters: List(LogFilters),
  limit: Int,
) -> Result(List(Log), ServiceError) {
  let where_items =
    list.map(filters, fn(filter) {
      case filter {
        Namespace(_) -> "namespace = ?"
        Source(_) -> "source = ?"
        Level(_) -> "level = ?"
        FromTime(_) -> "created_at >= ?"
        UntilTime(_) -> "created_at <= ?"
      }
    })

  let where_values =
    list.map(filters, fn(filter) {
      case filter {
        Namespace(value) -> sqlight.text(value)
        Source(value) -> sqlight.text(value)
        Level(value) -> sqlight.text(value)
        FromTime(value) -> sqlight.text(value)
        UntilTime(value) -> sqlight.text(value)
      }
    })

  let where_clause = case list.length(where_items) {
    0 -> ""
    _ -> "WHERE " <> string.join(where_items, " AND ")
  }

  let sql =
    "SELECT namespace, source, level, message, created_at FROM logs "
    <> where_clause
    <> " ORDER BY created_at DESC LIMIT ?"

  let vars = list.concat([where_values, [sqlight.int(limit)]])

  let query =
    sqlight.query(
      sql,
      on: conn,
      with: vars,
      expecting: dynamic.decode5(
        Log,
        dynamic.element(0, dynamic.string),
        dynamic.element(1, dynamic.string),
        dynamic.element(2, dynamic.string),
        dynamic.element(3, dynamic.string),
        dynamic.element(4, dynamic.string),
      ),
    )

  use result <- result.try(result.replace_error(
    query,
    ConnectorError("Failed to list logs."),
  ))

  Ok(result)
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
      expecting: dynamic.decode5(
        Log,
        dynamic.element(0, dynamic.string),
        dynamic.element(1, dynamic.string),
        dynamic.element(2, dynamic.string),
        dynamic.element(3, dynamic.string),
        dynamic.element(4, dynamic.string),
      ),
    )

  case query {
    Ok([l]) -> Ok(l)
    _ -> Error(ConnectorError("Failed to add log."))
  }
}
