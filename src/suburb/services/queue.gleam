import gleam/bool
import gleam/dynamic
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import sqlight
import suburb/services/namespace.{namespace_is_created}
import suburb/types.{
  type Queue, type ServiceError, ConnectorError, EmptyQueue, Queue,
  ResourceAlreadyExists, ResourceDoesNotExist,
}

pub type QueueFilters {
  QueueName(String)
}

const is_created_query = "
    SELECT EXISTS(
        SELECT 1 
        FROM queues 
        JOIN namespaces ON queues.namespace_id = namespaces.id 
        WHERE queues.queue = ? AND namespaces.name = ?
    )
"

const length_query = "
    SELECT COUNT(*)
    FROM queued_values qv
    JOIN queues q ON qv.queue_id = q.id
    JOIN namespaces n ON q.namespace_id = n.id
    WHERE q.queue = ?
      AND n.name = ?
      AND qv.consumed_at IS NULL
  "

const create_query = "
    INSERT INTO queues (queue, namespace_id)
    VALUES (
        ?, (SELECT id FROM namespaces WHERE name = ?)
    )
    RETURNING queue
  "

const push_query = "
    INSERT INTO queued_values (queue_id, content)
    SELECT q.id, ?
    FROM queues q
    JOIN namespaces n ON q.namespace_id = n.id
    WHERE q.queue = ?
      AND n.name = ?
    RETURNING content
  "

const pop_get_query = "
    SELECT qv.id, qv.content
    FROM queued_values qv
    JOIN queues q ON qv.queue_id = q.id
    JOIN namespaces n ON q.namespace_id = n.id
    WHERE q.queue = ?
      AND n.name = ?
      AND qv.consumed_at IS NULL
    ORDER BY qv.id ASC
    LIMIT 1
  "

const pop_update_query = "
    UPDATE queued_values
    SET consumed_at = CURRENT_TIMESTAMP
    WHERE id = ?
  "

const peek_query = "
    SELECT qv.content
    FROM queued_values qv
    JOIN queues q ON qv.queue_id = q.id
    JOIN namespaces n ON q.namespace_id = n.id
    WHERE q.queue = ?
      AND n.name = ?
      AND qv.consumed_at IS NULL
    ORDER BY qv.id ASC
    LIMIT 1
  "

const delete_query = "
    DELETE FROM queues
    WHERE queue = ? AND namespace_id = (
        SELECT id FROM namespaces WHERE name = ?
    )
  "

pub fn list(
  conn: sqlight.Connection,
  namespace: String,
  filters: List(QueueFilters),
) -> Result(List(Queue), ServiceError) {
  use exists <- result.try(namespace_is_created(conn, namespace))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> namespace <> " does not exist.")),
  )

  let where_items =
    list.map(filters, fn(filter) {
      case filter {
        QueueName(v) -> #("q.queue = ?", sqlight.text(v))
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
    "SELECT q.queue FROM queues as q JOIN namespaces as n ON q.namespace_id = n.id "
    <> where_clause
    <> " ORDER BY q.queue ASC"

  let query =
    sqlight.query(
      sql,
      on: conn,
      with: where_values,
      expecting: dynamic.decode1(Queue, dynamic.element(0, dynamic.string)),
    )

  case query {
    Ok(result) -> Ok(result)
    Error(_) -> Error(ConnectorError("Failed to list queues."))
  }
}

fn queue_is_created(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(Bool, ServiceError) {
  let query =
    sqlight.query(
      is_created_query,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok([1]) -> Ok(True)
    Ok([0]) -> Ok(False)
    _ -> Error(ConnectorError("Failed to check if queue exists."))
  }
}

pub fn length(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(Int, ServiceError) {
  use exists <- result.try(namespace_is_created(conn, namespace))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> namespace <> " does not exist.")),
  )

  use exists <- result.try(queue_is_created(conn, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " does not exist.")),
  )

  let query =
    sqlight.query(
      length_query,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok([count]) -> Ok(count)
    _ -> Error(ConnectorError("Failed to get queue length."))
  }
}

pub fn push(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
  value: String,
) -> Result(String, ServiceError) {
  use exists <- result.try(namespace_is_created(conn, namespace))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> namespace <> " does not exist.")),
  )

  use exists <- result.try(queue_is_created(conn, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " does not exist.")),
  )

  let query =
    sqlight.query(
      push_query,
      on: conn,
      with: [sqlight.text(value), sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.element(0, dynamic.string),
    )

  case query {
    Ok(_) -> Ok(value)
    Error(_) -> Error(ConnectorError("Failed to push value to queue."))
  }
}

pub fn pop(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(String, ServiceError) {
  use exists <- result.try(namespace_is_created(conn, namespace))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> namespace <> " does not exist.")),
  )

  use exists <- result.try(queue_is_created(conn, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " does not exist.")),
  )

  let get_query =
    sqlight.query(
      pop_get_query,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.tuple2(dynamic.int, dynamic.string),
    )

  case get_query {
    Ok([]) -> Error(EmptyQueue("Queue " <> name <> " is empty."))
    Ok([#(id, content)]) -> {
      let update_query =
        sqlight.query(
          pop_update_query,
          on: conn,
          with: [sqlight.int(id)],
          expecting: dynamic.element(0, dynamic.int),
        )

      case update_query {
        Ok(_) -> Ok(content)
        _ -> Error(ConnectorError("Failed to pop value from queue."))
      }
    }
    _ -> Error(ConnectorError("Failed to find value to pop from the queue."))
  }
}

pub fn create(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(Queue, ServiceError) {
  use exists <- result.try(namespace_is_created(conn, namespace))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> namespace <> " does not exist.")),
  )

  use exists <- result.try(queue_is_created(conn, namespace, name))
  use <- bool.guard(
    exists,
    Error(ResourceAlreadyExists("Queue " <> name <> " already exists.")),
  )

  let query =
    sqlight.query(
      create_query,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.decode1(Queue, dynamic.element(0, dynamic.string)),
    )

  case query {
    Ok([q]) -> Ok(q)
    _ -> Error(ConnectorError("Failed to create queue."))
  }
}

pub fn peek(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(String, ServiceError) {
  use exists <- result.try(namespace_is_created(conn, namespace))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> namespace <> " does not exist.")),
  )

  use exists <- result.try(queue_is_created(conn, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " does not exist.")),
  )

  let query =
    sqlight.query(
      peek_query,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.element(0, dynamic.string),
    )

  case query {
    Ok([content]) -> Ok(content)
    Ok([]) -> Error(EmptyQueue("Queue " <> name <> " is empty."))
    _ -> Error(ConnectorError("Failed to peek value from queue."))
  }
}

pub fn delete(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(Nil, ServiceError) {
  use exists <- result.try(namespace_is_created(conn, namespace))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Namespace " <> namespace <> " does not exist.")),
  )

  use exists <- result.try(queue_is_created(conn, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " does not exist.")),
  )

  let query =
    sqlight.query(
      delete_query,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(ConnectorError("Failed to delete queue."))
  }
}
