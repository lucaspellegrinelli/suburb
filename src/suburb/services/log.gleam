import gleam/dynamic
import gleam/list
import gleam/result
import gleam/string
import sqlight
import suburb/common.{type ServiceError, ConnectorError}

pub type Log {
  Log(
    namespace: String,
    source: String,
    level: String,
    message: String,
    created_at: String,
  )
}

pub type LogFilters {
  Source(String)
  Level(String)
  FromTime(String)
  UntilTime(String)
}

const add_log = "
  INSERT INTO logs (namespace, source, level, message)
  VALUES (?, ?, ?, ?)
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
        Source(_) -> "source = ?"
        Level(_) -> "level = ?"
        FromTime(_) -> "created_at >= ?"
        UntilTime(_) -> "created_at <= ?"
      }
    })

  let where_values =
    list.map(filters, fn(filter) {
      case filter {
        Source(value) -> sqlight.text(value)
        Level(value) -> sqlight.text(value)
        FromTime(value) -> sqlight.text(value)
        UntilTime(value) -> sqlight.text(value)
      }
    })

  let where_items = list.append(where_items, ["namespace = ?"])
  let where_clause = string.join(where_items, " AND ")

  let sql =
    "SELECT namespace, source, level, message, created_at FROM logs WHERE "
    <> where_clause
    <> " ORDER BY created_at DESC LIMIT ?"

  let vars =
    list.concat([[sqlight.text(namespace)], where_values, [sqlight.int(limit)]])

  let query =
    sqlight.query(
      sql,
      on: conn,
      with: vars,
      expecting: dynamic.tuple5(
        dynamic.string,
        dynamic.string,
        dynamic.string,
        dynamic.string,
        dynamic.string,
      ),
    )

  use result <- result.try(result.replace_error(
    query,
    ConnectorError("Failed to list logs."),
  ))

  Ok(
    list.map(result, fn(row) {
      Log(
        namespace: row.0,
        source: row.1,
        level: row.2,
        message: row.3,
        created_at: row.4,
      )
    }),
  )
}

pub fn add(
  conn: sqlight.Connection,
  namespace: String,
  source: String,
  level: String,
  message: String,
) -> Result(Nil, ServiceError) {
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
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(ConnectorError("Failed to add log."))
  }
}
