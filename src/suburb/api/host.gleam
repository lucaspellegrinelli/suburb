import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import mist
import radish
import suburb/api/router
import suburb/api/web.{Context}
import wisp

fn get_env_int(name: String, default: Int) -> Int {
  case envoy.get(name) {
    Ok(port) ->
      case int.parse(port) {
        Ok(port) -> port
        Error(_) -> {
          panic as {
            "The environment variable " <> name <> " is not a valid number"
          }
        }
      }
    Error(_) -> {
      io.println(name <> " not set, defaulting to " <> int.to_string(default))
      default
    }
  }
}

pub fn serve() {
  let port = get_env_int("PORT", 7777)
  let valkey_port = get_env_int("VALKEY_PORT", 6379)
  let valkey_host = case envoy.get("VALKEY_HOST") {
    Ok(host) -> host
    Error(_) -> {
      io.println("VALKEY_HOST not set, defaulting to localhost")
      "localhost"
    }
  }
  let api_secret = case envoy.get("API_SECRET") {
    Ok(secret) -> secret
    Error(_) -> {
      io.println("API_SECRET not set, defaulting to \"secret\"")
      "secret"
    }
  }

  wisp.configure_logger()

  let assert Ok(valkey_client) =
    radish.start(valkey_host, valkey_port, [
      radish.Timeout(128),
      radish.Auth(""),
    ])

  let context = Context(client: valkey_client, api_secret: api_secret)
  let handler = router.handle_request(_, context)

  let secret_key_base = wisp.random_string(64)
  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(port)
    |> mist.start_http

  process.sleep_forever()
}
