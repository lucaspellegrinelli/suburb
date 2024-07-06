import gleeunit/should
import suburb/db
import suburb/services/flag.{Flag, Namespace}
import suburb/types.{ResourceDoesNotExist}

pub fn flag_empty_test() {
  use conn <- db.db_connection(":memory:")
  flag.list(conn, []) |> should.equal(Ok([]))
}

pub fn flag_set_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns", "flag", "val") |> should.equal(Ok(Nil))
  case flag.list(conn, []) {
    Ok([f]) -> {
      f.namespace |> should.equal("ns")
      f.flag |> should.equal("flag")
      f.value |> should.equal("val")
    }
    _ -> should.fail()
  }
}

pub fn flag_get_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns", "flag", "val") |> should.equal(Ok(Nil))
  case flag.get(conn, "ns", "flag") {
    Ok("val") -> Nil
    _ -> should.fail()
  }
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
  flag.set(conn, "ns", "flag", "val") |> should.equal(Ok(Nil))
  flag.set(conn, "ns", "flag", "new_val") |> should.equal(Ok(Nil))
  case flag.get(conn, "ns", "flag") {
    Ok("new_val") -> Nil
    _ -> should.fail()
  }
}

pub fn flag_delete_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns", "flag", "val") |> should.equal(Ok(Nil))
  flag.delete(conn, "ns", "flag") |> should.equal(Ok(Nil))
  flag.get(conn, "ns", "flag")
  |> should.equal(
    Error(ResourceDoesNotExist("Feature Flag flag does not exist.")),
  )
}

pub fn flag_namespace_filter_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns1", "flag", "val") |> should.equal(Ok(Nil))
  flag.set(conn, "ns2", "flag", "val") |> should.equal(Ok(Nil))
  case flag.list(conn, [Namespace("ns1")]) {
    Ok([f]) -> f.namespace |> should.equal("ns1")
    _ -> should.fail()
  }
}

pub fn flag_name_filter_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns", "flag1", "val") |> should.equal(Ok(Nil))
  flag.set(conn, "ns", "flag2", "val") |> should.equal(Ok(Nil))
  case flag.list(conn, [Flag("flag1")]) {
    Ok([f]) -> f.flag |> should.equal("flag1")
    _ -> should.fail()
  }
}

pub fn flag_multiple_filter_test() {
  use conn <- db.db_connection(":memory:")
  flag.set(conn, "ns1", "flag1", "val") |> should.equal(Ok(Nil))
  flag.set(conn, "ns1", "flag2", "val") |> should.equal(Ok(Nil))
  flag.set(conn, "ns2", "flag1", "val") |> should.equal(Ok(Nil))
  flag.set(conn, "ns2", "flag2", "val") |> should.equal(Ok(Nil))
  case flag.list(conn, [Namespace("ns1"), Flag("flag1")]) {
    Ok([f]) -> {
      f.namespace |> should.equal("ns1")
      f.flag |> should.equal("flag1")
    }
    _ -> should.fail()
  }
}
