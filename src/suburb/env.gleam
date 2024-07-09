import envoy
import filepath
import gleam/dynamic
import gleam/json
import gleam/option.{type Option, Some}
import simplifile

const config_file = "config"

const default_host = "http://localhost:8080"

const default_token = "yoursecrettoken"

const default_namespace = "default"

pub type EnvVars {
  EnvVars(host: String, token: String, namespace: String)
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
    Ok(False) ->
      write_env_variables(
        Some(default_host),
        Some(default_token),
        Some(default_namespace),
      )
    Error(e) -> Error(simplifile.describe_error(e))
  }
}

pub fn with_env_variables(f: fn(EnvVars) -> a) {
  case get_env_variables() {
    Ok(env_vars) -> f(env_vars)
    Error(e) -> panic as e
  }
}

fn read_env_variables() {
  case simplifile.read(config_path()) {
    Ok(config_str) -> {
      let decoded_config =
        config_str
        |> json.decode(dynamic.decode3(
          EnvVars,
          dynamic.field("host", dynamic.string),
          dynamic.field("token", dynamic.string),
          dynamic.field("namespace", dynamic.string),
        ))

      case decoded_config {
        Ok(env_vars) -> Ok(env_vars)
        _ -> Error("Could not decode config file")
      }
    }
    Error(e) -> Error(simplifile.describe_error(e))
  }
}

pub fn write_env_variables(
  host: Option(String),
  token: Option(String),
  namespace: Option(String),
) {
  let config = case read_env_variables() {
    Ok(ev) -> {
      let host = option.unwrap(host, ev.host)
      let token = option.unwrap(token, ev.token)
      let namespace = option.unwrap(namespace, ev.namespace)
      EnvVars(host, token, namespace)
    }
    _ -> {
      let host = option.unwrap(host, default_host)
      let token = option.unwrap(token, default_token)
      let namespace = option.unwrap(namespace, default_namespace)
      EnvVars(host, token, namespace)
    }
  }

  let json_config =
    json.object([
      #("host", json.string(config.host)),
      #("token", json.string(config.token)),
      #("namespace", json.string(config.namespace)),
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
