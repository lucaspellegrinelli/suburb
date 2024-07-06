import gleam/dynamic
import gleam/json
import gleam/list
import gleam/string_builder
import gleeunit/should
import suburb/api/routes/log as log_route
import suburb/api/web.{Context}
import suburb/coders/log as log_coder
import suburb/db
import suburb/services/log as log_service
import wisp.{Text}
import wisp/testing

fn body_to_string(body: wisp.Body) {
  case body {
    Text(s) -> string_builder.to_string(s)
    _ -> ""
  }
}

pub fn log_list_empty_test() {
  use c <- db.db_connection(":memory:")
  let req = testing.get("", [])
  let res = log_route.list_route(req, Context(c, ""))
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(log_coder.decoder),
    ))
  decoded_body |> should.equal([])
}

pub fn log_add_test() {
  use c <- db.db_connection(":memory:")
  let body =
    json.object([
      #("source", json.string("src")),
      #("level", json.string("lvl")),
      #("message", json.string("msg")),
    ])
  let req = testing.post_json("", [], body)
  let res = log_route.add_route(req, Context(c, ""), "ns")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: log_coder.decoder))

  decoded_body.namespace |> should.equal("ns")
  decoded_body.source |> should.equal("src")
  decoded_body.level |> should.equal("lvl")
  decoded_body.message |> should.equal("msg")
}

pub fn log_list_with_logs_test() {
  use c <- db.db_connection(":memory:")
  let body =
    json.object([
      #("source", json.string("src")),
      #("level", json.string("lvl")),
      #("message", json.string("msg")),
    ])
  let req = testing.post_json("", [], body)
  log_route.add_route(req, Context(c, ""), "ns")

  case log_service.list(c, [], 100) {
    Ok([log]) -> {
      log.namespace |> should.equal("ns")
      log.source |> should.equal("src")
      log.level |> should.equal("lvl")
      log.message |> should.equal("msg")
    }
    _ -> should.fail()
  }
}

pub fn log_list_with_namespace_filter_test() {
  use c <- db.db_connection(":memory:")
  log_service.add(c, "ns1", "src", "lvl", "msg") |> should.be_ok()
  log_service.add(c, "ns2", "src", "lvl", "msg") |> should.be_ok()

  let req = testing.get("?namespace=ns1", [])
  let res = log_route.list_route(req, Context(c, ""))
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(log_coder.decoder),
    ))

  case decoded_body {
    [log] -> {
      log.namespace |> should.equal("ns1")
      log.source |> should.equal("src")
      log.level |> should.equal("lvl")
      log.message |> should.equal("msg")
    }
    _ -> should.fail()
  }
}

pub fn log_list_with_source_filter_test() {
  use c <- db.db_connection(":memory:")
  log_service.add(c, "ns", "src1", "lvl", "msg") |> should.be_ok()
  log_service.add(c, "ns", "src2", "lvl", "msg") |> should.be_ok()

  let req = testing.get("?source=src1", [])
  let res = log_route.list_route(req, Context(c, ""))
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(log_coder.decoder),
    ))

  case decoded_body {
    [log] -> {
      log.namespace |> should.equal("ns")
      log.source |> should.equal("src1")
      log.level |> should.equal("lvl")
      log.message |> should.equal("msg")
    }
    _ -> should.fail()
  }
}

pub fn log_list_with_level_filter_test() {
  use c <- db.db_connection(":memory:")
  log_service.add(c, "ns", "src", "lvl1", "msg") |> should.be_ok()
  log_service.add(c, "ns", "src", "lvl2", "msg") |> should.be_ok()

  let req = testing.get("?level=lvl1", [])
  let res = log_route.list_route(req, Context(c, ""))
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(log_coder.decoder),
    ))

  case decoded_body {
    [log] -> {
      log.namespace |> should.equal("ns")
      log.source |> should.equal("src")
      log.level |> should.equal("lvl1")
      log.message |> should.equal("msg")
    }
    _ -> should.fail()
  }
}

pub fn log_list_with_multiple_filter_test() {
  use c <- db.db_connection(":memory:")
  log_service.add(c, "ns1", "src1", "lvl1", "msg") |> should.be_ok()
  log_service.add(c, "ns1", "src2", "lvl1", "msg") |> should.be_ok()
  log_service.add(c, "ns2", "src1", "lvl1", "msg") |> should.be_ok()
  log_service.add(c, "ns2", "src2", "lvl1", "msg") |> should.be_ok()
  log_service.add(c, "ns1", "src1", "lvl2", "msg") |> should.be_ok()
  log_service.add(c, "ns1", "src2", "lvl2", "msg") |> should.be_ok()
  log_service.add(c, "ns2", "src1", "lvl2", "msg") |> should.be_ok()
  log_service.add(c, "ns2", "src2", "lvl2", "msg") |> should.be_ok()

  let req = testing.get("?namespace=ns1&source=src1&level=lvl1", [])
  let res = log_route.list_route(req, Context(c, ""))
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(log_coder.decoder),
    ))

  case decoded_body {
    [log] -> {
      log.namespace |> should.equal("ns1")
      log.source |> should.equal("src1")
      log.level |> should.equal("lvl1")
      log.message |> should.equal("msg")
    }
    _ -> should.fail()
  }
}

pub fn log_list_with_limit_test() {
  use c <- db.db_connection(":memory:")
  list.range(0, 20)
  |> list.each(fn(_) {
    log_service.add(c, "ns", "src", "lvl", "msg") |> should.be_ok()
  })

  let req = testing.get("?limit=10", [])
  let res = log_route.list_route(req, Context(c, ""))
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(log_coder.decoder),
    ))

  decoded_body |> list.length |> should.equal(10)
}
