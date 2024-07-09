import gleam/bool
import gleam/dynamic
import gleam/result
import sqlight
import suburb/types.{
  type Namespace, type ServiceError, ConnectorError, Namespace,
  ResourceDoesNotExist,
}

const is_created_flag = "SELECT EXISTS(SELECT 1 FROM namespaces WHERE name = ?);"

const list_namespaces = "SELECT name FROM namespaces ORDER BY name;"

const add_namespace = "INSERT INTO namespaces (name) VALUES (?) RETURNING name;"

const delete_namespace = "DELETE FROM namespaces WHERE name = ?;"

pub fn list(conn: sqlight.Connection) -> Result(List(Namespace), ServiceError) {
  let query =
    sqlight.query(
      list_namespaces,
      on: conn,
      with: [],
      expecting: dynamic.decode1(Namespace, dynamic.element(0, dynamic.string)),
    )

  case query {
    Ok(namespaces) -> Ok(namespaces)
    _ -> Error(ConnectorError("Failed to list namespaces."))
  }
}

pub fn namespace_is_created(
  conn: sqlight.Connection,
  name: String,
) -> Result(Bool, ServiceError) {
  let query =
    sqlight.query(
      is_created_flag,
      on: conn,
      with: [sqlight.text(name)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok([1]) -> Ok(True)
    Ok([0]) -> Ok(False)
    _ -> Error(ConnectorError("Failed to check if namespace exists."))
  }
}

pub fn add(
  conn: sqlight.Connection,
  name: String,
) -> Result(Namespace, ServiceError) {
  let query =
    sqlight.query(
      add_namespace,
      on: conn,
      with: [sqlight.text(name)],
      expecting: dynamic.decode1(Namespace, dynamic.element(0, dynamic.string)),
    )

  case query {
    Ok([n]) -> Ok(n)
    _ -> Error(ConnectorError("Failed to create namespace."))
  }
}

pub fn delete(
  conn: sqlight.Connection,
  name: String,
) -> Result(Nil, ServiceError) {
  use exists <- result.try(namespace_is_created(conn, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> name <> " does not exist.")),
  )

  let query =
    sqlight.query(
      delete_namespace,
      on: conn,
      with: [sqlight.text(name)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(ConnectorError("Failed to delete namespace."))
  }
}
