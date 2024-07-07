import gleam/io
import glint
import suburb/env.{EnvVars}

fn show_api_key_flag() -> glint.Flag(Bool) {
  glint.bool_flag("key")
  |> glint.flag_default(False)
  |> glint.flag_help("Shows the API Key")
}

pub fn set() -> glint.Command(Nil) {
  use <- glint.command_help("Sets the remote server host and API key")
  use host <- glint.named_arg("remote host")
  use token <- glint.named_arg("remote token")
  use named, _, _ <- glint.command()

  case env.write_env_variables(EnvVars(host(named), token(named))) {
    Ok(_) -> {
      io.println("Remote HOST:\t" <> host(named))
      io.println("Remote TOKEN:\t" <> token(named))
    }
    Error(e) -> io.println("Failed to set remote host: " <> e)
  }
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
