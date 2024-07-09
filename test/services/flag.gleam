import gleeunit/should
import suburb/db
import suburb/services/flag.{Flag}
import suburb/types.{FeatureFlag, ResourceDoesNotExist}

pub fn flag_empty_test() {
  use conn <- db.db_connection(":memory:")
  flag.list(conn, "ns", []) |> should.equal(Ok([]))
}

pub fn flag_set_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns", "flag", True)
  |> should.equal(Ok(FeatureFlag("flag", True)))
  case flag.list(conn, "ns", []) {
    Ok([f]) -> {
      f.flag |> should.equal("flag")
      f.value |> should.equal(True)
    }
    _ -> should.fail()
  }
}

pub fn flag_get_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns", "flag", True) |> should.be_ok()
  flag.get(conn, "ns", "flag")
  |> should.equal(Ok(FeatureFlag("flag", True)))
}

pub fn flag_get_from_non_existent_flag_test() {
  use conn <- db.db_connection(":memory:")
  flag.get(conn, "ns", "flag")
  |> should.equal(
    Error(ResourceDoesNotExist("Feature Flag flag does not exist.")),
  )
}

pub fn flag_override_value_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns", "flag", False) |> should.be_ok()
  flag.set(conn, "ns", "flag", True) |> should.be_ok()
  flag.get(conn, "ns", "flag")
  |> should.equal(Ok(FeatureFlag("flag", True)))
}

pub fn flag_delete_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns", "flag", True) |> should.be_ok()
  flag.delete(conn, "ns", "flag") |> should.equal(Ok(Nil))
  flag.get(conn, "ns", "flag")
  |> should.equal(
    Error(ResourceDoesNotExist("Feature Flag flag does not exist.")),
  )
}

pub fn flag_namespace_filter_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns1", "flag1", True) |> should.be_ok()
  flag.set(conn, "ns2", "flag1", True) |> should.be_ok()
  case flag.list(conn, "ns1", []) {
    Ok([f]) -> f.flag |> should.equal("flag1")
    _ -> should.fail()
  }
}

pub fn flag_name_filter_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns", "flag1", True) |> should.be_ok()
  flag.set(conn, "ns", "flag2", True) |> should.be_ok()
  case flag.list(conn, "ns", [Flag("flag1")]) {
    Ok([f]) -> f.flag |> should.equal("flag1")
    _ -> should.fail()
  }
}

pub fn flag_multiple_filter_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns1", "flag1", True) |> should.be_ok()
  flag.set(conn, "ns1", "flag2", True) |> should.be_ok()
  flag.set(conn, "ns2", "flag3", True) |> should.be_ok()
  flag.set(conn, "ns2", "flag4", True) |> should.be_ok()
  case flag.list(conn, "ns1", [Flag("flag1")]) {
    Ok([f]) -> {
      f.flag |> should.equal("flag1")
    }
    _ -> should.fail()
  }
}
