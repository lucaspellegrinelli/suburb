import gleam/io
import gleam/list
import gleam/option.{None, Some}
import glint
import suburb/env

fn host_flag() -> glint.Flag(String) {
  glint.string_flag("host")
  |> glint.flag_help("Setting the remote host")
}

fn token_flag() -> glint.Flag(String) {
  glint.string_flag("token")
  |> glint.flag_help("Setting the remote token")
}

fn namespace_flag() -> glint.Flag(String) {
  glint.string_flag("namespace")
  |> glint.flag_help("Setting the namespace")
}

pub fn handle() -> glint.Command(Nil) {
  use <- glint.command_help("Handles getting/setting the current configuration")
  use host <- glint.flag(host_flag())
  use token <- glint.flag(token_flag())
  use namespace <- glint.flag(namespace_flag())
  use _, _, flags <- glint.command()

  let host = case host(flags) {
    Ok(h) -> Some(h)
    _ -> None
  }

  let token = case token(flags) {
    Ok(t) -> Some(t)
    _ -> None
  }

  let namespace = case namespace(flags) {
    Ok(n) -> Some(n)
    _ -> None
  }

  case list.any([host, token, namespace], option.is_some) {
    True -> {
      case env.write_env_variables(host, token, namespace) {
        Ok(vars) -> {
          io.println("NAMESPACE\t" <> vars.namespace)
          io.println("HOST\t\t" <> vars.host)
          io.println("TOKEN\t\t" <> vars.token)
        }
        Error(e) -> io.println("Failed to set current configuration: " <> e)
      }
    }
    _ -> {
      case env.get_env_variables() {
        Ok(vars) -> {
          io.println("NAMESPACE\t" <> vars.namespace)
          io.println("HOST\t\t" <> vars.host)
          io.println("TOKEN\t\t" <> vars.token)
        }
        Error(e) -> io.println("Failed to get current configuration: " <> e)
      }
    }
  }
}
