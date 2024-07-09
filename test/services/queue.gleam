import gleeunit/should
import suburb/db
import suburb/services/namespace as namespace_service
import suburb/services/queue.{QueueName}
import suburb/types.{
  EmptyQueue, Queue, ResourceAlreadyExists, ResourceDoesNotExist,
}

pub fn queue_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.list(c, "ns", []) |> should.equal(Ok([]))
}

pub fn queue_list_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  queue.list(c, "ns", [])
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn queue_create_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue") |> should.equal(Ok(Queue("queue")))
  case queue.list(c, "ns", []) {
    Ok([q]) -> {
      q.queue |> should.equal("queue")
    }
    _ -> should.fail()
  }
}

pub fn queue_create_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  queue.create(c, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn queue_create_duplicate_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue") |> should.be_ok()
  queue.create(c, "ns", "queue")
  |> should.equal(Error(ResourceAlreadyExists("Queue queue already exists.")))
}

pub fn queue_push_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue") |> should.be_ok()
  queue.push(c, "ns", "queue", "item") |> should.equal(Ok("item"))
  case queue.list(c, "ns", []) {
    Ok([q]) -> {
      q.queue |> should.equal("queue")
    }
    _ -> should.fail()
  }
}

pub fn queue_push_to_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  queue.push(c, "ns", "queue", "item")
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn queue_push_to_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.push(c, "ns", "queue", "item")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_pop_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue") |> should.be_ok()
  queue.push(c, "ns", "queue", "item") |> should.be_ok()
  queue.pop(c, "ns", "queue") |> should.equal(Ok("item"))
  queue.length(c, "ns", "queue") |> should.equal(Ok(0))
}

pub fn queue_pop_from_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  queue.pop(c, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn queue_pop_from_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.pop(c, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_pop_from_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue") |> should.be_ok()
  queue.pop(c, "ns", "queue")
  |> should.equal(Error(EmptyQueue("Queue queue is empty.")))
}

pub fn queue_peek_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue") |> should.be_ok()
  queue.push(c, "ns", "queue", "item") |> should.be_ok()
  queue.peek(c, "ns", "queue") |> should.equal(Ok("item"))
  queue.length(c, "ns", "queue") |> should.equal(Ok(1))
}

pub fn queue_peek_from_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  queue.peek(c, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn queue_peek_from_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.peek(c, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_peek_from_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue") |> should.be_ok()
  queue.peek(c, "ns", "queue")
  |> should.equal(Error(EmptyQueue("Queue queue is empty.")))
}

pub fn queue_length_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue") |> should.be_ok()
  queue.length(c, "ns", "queue") |> should.equal(Ok(0))
  queue.push(c, "ns", "queue", "item") |> should.be_ok()
  queue.length(c, "ns", "queue") |> should.equal(Ok(1))
  queue.pop(c, "ns", "queue") |> should.equal(Ok("item"))
  queue.length(c, "ns", "queue") |> should.equal(Ok(0))
}

pub fn queue_length_of_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  queue.length(c, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn queue_length_of_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.length(c, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_delete_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue") |> should.be_ok()
  queue.push(c, "ns", "queue", "item") |> should.be_ok()
  queue.delete(c, "ns", "queue") |> should.equal(Ok(Nil))
  queue.list(c, "ns", []) |> should.equal(Ok([]))
}

pub fn queue_delete_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  queue.delete(c, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn queue_delete_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.delete(c, "ns", "queue")
  |> should.equal(Error(ResourceDoesNotExist("Queue queue does not exist.")))
}

pub fn queue_namespace_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  queue.create(c, "ns1", "queue1") |> should.be_ok()
  queue.create(c, "ns2", "queue2") |> should.be_ok()
  case queue.list(c, "ns1", []) {
    Ok([q]) -> q.queue |> should.equal("queue1")
    _ -> should.fail()
  }
}

pub fn queue_name_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue.create(c, "ns", "queue1") |> should.be_ok()
  queue.create(c, "ns", "queue2") |> should.be_ok()
  case queue.list(c, "ns", [QueueName("queue1")]) {
    Ok([q]) -> q.queue |> should.equal("queue1")
    _ -> should.fail()
  }
}

pub fn queue_multiple_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  queue.create(c, "ns1", "queue1") |> should.be_ok()
  queue.create(c, "ns1", "queue2") |> should.be_ok()
  queue.create(c, "ns2", "queue1") |> should.be_ok()
  queue.create(c, "ns2", "queue2") |> should.be_ok()
  case queue.list(c, "ns1", [QueueName("queue1")]) {
    Ok([q]) -> {
      q.queue |> should.equal("queue1")
    }
    _ -> should.fail()
  }
}
