import gleam/dynamic
import gleam/http
import gleam/json
import suburb/api/utils.{construct_response, extract_error}
import suburb/api/web.{type Context}
import suburb/services/log
import wisp.{type Request, type Response}

pub fn list_route(req: Request, ctx: Context, namespace: String) -> Response {
  use <- wisp.require_method(req, http.Get)
  case log.list(ctx.conn, namespace, [], 100) {
    Ok(values) -> {
      json.array(values, fn(log) {
        json.object([
          #("namespace", json.string(log.namespace)),
          #("source", json.string(log.source)),
          #("level", json.string(log.level)),
          #("message", json.string(log.message)),
          #("created_at", json.string(log.created_at)),
        ])
      })
      |> construct_response("success", 200)
    }
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn add_route(req: Request, ctx: Context, namespace: String) -> Response {
  use <- wisp.require_method(req, http.Post)
  use json <- wisp.require_json(req)
  let source = json |> dynamic.field("source", dynamic.string)
  let level = json |> dynamic.field("level", dynamic.string)
  let message = json |> dynamic.field("message", dynamic.string)

  case source, level, message {
    Ok(s), Ok(l), Ok(m) -> {
      case log.add(ctx.conn, namespace, s, l, m) {
        Ok(_) -> "added" |> json.string |> construct_response("success", 200)
        Error(e) -> e |> extract_error |> construct_response("error", 404)
      }
    }
    _, _, _ ->
      "invalid request" |> json.string |> construct_response("error", 400)
  }
}
