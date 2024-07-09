import gleam/dynamic
import gleam/json
import gleam/string_builder
import gleeunit/should
import suburb/api/routes/namespace as namespace_route
import suburb/api/web.{Context}
import suburb/coders/namespace as namespace_coder
import suburb/db
import suburb/services/namespace as namespace_service
import wisp.{Text}
import wisp/testing

fn body_to_string(body: wisp.Body) {
  case body {
    Text(s) -> string_builder.to_string(s)
    _ -> ""
  }
}

pub fn namespace_list_empty_test() {
  use c <- db.db_connection(":memory:")
  let req = testing.get("", [])
  let res = namespace_route.list_route(req, Context(c, ""))
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(namespace_coder.decoder),
    ))
  decoded_body |> should.equal([])
}

pub fn namespace_add_test() {
  use c <- db.db_connection(":memory:")
  let body = json.object([#("name", json.string("ns"))])
  let req = testing.post_json("", [], body)
  let res = namespace_route.add_route(req, Context(c, ""))
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: namespace_coder.decoder))

  decoded_body.name |> should.equal("ns")
}

pub fn namespace_delete_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  let req = testing.delete("", [], "")
  let res = namespace_route.delete_route(req, Context(c, ""), "ns")
  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Namespace ns has been deleted.")
  namespace_service.list(c) |> should.equal(Ok([]))
}

pub fn namespace_delete_non_existent_test() {
  use c <- db.db_connection(":memory:")
  let req = testing.delete("", [], "")
  let res = namespace_route.delete_route(req, Context(c, ""), "ns")
  res.status |> should.equal(404)

  let assert Ok(decoded_body) =
    res.body
    |> body_to_string
    |> json.decode(dynamic.field("response", of: dynamic.string))

  decoded_body |> should.equal("Namespace ns does not exist.")
}
