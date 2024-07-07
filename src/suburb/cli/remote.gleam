import gleam/io
import gleam/option.{None, Some}
import gleam/result
import glint
import suburb/env

fn host_flag() -> glint.Flag(String) {
  glint.string_flag("host")
  |> glint.flag_help("Remote server host")
}

fn token_flag() -> glint.Flag(String) {
  glint.string_flag("token")
  |> glint.flag_help("Remote server API key")
}

pub fn set() -> glint.Command(Nil) {
  use <- glint.command_help("Sets the remote server host and API key")
  use host <- glint.flag(host_flag())
  use token <- glint.flag(token_flag())
  use _, _, flags <- glint.command()

  let host = result.unwrap(result.map(host(flags), Some), None)
  let token = result.unwrap(result.map(token(flags), Some), None)

  case env.write_env_variables(host, token) {
    Ok(vars) -> {
      io.println("Remote HOST:\t" <> vars.host)
      io.println("Remote TOKEN:\t" <> vars.token)
    }
    Error(e) -> io.println("Failed to set remote host: " <> e)
  }
}

fn show_api_key_flag() -> glint.Flag(Bool) {
  glint.bool_flag("key")
  |> glint.flag_default(False)
  |> glint.flag_help("Shows the API Key")
}

pub fn get() -> glint.Command(Nil) {
  use <- glint.command_help("Gets the remote server host and API key")
  use show_key <- glint.flag(show_api_key_flag())
  use _, _, flags <- glint.command()

  case env.get_env_variables() {
    Ok(config) -> {
      io.println("Remote HOST:\t" <> config.host)
      case show_key(flags) {
        Ok(True) -> io.println("Remote TOKEN:\t" <> config.token)
        _ -> io.println("Remote TOKEN:\t" <> "****************")
      }
    }
    Error(e) -> io.println("Failed to get remote host: " <> e)
  }
}
