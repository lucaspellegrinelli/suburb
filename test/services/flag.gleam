import gleeunit/should
import suburb/db
import suburb/services/flag.{Flag}
import suburb/services/namespace as namespace_service
import suburb/types.{FeatureFlag, ResourceDoesNotExist}

pub fn flag_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag.list(c, "ns", []) |> should.equal(Ok([]))
}

pub fn flag_list_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  flag.list(c, "ns", [])
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn flag_set_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag.set(c, "ns", "flag", True)
  |> should.equal(Ok(FeatureFlag("flag", True)))
  case flag.list(c, "ns", []) {
    Ok([f]) -> {
      f.flag |> should.equal("flag")
      f.value |> should.equal(True)
    }
    _ -> should.fail()
  }
}

pub fn flag_set_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  flag.set(c, "ns", "flag", True)
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn flag_get_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag.set(c, "ns", "flag", True) |> should.be_ok()
  flag.get(c, "ns", "flag")
  |> should.equal(Ok(FeatureFlag("flag", True)))
}

pub fn flag_get_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  flag.get(c, "ns", "flag")
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn flag_get_from_non_existent_flag_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag.get(c, "ns", "flag")
  |> should.equal(
    Error(ResourceDoesNotExist("Feature Flag flag does not exist.")),
  )
}

pub fn flag_override_value_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag.set(c, "ns", "flag", False) |> should.be_ok()
  flag.set(c, "ns", "flag", True) |> should.be_ok()
  flag.get(c, "ns", "flag")
  |> should.equal(Ok(FeatureFlag("flag", True)))
}

pub fn flag_delete_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag.set(c, "ns", "flag", True) |> should.be_ok()
  flag.delete(c, "ns", "flag") |> should.equal(Ok(Nil))
  flag.get(c, "ns", "flag")
  |> should.equal(
    Error(ResourceDoesNotExist("Feature Flag flag does not exist.")),
  )
}

pub fn flag_namespace_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  flag.set(c, "ns1", "flag1", True) |> should.be_ok()
  flag.set(c, "ns2", "flag1", True) |> should.be_ok()
  case flag.list(c, "ns1", []) {
    Ok([f]) -> f.flag |> should.equal("flag1")
    _ -> should.fail()
  }
}

pub fn flag_name_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  flag.set(c, "ns", "flag1", True) |> should.be_ok()
  flag.set(c, "ns", "flag2", True) |> should.be_ok()
  case flag.list(c, "ns", [Flag("flag1")]) {
    Ok([f]) -> f.flag |> should.equal("flag1")
    _ -> should.fail()
  }
}

pub fn flag_multiple_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  flag.set(c, "ns1", "flag1", True) |> should.be_ok()
  flag.set(c, "ns1", "flag2", True) |> should.be_ok()
  flag.set(c, "ns2", "flag3", True) |> should.be_ok()
  flag.set(c, "ns2", "flag4", True) |> should.be_ok()
  case flag.list(c, "ns1", [Flag("flag1")]) {
    Ok([f]) -> {
      f.flag |> should.equal("flag1")
    }
    _ -> should.fail()
  }
}
