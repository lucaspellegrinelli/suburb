import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import mist
import suburb/api/router
import suburb/api/web.{Context}
import suburb/db.{db_connection}
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
  let api_secret = case envoy.get("API_SECRET") {
    Ok(secret) -> secret
    Error(_) -> {
      io.println("API_SECRET not set, defaulting to \"secret\"")
      "secret"
    }
  }
  let database_path = case envoy.get("DATABASE_PATH") {
    Ok(path) -> path
    Error(_) -> {
      io.println("DATABASE_PATH not set, defaulting to \"suburb.db\"")
      "suburb.db"
    }
  }

  wisp.configure_logger()

  use db_conn <- db_connection(database_path)

  let context = Context(conn: db_conn, api_secret: api_secret)
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
