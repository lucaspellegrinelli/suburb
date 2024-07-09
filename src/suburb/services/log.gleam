import gleam/bool
import gleam/dynamic
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import sqlight
import suburb/services/namespace.{namespace_is_created}
import suburb/types.{
  type Log, type ServiceError, ConnectorError, Log, ResourceDoesNotExist,
}

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
  use exists <- result.try(namespace_is_created(conn, namespace))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> namespace <> " does not exist.")),
  )

  let where_items =
    list.map(filters, fn(filter) {
      case filter {
        Source(v) -> #("l.source = ?", sqlight.text(v))
        Level(v) -> #("l.level = ?", sqlight.text(v))
        FromTime(v) -> #("l.created_at >= ?", sqlight.text(v))
        UntilTime(v) -> #("l.created_at <= ?", sqlight.text(v))
      }
    })
    |> list.append([#("n.name = ?", sqlight.text(namespace))])

  let where_keys = list.map(where_items, pair.first)
  let where_values = list.map(where_items, pair.second)

  let where_clause = case list.length(where_items) {
    0 -> ""
    _ -> "WHERE " <> string.join(where_keys, " AND ")
  }

  let sql =
    "SELECT l.source, l.level, l.message, l.created_at FROM logs as l JOIN namespaces as n ON l.namespace_id = n.id "
    <> where_clause
    <> " ORDER BY l.created_at DESC LIMIT ?"

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
  use exists <- result.try(namespace_is_created(conn, namespace))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> namespace <> " does not exist.")),
  )

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
