import envoy
import gleam/erlang/process
import gleam/int
import gleam/result
import mist
import radish
import vkutils/interface/router
import vkutils/interface/web.{Context}
import wisp

pub fn main() {
  let assert Ok(valkey_port) =
    envoy.get("VALKEY_PORT")
    |> result.unwrap("6379")
    |> int.parse

  wisp.configure_logger()

  let assert Ok(valkey_client) =
    radish.start("localhost", valkey_port, [
      radish.Timeout(128),
      radish.Auth(""),
    ])

  let context = Context(client: valkey_client)
  let handler = router.handle_request(_, context)

  let secret_key_base = wisp.random_string(64)
  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(7777)
    |> mist.start_http

  process.sleep_forever()
}
