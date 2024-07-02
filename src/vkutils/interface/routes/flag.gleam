import gleam/dynamic.{type Dynamic}
import gleam/http.{Post}
import gleam/json
import gleam/result
import vkutils/interface/utils.{construct_response, extract_error, map_both}
import vkutils/interface/web.{type Context}
import vkutils/services/featureflag
import wisp.{type Request, type Response}

type FlagRequest {
  FlagRequest(action: String, namespace: String, flag: String, value: Bool)
}

fn decode_flag_request(
  json: Dynamic,
) -> Result(FlagRequest, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode4(
      FlagRequest,
      dynamic.field("action", dynamic.string),
      dynamic.field("namespace", dynamic.string),
      dynamic.field("flag", dynamic.string),
      dynamic.field("value", dynamic.bool),
    )
  decoder(json)
}

fn perform_request(ctx: Context, r: FlagRequest) {
  case r.action {
    "set" ->
      map_both(
        featureflag.set(ctx.client, r.namespace, r.flag, r.value),
        json.string,
        extract_error,
      )
    "get" ->
      map_both(
        featureflag.get(ctx.client, r.namespace, r.flag),
        json.bool,
        extract_error,
      )
    _ -> Error(json.string("Invalid action"))
  }
}

pub fn flag_route(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Post)
  use json <- wisp.require_json(req)
  case decode_flag_request(json) {
    Ok(r) ->
      perform_request(ctx, r)
      |> result.unwrap_both
      |> construct_response("success")
    Error(_) -> json.string("Invalid request") |> construct_response("error")
  }
}
