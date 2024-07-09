import gleeunit/should
import suburb/db
import suburb/services/namespace
import suburb/types.{ResourceDoesNotExist}

pub fn namespace_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace.list(c) |> should.equal(Ok([]))
}

pub fn namespace_entry_test() {
  use c <- db.db_connection(":memory:")
  namespace.add(c, "ns") |> should.be_ok()
  case namespace.list(c) {
    Ok([ns]) -> {
      ns.name |> should.equal("ns")
    }
    _ -> should.fail()
  }
}

pub fn namespace_add_test() {
  use c <- db.db_connection(":memory:")
  case namespace.add(c, "ns") {
    Ok(ns) -> {
      ns.name |> should.equal("ns")
    }
    _ -> should.fail()
  }
}

pub fn namespace_delete_test() {
  use c <- db.db_connection(":memory:")
  namespace.add(c, "ns") |> should.be_ok()
  case namespace.delete(c, "ns") {
    Ok(v) -> should.equal(v, Nil)
    _ -> should.fail()
  }
}

pub fn namespace_delete_non_existent_test() {
  use c <- db.db_connection(":memory:")
  namespace.delete(c, "ns")
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}
