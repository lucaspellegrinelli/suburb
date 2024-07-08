import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/http
import gleam/http/request.{type Request}
import gleam/json
import gleam/option.{Some}
import gleam/otp/actor
import mist.{type Connection}
import suburb/api/utils.{construct_response}
import suburb/api/web.{type Context}
import suburb/api/websocket.{
  type Broadcaster, type PubSubMessage, Broadcast, Register, Send,
  Unregister, authenticate,
}
import wisp

type SocketState {
  SocketState(subject: Subject(PubSubMessage))
}

pub fn setup_websocket(
  req: Request(Connection),
  ctx: Context,
  channel: String,
  broadcaster: Broadcaster,
) {
  use <- authenticate(req, ctx)

  mist.websocket(
    request: req,
    on_init: fn(_conn) {
      let subject = process.new_subject()
      let selector =
        process.new_selector() |> process.selecting(subject, function.identity)
      process.send(broadcaster, Register(subject, channel))
      #(SocketState(subject), Some(selector))
    },
    on_close: fn(state) {
      process.send(broadcaster, Unregister(state.subject, channel))
    },
    handler: fn(state, conn, message) {
      case message {
        mist.Text("ping") -> {
          let assert Ok(_) = mist.send_text_frame(conn, "pong")
          actor.continue(state)
        }
        mist.Text(_) | mist.Binary(_) -> {
          actor.continue(state)
        }
        mist.Custom(Send(text)) -> {
          let assert Ok(_) = mist.send_text_frame(conn, text)
          actor.continue(state)
        }
        mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
      }
    },
  )
}

pub fn publish_route(
  req: wisp.Request,
  channel: String,
  broadcaster: Broadcaster,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_string_body(req)
  process.send(broadcaster, Broadcast(Send(body), channel))
  "published" |> json.string |> construct_response("success", 200)
}
