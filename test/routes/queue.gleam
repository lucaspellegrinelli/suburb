import gleam/dynamic
import gleam/json
import gleam/string_builder
import gleeunit/should
import suburb/api/routes/queue as queue_route
import suburb/api/web.{Context}
import suburb/coders/queue as queue_coder
import suburb/db
import suburb/services/namespace as namespace_service
import suburb/services/queue as queue_service
import wisp.{Text}
import wisp/testing

fn body_to_string(body: wisp.Body) {
  case body {
    Text(s) -> string_builder.to_string(s)
    _ -> ""
  }
}

pub fn queue_list_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let req = testing.get("", [])
  let res = queue_route.list_route(req, Context(c, ""), "ns")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(queue_coder.decoder),
    ))
  decoded_body |> should.equal([])
}

pub fn queue_create_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let body = json.object([#("queue", json.string("queue"))])
  let req = testing.post_json("", [], body)
  let res = queue_route.create_route(req, Context(c, ""), "ns")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: queue_coder.decoder))

  decoded_body.queue |> should.equal("queue")
}

pub fn queue_create_duplicate_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue_service.create(c, "ns", "queue") |> should.be_ok()
  let body =
    json.object([
      #("namespace", json.string("ns")),
      #("queue", json.string("queue")),
    ])
  let req = testing.post_json("", [], body)
  let res = queue_route.create_route(req, Context(c, ""), "ns")
  res.status |> should.equal(404)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Queue queue already exists.")
}

pub fn queue_push_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue_service.create(c, "ns", "queue") |> should.be_ok()
  let body = json.object([#("message", json.string("msg"))])
  let req = testing.post_json("", [], body)
  let res = queue_route.push_route(req, Context(c, ""), "ns", "queue")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("msg")
}

pub fn queue_push_to_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let body = json.object([#("message", json.string("msg"))])
  let req = testing.post_json("", [], body)
  let res = queue_route.push_route(req, Context(c, ""), "ns", "queue")
  res.status |> should.equal(404)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Queue queue does not exist.")
}

pub fn queue_pop_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue_service.create(c, "ns", "queue") |> should.be_ok()
  queue_service.push(c, "ns", "queue", "msg") |> should.be_ok()

  let req = testing.post("", [], "")
  let res = queue_route.pop_route(req, Context(c, ""), "ns", "queue")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("msg")
  queue_service.length(c, "ns", "queue") |> should.equal(Ok(0))
}

pub fn queue_pop_from_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let req = testing.post("", [], "")
  let res = queue_route.pop_route(req, Context(c, ""), "ns", "queue")
  res.status |> should.equal(404)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Queue queue does not exist.")
}

pub fn queue_pop_from_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue_service.create(c, "ns", "queue") |> should.be_ok()
  let req = testing.post("", [], "")
  let res = queue_route.pop_route(req, Context(c, ""), "ns", "queue")
  res.status |> should.equal(204)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Queue queue is empty.")
}

pub fn queue_peek_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue_service.create(c, "ns", "queue") |> should.be_ok()
  queue_service.push(c, "ns", "queue", "msg") |> should.be_ok()

  let req = testing.get("", [])
  let res = queue_route.peek_route(req, Context(c, ""), "ns", "queue")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("msg")
  queue_service.length(c, "ns", "queue") |> should.equal(Ok(1))
}

pub fn queue_peek_from_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let req = testing.get("", [])
  let res = queue_route.peek_route(req, Context(c, ""), "ns", "queue")
  res.status |> should.equal(404)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Queue queue does not exist.")
}

pub fn queue_peek_from_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue_service.create(c, "ns", "queue") |> should.be_ok()
  let req = testing.get("", [])
  let res = queue_route.peek_route(req, Context(c, ""), "ns", "queue")
  res.status |> should.equal(204)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Queue queue is empty.")
}

pub fn queue_length_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue_service.create(c, "ns", "queue") |> should.be_ok()
  queue_service.push(c, "ns", "queue", "msg1") |> should.be_ok()
  queue_service.push(c, "ns", "queue", "msg2") |> should.be_ok()

  let req = testing.get("", [])
  let res = queue_route.length_route(req, Context(c, ""), "ns", "queue")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.int))

  decoded_body |> should.equal(2)
}

pub fn queue_length_of_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let req = testing.get("", [])
  let res = queue_route.length_route(req, Context(c, ""), "ns", "queue")
  res.status |> should.equal(404)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Queue queue does not exist.")
}

pub fn queue_delete_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue_service.create(c, "ns", "queue") |> should.be_ok()
  queue_service.push(c, "ns", "queue", "msg") |> should.be_ok()

  let req = testing.delete("", [], "")
  let res = queue_route.delete_route(req, Context(c, ""), "ns", "queue")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Queue queue deleted.")
  queue_service.list(c, "ns", []) |> should.equal(Ok([]))
}

pub fn queue_delete_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let req = testing.delete("", [], "")
  let res = queue_route.delete_route(req, Context(c, ""), "ns", "queue")
  res.status |> should.equal(404)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Queue queue does not exist.")
}

pub fn queue_namespace_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  queue_service.create(c, "ns1", "queue") |> should.be_ok()
  queue_service.create(c, "ns2", "queue") |> should.be_ok()

  let req = testing.get("", [])
  let res = queue_route.list_route(req, Context(c, ""), "ns1")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(queue_coder.decoder),
    ))

  case decoded_body {
    [queue] -> {
      queue.queue |> should.equal("queue")
    }
    _ -> should.fail()
  }
}

pub fn queue_name_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  queue_service.create(c, "ns", "queue1") |> should.be_ok()
  queue_service.create(c, "ns", "queue2") |> should.be_ok()

  let req = testing.get("?queue=queue1", [])
  let res = queue_route.list_route(req, Context(c, ""), "ns")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(queue_coder.decoder),
    ))

  case decoded_body {
    [queue] -> {
      queue.queue |> should.equal("queue1")
    }
    _ -> should.fail()
  }
}

pub fn queue_multiple_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  queue_service.create(c, "ns1", "queue1") |> should.be_ok()
  queue_service.create(c, "ns1", "queue2") |> should.be_ok()
  queue_service.create(c, "ns2", "queue1") |> should.be_ok()
  queue_service.create(c, "ns2", "queue2") |> should.be_ok()

  let req = testing.get("?queue=queue1", [])
  let res = queue_route.list_route(req, Context(c, ""), "ns1")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(queue_coder.decoder),
    ))

  case decoded_body {
    [queue] -> {
      queue.queue |> should.equal("queue1")
    }
    _ -> should.fail()
  }
}
