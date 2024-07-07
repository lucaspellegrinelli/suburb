import envoy
import filepath
import gleam/dynamic
import gleam/io
import gleam/json
import gleam/option.{type Option, Some}
import simplifile

const config_file = "config"

const default_host = "http://localhost:8080"

const default_token = "yoursecrettoken"

pub type EnvVars {
  EnvVars(host: String, token: String)
}

fn config_folder() {
  case envoy.get("HOME") {
    Ok(home) -> filepath.join(home, ".suburb")
    Error(_) -> panic as "Could not get home directory from $HOME"
  }
}

fn config_path() {
  filepath.join(config_folder(), config_file)
}

pub fn get_env_variables() {
  case simplifile.is_file(config_path()) {
    Ok(True) -> read_env_variables()
    Ok(False) -> write_env_variables(Some(default_host), Some(default_token))
    Error(e) -> Error(simplifile.describe_error(e))
  }
}

fn read_env_variables() {
  case simplifile.read(config_path()) {
    Ok(config_str) -> {
      let decoded_config =
        config_str
        |> json.decode(dynamic.decode2(
          EnvVars,
          dynamic.field("host", dynamic.string),
          dynamic.field("token", dynamic.string),
        ))

      case decoded_config {
        Ok(env_vars) -> Ok(env_vars)
        _ -> Error("Could not decode config file")
      }
    }
    Error(e) -> Error(simplifile.describe_error(e))
  }
}

pub fn write_env_variables(host: Option(String), token: Option(String)) {
  let config = case read_env_variables() {
    Ok(ev) -> {
      let host = option.unwrap(host, ev.host)
      let token = option.unwrap(token, ev.token)
      EnvVars(host, token)
    }
    _ -> {
      let host = option.unwrap(host, default_host)
      let token = option.unwrap(token, default_token)
      EnvVars(host, token)
    }
  }

  let json_config =
    json.object([
      #("host", json.string(config.host)),
      #("token", json.string(config.token)),
    ])
    |> json.to_string

  case simplifile.create_directory(config_folder()) {
    _ ->
      case simplifile.is_directory(config_folder()) {
        Ok(True) ->
          case simplifile.write(config_path(), json_config) {
            Ok(_) -> Ok(config)
            Error(e) -> Error(simplifile.describe_error(e))
          }
        Ok(False) -> Error("Could not create config folder")
        Error(e) -> Error(simplifile.describe_error(e))
      }
  }
}
