import gleam/dynamic
import gleam/http
import gleam/json
import suburb/api/utils.{construct_response, extract_error}
import suburb/api/web.{type Context}
import suburb/services/flag
import wisp.{type Request, type Response}

pub fn list_route(req: Request, ctx: Context, namespace: String) -> Response {
  use <- wisp.require_method(req, http.Get)
  case flag.list(ctx.conn, namespace) {
    Ok(values) ->
      values
      |> json.array(of: json.string)
      |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn get_route(
  req: Request,
  ctx: Context,
  namespace: String,
  flag: String,
) -> Response {
  use <- wisp.require_method(req, http.Get)
  case flag.get(ctx.conn, namespace, flag) {
    Ok(value) -> value |> json.string |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn set_route(
  req: Request,
  ctx: Context,
  namespace: String,
  flag: String,
) -> Response {
  use <- wisp.require_method(req, http.Post)
  use json <- wisp.require_json(req)
  let value = json |> dynamic.field("value", dynamic.string)

  case value {
    Ok(value) ->
      case flag.set(ctx.conn, namespace, flag, value) {
        Ok(_) -> "set" |> json.string |> construct_response("success", 200)
        Error(e) -> e |> extract_error |> construct_response("error", 404)
      }
    Error(_) ->
      json.string("Couldn't parse value") |> construct_response("error", 400)
  }
}

pub fn delete_route(
  req: Request,
  ctx: Context,
  namespace: String,
  flag: String,
) -> Response {
  use <- wisp.require_method(req, http.Delete)
  case flag.delete(ctx.conn, namespace, flag) {
    Ok(_) -> "deleted" |> json.string |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}
