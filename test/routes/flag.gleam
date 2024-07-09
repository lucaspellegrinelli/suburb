import gleam/io
import gleam/dynamic
import gleam/json
import gleam/string_builder
import gleeunit/should
import suburb/api/routes/flag as flag_route
import suburb/api/web.{Context}
import suburb/coders/flag as flag_coder
import suburb/db
import suburb/services/flag as flag_service
import suburb/services/namespace as namespace_service
import wisp.{Text}
import wisp/testing

fn body_to_string(body: wisp.Body) {
  case body {
    Text(s) -> string_builder.to_string(s)
    _ -> ""
  }
}

pub fn flag_list_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let req = testing.get("", [])
  let res = flag_route.list_route(req, Context(c, ""), "ns")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(flag_coder.decoder),
    ))
  decoded_body |> should.equal([])
}

pub fn flag_set_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let body = json.object([#("value", json.bool(True))])
  let req = testing.post_json("", [], body)
  let res = flag_route.set_route(req, Context(c, ""), "ns", "flag")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: flag_coder.decoder))
  decoded_body.flag |> should.equal("flag")
  decoded_body.value |> should.equal(True)
}

pub fn flag_get_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag_service.set(c, "ns", "flag", True) |> should.be_ok()
  let req = testing.get("", [])
  let res = flag_route.get_route(req, Context(c, ""), "ns", "flag")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: flag_coder.decoder))

  decoded_body.flag |> should.equal("flag")
  decoded_body.value |> should.equal(True)
}

pub fn flag_get_from_non_existent_flag_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let req = testing.get("", [])
  let res = flag_route.get_route(req, Context(c, ""), "ns", "flag")
  res.status |> should.equal(404)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Feature Flag flag does not exist.")
}

pub fn flag_override_value_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag_service.set(c, "ns", "flag", False) |> should.be_ok()
  let body = json.object([#("value", json.bool(True))])
  let req = testing.post_json("", [], body)
  let res = flag_route.set_route(req, Context(c, ""), "ns", "flag")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: flag_coder.decoder))

  decoded_body.flag |> should.equal("flag")
  decoded_body.value |> should.equal(True)
}

pub fn flag_delete_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag_service.set(c, "ns", "flag", True) |> should.be_ok()
  let req = testing.delete("", [], "")
  let res = flag_route.delete_route(req, Context(c, ""), "ns", "flag")
  res.status |> should.equal(200)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Feature Flag flag has been deleted.")
}

pub fn flag_namespace_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  flag_service.set(c, "ns1", "flag1", True) |> should.be_ok()
  flag_service.set(c, "ns2", "flag2", True) |> should.be_ok()
  let req = testing.get("?namespace=ns1", [])
  let res = flag_route.list_route(req, Context(c, ""), "ns1")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(flag_coder.decoder),
    ))

  case decoded_body {
    [flag] -> {
      flag.flag |> should.equal("flag1")
      flag.value |> should.equal(True)
    }
    _ -> should.fail()
  }
}

pub fn flag_name_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag_service.set(c, "ns", "flag1", True) |> should.be_ok()
  flag_service.set(c, "ns", "flag2", True) |> should.be_ok()
  let req = testing.get("?flag=flag1", [])
  let res = flag_route.list_route(req, Context(c, ""), "ns")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(flag_coder.decoder),
    ))

  case decoded_body {
    [flag] -> {
      flag.flag |> should.equal("flag1")
      flag.value |> should.equal(True)
    }
    _ -> should.fail()
  }
}

pub fn flag_multiple_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  flag_service.set(c, "ns1", "flag1", True) |> should.be_ok()
  flag_service.set(c, "ns1", "flag2", True) |> should.be_ok()
  flag_service.set(c, "ns2", "flag3", True) |> should.be_ok()
  flag_service.set(c, "ns2", "flag4", True) |> should.be_ok()
  let req = testing.get("?flag=flag1", [])
  let res = flag_route.list_route(req, Context(c, ""), "ns1")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(flag_coder.decoder),
    ))

  case decoded_body {
    [flag] -> {
      flag.flag |> should.equal("flag1")
      flag.value |> should.equal(True)
    }
    _ -> should.fail()
  }
}
