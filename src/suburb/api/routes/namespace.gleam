import gleam/dynamic
import gleam/http
import gleam/json
import suburb/api/utils.{construct_response, extract_error}
import suburb/api/web.{type Context}
import suburb/coders/namespace as namespace_coder
import suburb/services/namespace
import wisp.{type Request, type Response}

pub fn list_route(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, http.Get)

  case namespace.list(ctx.conn) {
    Ok(values) -> {
      json.array(values, fn(ns) {
        json.object([#("name", json.string(ns.name))])
      })
      |> construct_response("success", 200)
    }
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn add_route(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, http.Post)
  use json <- wisp.require_json(req)
  let name = json |> dynamic.field("name", dynamic.string)

  case name {
    Ok(n) -> {
      case namespace.add(ctx.conn, n) {
        Ok(v) ->
          v |> namespace_coder.encoder |> construct_response("success", 200)
        Error(e) -> e |> extract_error |> construct_response("error", 404)
      }
    }
    _ -> "invalid request" |> json.string |> construct_response("error", 400)
  }
}

pub fn delete_route(req: Request, ctx: Context, name: String) -> Response {
  use <- wisp.require_method(req, http.Delete)
  case namespace.delete(ctx.conn, name) {
    Ok(_) ->
      { "Namespace " <> name <> " has been deleted." }
      |> json.string
      |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}
