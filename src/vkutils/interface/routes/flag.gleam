import gleam/dynamic.{type Dynamic}
import gleam/http.{Post}
import gleam/json
import gleam/result
import vkutils/common.{ConnectorError, InvalidKey}
import vkutils/featureflag
import vkutils/interface/web.{type Context}
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

fn call_error(e: common.ServiceError) {
  case e {
    common.InvalidKey(e) | common.ConnectorError(e) -> {
      json.object([
        #("status", json.string("error")),
        #("error", json.string(e)),
      ])
      |> json.to_string_builder
      |> wisp.json_response(400)
    }
  }
}

fn perform_request(ctx: Context, r: FlagRequest) {
  case r.action {
    "set" -> {
      use flag <- result.try(result.map_error(
        featureflag.set(ctx.client, r.namespace, r.flag, r.value),
        call_error,
      ))
      json.object([
        #("status", json.string("ok")),
        #("value", json.string(flag)),
      ])
      |> json.to_string_builder
      |> wisp.json_response(200)
      |> Ok
    }
    "get" -> {
      use flag <- result.try(result.map_error(
        featureflag.get(ctx.client, r.namespace, r.flag),
        call_error,
      ))
      json.object([#("status", json.string("ok")), #("value", json.bool(flag))])
      |> json.to_string_builder
      |> wisp.json_response(200)
      |> Ok
    }
    _ -> Ok(wisp.unprocessable_entity())
  }
}

pub fn flag_route(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Post)
  use json <- wisp.require_json(req)
  case decode_flag_request(json) {
    Ok(r) -> result.unwrap_both(perform_request(ctx, r))
    Error(_) -> wisp.unprocessable_entity()
  }
}
