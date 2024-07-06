import gleam/bool
import gleam/dynamic
import gleam/list
import gleam/result
import gleam/string
import sqlight
import suburb/types.{
  type Queue, type ServiceError, ConnectorError, Queue, ResourceDoesNotExist,
}

pub type QueueFilters {
  Namespace(String)
  QueueName(String)
}

const is_created_query = "SELECT EXISTS(SELECT 1 FROM queues WHERE queue = ? AND namespace = ?)"

const length_query = "
    SELECT COUNT(*)
    FROM queued_values qv
    JOIN queues q ON qv.queue_id = q.id
    WHERE q.queue = ?
      AND q.namespace = ?
      AND qv.consumed_at IS NULL
  "

const create_query = "
    INSERT INTO queues (queue, namespace)
    VALUES (?, ?)
  "

const push_query = "
    INSERT INTO queued_values (queue_id, content)
    SELECT q.id, ?
    FROM queues q
    WHERE q.queue = ?
      AND q.namespace = ?
  "

const pop_get_query = "
    SELECT qv.id, qv.content
    FROM queued_values qv
    JOIN queues q ON qv.queue_id = q.id
    WHERE q.queue = ?
      AND q.namespace = ?
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
    WHERE q.queue = ?
      AND q.namespace = ?
      AND qv.consumed_at IS NULL
    ORDER BY qv.id ASC
    LIMIT 1
  "

const delete_query = "
    DELETE FROM queues
    WHERE queue = ?
      AND namespace = ?
  "

pub fn list(
  conn: sqlight.Connection,
  filters: List(QueueFilters),
) -> Result(List(Queue), ServiceError) {
  let where_items =
    list.map(filters, fn(filter) {
      case filter {
        Namespace(_) -> "namespace = ?"
        QueueName(_) -> "queue = ?"
      }
    })

  let where_values =
    list.map(filters, fn(filter) {
      case filter {
        Namespace(value) -> sqlight.text(value)
        QueueName(value) -> sqlight.text(value)
      }
    })

  let where_clause = case list.length(where_items) {
    0 -> ""
    _ -> "WHERE " <> string.join(where_items, " AND ")
  }

  let sql =
    "SELECT namespace, queue FROM queues "
    <> where_clause
    <> " ORDER BY namespace, queue ASC"

  let query =
    sqlight.query(
      sql,
      on: conn,
      with: where_values,
      expecting: dynamic.tuple2(dynamic.string, dynamic.string),
    )

  use result <- result.try(result.replace_error(
    query,
    ConnectorError("Failed to list queues."),
  ))

  Ok(list.map(result, fn(row) { Queue(namespace: row.0, queue: row.1) }))
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

  use result <- result.try(result.replace_error(
    query,
    ConnectorError("Failed to check if queue exists."),
  ))

  case list.first(result) {
    Ok(1) -> Ok(True)
    Ok(0) -> Ok(False)
    _ -> Error(ConnectorError("Failed to check if queue exists."))
  }
}

pub fn length(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(Int, ServiceError) {
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

  use result <- result.try(result.replace_error(
    query,
    ConnectorError("Failed to get queue length."),
  ))

  Ok(result.unwrap(list.first(result), 0))
}

pub fn push(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
  value: String,
) -> Result(Nil, ServiceError) {
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
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(ConnectorError("Failed to push value to queue."))
  }
}

pub fn pop(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(String, ServiceError) {
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

  use result <- result.try(result.replace_error(
    get_query,
    ConnectorError("Failed to pop value from queue."),
  ))

  use #(id, content) <- result.try(result.replace_error(
    list.first(result),
    ConnectorError("Failed to pop value from queue."),
  ))

  let update_query =
    sqlight.query(
      pop_update_query,
      on: conn,
      with: [sqlight.int(id)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case update_query {
    Ok(_) -> Ok(content)
    Error(_) -> Error(ConnectorError("Failed to pop value from queue."))
  }
}

pub fn create(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(Nil, ServiceError) {
  use exists <- result.try(queue_is_created(conn, namespace, name))
  use <- bool.guard(
    exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " already exists.")),
  )

  let query =
    sqlight.query(
      create_query,
      on: conn,
      with: [sqlight.text(name), sqlight.text(namespace)],
      expecting: dynamic.element(0, dynamic.int),
    )

  case query {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(ConnectorError("Failed to create queue."))
  }
}

pub fn peek(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(String, ServiceError) {
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

  use result <- result.try(result.replace_error(
    query,
    ConnectorError("Failed to peek value from queue."),
  ))

  Ok(result.unwrap(list.first(result), ""))
}

pub fn delete(
  conn: sqlight.Connection,
  namespace: String,
  name: String,
) -> Result(Nil, ServiceError) {
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
