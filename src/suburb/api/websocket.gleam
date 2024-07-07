import gleam/bool
import gleam/bytes_builder
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/otp/actor
import mist.{type Connection, type ResponseData}
import suburb/api/web.{type Context}

pub type BroadcasterMessage(a) {
  Register(subject: Subject(a))
  Unregister(subject: Subject(a))
  Broadcast(msg: a)
}

pub type PubSubMessage {
  Send(String)
}

pub type Broadcaster =
  Subject(BroadcasterMessage(PubSubMessage))

fn broadcaster_handle_message(
  message: BroadcasterMessage(a),
  destinations: List(Subject(a)),
) {
  case message {
    Register(subject) -> actor.continue([subject, ..destinations])
    Unregister(subject) ->
      actor.continue(
        destinations
        |> list.filter(fn(d) { d != subject }),
      )
    Broadcast(inner) -> {
      destinations
      |> list.each(fn(dest) { process.send(dest, inner) })
      actor.continue(destinations)
    }
  }
}

pub fn setup_websocket_broadcaster() {
  actor.start([], broadcaster_handle_message)
}

pub fn authenticate(
  req: Request(Connection),
  ctx: Context,
  cb: fn() -> Response(ResponseData),
) {
  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let header_list = dict.from_list(req.headers)
  case dict.get(header_list, "authorization") {
    Ok(token) -> {
      use <- bool.guard(token != ctx.api_secret, not_found)
      cb()
    }
    _ -> not_found
  }
}
