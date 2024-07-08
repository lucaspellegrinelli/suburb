import gleam/bool
import gleam/bytes_builder
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/list
import gleam/otp/actor
import mist.{type Connection, type ResponseData}
import suburb/api/web.{type Context}

pub type BroadcasterMessage(a) {
  Register(subject: Subject(a), channel: String)
  Unregister(subject: Subject(a), channel: String)
  Broadcast(message: a, channel: String)
  Ping(subject: Subject(a), message: a)
}

pub type PubSubMessage {
  Send(message: String)
}

pub type Broadcaster =
  Subject(BroadcasterMessage(PubSubMessage))

fn broadcaster_handle_message(
  message: BroadcasterMessage(a),
  destinations: List(#(Subject(a), String)),
) {
  case message {
    Register(subject, channel) -> {
      io.debug("RECIEVED REGISTER")
      io.debug(#(subject, channel))
      io.debug("DESTINATIONS (PRE)")
      io.debug(destinations)
      actor.continue([#(subject, channel), ..destinations])
    }
    Unregister(subject, channel) -> {
      io.debug("RECIEVED UNREGISTER")
      io.debug(#(subject, channel))
      io.debug("DESTINATIONS (PRE)")
      io.debug(destinations)
      destinations
      |> list.filter(fn(d) {
        io.debug("CHECKING IF SHOULD UNREGISTER")
        io.debug(#("ITEM IN LIST", d))
        io.debug(#("ITEM TO UNREGISTER", #(subject, channel)))
        io.debug(#("CHECK", d.0 != subject && d.1 != channel))
        d.0 != subject && d.1 != channel
      })
      io.debug("DESTINATIONS (POST)")
      io.debug(destinations)
      actor.continue(
        destinations
        |> list.filter(fn(d) { d.0 != subject && d.1 != channel }),
      )
    }
    Broadcast(inner, channel) -> {
      io.debug("RECIEVED BROADCAST")
      io.debug(#(inner, channel))
      io.debug("DESTINATIONS")
      io.debug(destinations)
      destinations
      |> list.filter(fn(d) { d.1 == channel })
      |> list.each(fn(dest) {
        io.debug("SENDING TO DEST")
        io.debug(dest)
        process.send(dest.0, inner)
      })
      actor.continue(destinations)
    }
    Ping(subject, message) -> {
      io.debug("RECIEVED PING")
      io.debug(#(subject, message))
      process.send(subject, message)
      io.debug("DESTINATIONS")
      io.debug(destinations)
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
  let unauthorized =
    response.new(401)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let header_list = dict.from_list(req.headers)
  case dict.get(header_list, "authorization") {
    Ok(token) -> {
      use <- bool.guard(token != ctx.api_secret, unauthorized)
      cb()
    }
    _ -> unauthorized
  }
}
