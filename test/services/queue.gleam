import gleeunit/should
import suburb/db
import suburb/services/queue.{Namespace, QueueName}
import suburb/types.{EmptyQueue, ResourceAlreadyExists, ResourceDoesNotExist}

pub fn queue_empty_test() {
  use conn <- db.db_connection(":memory:")
  queue.list(conn, []) |> should.equal(Ok([]))
}

pub fn queue_create_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue") |> should.equal(Ok(Nil))
  case queue.list(conn, []) {
    Ok([q]) -> {
      q.namespace |> should.equal("ns")
      q.queue |> should.equal("queue")
    }
    _ -> should.fail()
  }
}

pub fn queue_create_duplicate_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue") |> should.equal(Ok(Nil))
  queue.create(conn, "ns", "queue")
  |> should.equal(Error(ResourceAlreadyExists("Queue queue already exists.")))
}

pub fn queue_push_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue") |> should.equal(Ok(Nil))
  queue.push(conn, "ns", "queue", "item") |> should.equal(Ok(Nil))
  case queue.list(conn, []) {
    Ok([q]) -> {
      q.namespace |> should.equal("ns")
      q.queue |> should.equal("queue")
    }
    _ -> should.fail()
  }
}

pub fn queue_push_to_non_existent_test() {
  use conn <- db.db_connection(":memory:")
  queue.push(conn, "ns", "queue", "item")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_pop_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue") |> should.equal(Ok(Nil))
  queue.push(conn, "ns", "queue", "item") |> should.equal(Ok(Nil))
  queue.pop(conn, "ns", "queue") |> should.equal(Ok("item"))
  queue.length(conn, "ns", "queue") |> should.equal(Ok(0))
}

pub fn queue_pop_from_non_existent_test() {
  use conn <- db.db_connection(":memory:")
  queue.pop(conn, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_pop_from_empty_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue") |> should.equal(Ok(Nil))
  queue.pop(conn, "ns", "queue")
  |> should.equal(Error(EmptyQueue("Queue queue is empty.")))
}

pub fn queue_peek_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue") |> should.equal(Ok(Nil))
  queue.push(conn, "ns", "queue", "item") |> should.equal(Ok(Nil))
  queue.peek(conn, "ns", "queue") |> should.equal(Ok("item"))
  queue.length(conn, "ns", "queue") |> should.equal(Ok(1))
}

pub fn queue_peek_from_non_existent_test() {
  use conn <- db.db_connection(":memory:")
  queue.peek(conn, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_peek_from_empty_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue") |> should.equal(Ok(Nil))
  queue.peek(conn, "ns", "queue")
  |> should.equal(Error(EmptyQueue("Queue queue is empty.")))
}

pub fn queue_length_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue") |> should.equal(Ok(Nil))
  queue.length(conn, "ns", "queue") |> should.equal(Ok(0))
  queue.push(conn, "ns", "queue", "item") |> should.equal(Ok(Nil))
  queue.length(conn, "ns", "queue") |> should.equal(Ok(1))
  queue.pop(conn, "ns", "queue") |> should.equal(Ok("item"))
  queue.length(conn, "ns", "queue") |> should.equal(Ok(0))
}

pub fn queue_length_of_non_existent_test() {
  use conn <- db.db_connection(":memory:")
  queue.length(conn, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_delete_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue") |> should.equal(Ok(Nil))
  queue.push(conn, "ns", "queue", "item") |> should.equal(Ok(Nil))
  queue.delete(conn, "ns", "queue") |> should.equal(Ok(Nil))
  queue.list(conn, []) |> should.equal(Ok([]))
}

pub fn queue_delete_non_existent_test() {
  use conn <- db.db_connection(":memory:")
  queue.delete(conn, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_namespace_filter_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns1", "queue") |> should.equal(Ok(Nil))
  queue.create(conn, "ns2", "queue") |> should.equal(Ok(Nil))
  case queue.list(conn, [Namespace("ns1")]) {
    Ok([q]) -> q.namespace |> should.equal("ns1")
    _ -> should.fail()
  }
}

pub fn queue_name_filter_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns", "queue1") |> should.equal(Ok(Nil))
  queue.create(conn, "ns", "queue2") |> should.equal(Ok(Nil))
  case queue.list(conn, [QueueName("queue1")]) {
    Ok([q]) -> q.queue |> should.equal("queue1")
    _ -> should.fail()
  }
}

pub fn queue_multiple_filter_test() {
  use conn <- db.db_connection(":memory:")
  queue.create(conn, "ns1", "queue1") |> should.equal(Ok(Nil))
  queue.create(conn, "ns1", "queue2") |> should.equal(Ok(Nil))
  queue.create(conn, "ns2", "queue1") |> should.equal(Ok(Nil))
  queue.create(conn, "ns2", "queue2") |> should.equal(Ok(Nil))
  case queue.list(conn, [Namespace("ns1"), QueueName("queue1")]) {
    Ok([q]) -> {
      q.namespace |> should.equal("ns1")
      q.queue |> should.equal("queue1")
    }
    _ -> should.fail()
  }
}
