import gleam/dynamic
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/pair
import gleam/result
import suburb/api/utils.{construct_response, extract_error}
import suburb/api/web.{type Context}
import suburb/decoders/log as logd
import suburb/services/log.{FromTime, Level, Namespace, Source, UntilTime}
import wisp.{type Request, type Response}

pub fn list_route(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, http.Get)
  let query_params = wisp.get_query(req)

  let filters =
    list.filter_map(query_params, fn(param) {
      let #(key, value) = param
      case key {
        "namespace" -> Ok(Namespace(value))
        "source" -> Ok(Source(value))
        "level" -> Ok(Level(value))
        "from_time" -> Ok(FromTime(value))
        "until_time" -> Ok(UntilTime(value))
        _ -> Error(Nil)
      }
    })

  let assert Ok(limit) =
    query_params
    |> list.find(fn(param) {
      let #(key, _) = param
      key == "limit"
    })
    |> result.unwrap(#("limit", "100"))
    |> pair.second
    |> int.parse

  case log.list(ctx.conn, filters, limit) {
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
        Ok(v) -> v |> logd.encoder |> construct_response("success", 200)
        Error(e) -> e |> extract_error |> construct_response("error", 404)
      }
    }
    _, _, _ ->
      "invalid request" |> json.string |> construct_response("error", 400)
  }
}
