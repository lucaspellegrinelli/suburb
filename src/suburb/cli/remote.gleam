import gleam/io
import glint
import suburb/env.{EnvVars}

pub fn set() -> glint.Command(Nil) {
  use <- glint.command_help("Sets the remote server host and API key")
  use host <- glint.named_arg("remote host")
  use token <- glint.named_arg("remote token")
  use named, _, _ <- glint.command()

  case env.write_env_variables(EnvVars(host(named), token(named))) {
    Ok(_) -> io.println("Remote HOST:\t" <> host(named))
    Error(e) -> io.println("Failed to set remote host: " <> e)
  }
}

pub fn get() -> glint.Command(Nil) {
  use <- glint.command_help("Gets the remote server host and API key")
  use _, _, _ <- glint.command()

  case env.get_env_variables() {
    Ok(config) -> io.println("Remote HOST:\t" <> config.host)
    Error(e) -> io.println("Failed to get remote host: " <> e)
  }
}
