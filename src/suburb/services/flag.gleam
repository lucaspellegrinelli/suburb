import gleam/bool
import gleam/dynamic
import gleam/list
import gleam/result
import sqlight
import suburb/types.{
  type FeatureFlag, type ServiceError, ConnectorError, FeatureFlag,
  ResourceDoesNotExist,
}

const list_flags = "SELECT namespace, flag, value FROM feature_flags WHERE namespace = ?"

const is_created_flag = "SELECT EXISTS(SELECT 1 FROM feature_flags WHERE flag = ? AND namespace = ?)"

const delete_flag = "DELETE FROM feature_flags WHERE flag = ? AND namespace = ?"

const set_flag = "
    INSERT INTO feature_flags (namespace, flag, value)
    VALUES (?, ?, ?)
    ON CONFLICT(flag, namespace)
    DO UPDATE SET value = excluded.value;
  "

const get_flag = "SELECT value FROM feature_flags WHERE flag = ? AND namespace = ?"

pub fn list(
  conn: sqlight.Connection,
  namespace: String,
) -> Result(List(FeatureFlag), ServiceError) {
  let query =
    sqlight.query(
      list_flags,
      on: conn,
      with: [sqlight.text(namespace)],
      expecting: dynamic.tuple3(dynamic.string, dynamic.string, dynamic.string),
    )

  use result <- result.try(result.replace_error(
    query,
    ConnectorError("Failed to list feature flags."),
  ))

  Ok(
    list.map(result, fn(row) {
      FeatureFlag(namespace: row.0, flag: row.1, value: row.2)
    }),
  )
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

  use result <- result.try(result.replace_error(
    query,
    ConnectorError("Failed to check if feature flag exists."),
  ))

  case list.first(result) {
    Ok(1) -> Ok(True)
    Ok(0) -> Ok(False)
    _ -> Error(ConnectorError("Failed to check if feature flag exists."))
  }
}

pub fn set(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
  value: String,
) -> Result(Nil, ServiceError) {
  let query =
    sqlight.query(
      set_flag,
      on: conn,
      with: [sqlight.text(namespace), sqlight.text(name), sqlight.text(value)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(ConnectorError("Failed to set feature flag."))
  }
}

pub fn get(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(String, ServiceError) {
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
      expecting: dynamic.element(0, dynamic.string),
    )

  use result <- result.try(result.replace_error(
    query,
    ConnectorError("Failed to get feature flag."),
  ))

  Ok(result.unwrap(list.first(result), ""))
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
