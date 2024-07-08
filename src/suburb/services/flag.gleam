import gleam/bool
import gleam/dynamic
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import sqlight
import suburb/coders/flag.{str_to_bool}
import suburb/types.{
  type FeatureFlag, type ServiceError, ConnectorError, FeatureFlag,
  ResourceDoesNotExist,
}

pub type FlagFilters {
  Namespace(String)
  Flag(String)
}

const is_created_flag = "SELECT EXISTS(SELECT 1 FROM feature_flags WHERE flag = ? AND namespace = ?)"

const delete_flag = "DELETE FROM feature_flags WHERE flag = ? AND namespace = ?"

const set_flag = "
    INSERT INTO feature_flags (namespace, flag, value)
    VALUES (?, ?, ?)
    ON CONFLICT(flag, namespace)
    DO UPDATE SET value = excluded.value;
  "

const get_flag = "SELECT namespace, flag, value FROM feature_flags WHERE flag = ? AND namespace = ?"

pub fn list(
  conn: sqlight.Connection,
  filters: List(FlagFilters),
) -> Result(List(FeatureFlag), ServiceError) {
  let where_items =
    list.map(filters, fn(filter) {
      case filter {
        Namespace(v) -> #("namespace = ?", sqlight.text(v))
        Flag(v) -> #("flag = ?", sqlight.text(v))
      }
    })

  let where_keys = list.map(where_items, pair.first)
  let where_values = list.map(where_items, pair.second)

  let where_clause = case list.length(where_items) {
    0 -> ""
    _ -> "WHERE " <> string.join(where_keys, " AND ")
  }

  let sql =
    "SELECT namespace, flag, value FROM feature_flags "
    <> where_clause
    <> " ORDER BY namespace, flag ASC"

  let query =
    sqlight.query(
      sql,
      on: conn,
      with: where_values,
      expecting: dynamic.decode3(
        FeatureFlag,
        dynamic.element(0, dynamic.string),
        dynamic.element(1, dynamic.string),
        dynamic.element(2, str_to_bool),
      ),
    )

  case query {
    Ok(flags) -> Ok(flags)
    Error(_) -> Error(ConnectorError("Failed to list feature flags."))
  }
}

fn flag_is_created(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(Bool, ServiceError) {
  let query =
    sqlight.query(
      is_created_flag,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok([1]) -> Ok(True)
    Ok([0]) -> Ok(False)
    _ -> Error(ConnectorError("Failed to check if feature flag exists."))
  }
}

pub fn set(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
  value: Bool,
) -> Result(FeatureFlag, ServiceError) {
  let query =
    sqlight.query(
      set_flag,
      on: conn,
      with: [
        sqlight.text(namespace),
        sqlight.text(name),
        sqlight.text(bool.to_string(value)),
      ],
      expecting: dynamic.decode3(
        FeatureFlag,
        dynamic.element(0, dynamic.string),
        dynamic.element(1, dynamic.string),
        dynamic.element(2, str_to_bool),
      ),
    )

  case query {
    Ok([f]) -> Ok(f)
    Ok([]) -> Ok(FeatureFlag(namespace, name, value))
    _ -> Error(ConnectorError("Failed to set feature flag."))
  }
}

pub fn get(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(FeatureFlag, ServiceError) {
  use exists <- result.try(flag_is_created(conn, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Feature Flag " <> name <> " does not exist.")),
  )

  let query =
    sqlight.query(
      get_flag,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.decode3(
        FeatureFlag,
        dynamic.element(0, dynamic.string),
        dynamic.element(1, dynamic.string),
        dynamic.element(2, str_to_bool),
      ),
    )

  case query {
    Ok([f]) -> Ok(f)
    _ -> Error(ConnectorError("Failed to get feature flag."))
  }
}

pub fn delete(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(Nil, ServiceError) {
  use exists <- result.try(flag_is_created(conn, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Feature Flag " <> name <> " does not exist.")),
  )

  let query =
    sqlight.query(
      delete_flag,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(ConnectorError("Failed to delete feature flag."))
  }
}
