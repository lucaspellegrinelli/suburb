import gleam/list
import gleam/result
import gleeunit/should
import suburb/db
import suburb/services/log.{Level, Source}
import suburb/services/namespace as namespace_service
import suburb/types.{ResourceDoesNotExist}

pub fn log_empty_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  log.list(c, "ns", [], 100) |> should.equal(Ok([]))
}

pub fn log_list_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  log.list(c, "ns", [], 100)
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn log_entry_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  log.add(c, "ns", "src", "lvl", "msg") |> should.be_ok()
  case log.list(c, "ns", [], 100) {
    Ok([log]) -> {
      log.source |> should.equal("src")
      log.level |> should.equal("lvl")
      log.message |> should.equal("msg")
    }
    _ -> should.fail()
  }
}

pub fn log_add_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  case log.add(c, "ns", "src", "lvl", "msg") {
    Ok(log) -> {
      log.source |> should.equal("src")
      log.level |> should.equal("lvl")
      log.message |> should.equal("msg")
    }
    _ -> should.fail()
  }
}

pub fn log_add_non_existent_namespace_test() {
  use c <- db.db_connection(":memory:")
  log.add(c, "ns", "src", "lvl", "msg")
  |> should.equal(Error(ResourceDoesNotExist("Namespace ns does not exist.")))
}

pub fn log_limit_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  list.range(0, 20)
  |> list.each(fn(_) { log.add(c, "ns", "src", "lvl", "msg") |> should.be_ok() })

  log.list(c, "ns", [], 10)
  |> result.unwrap([])
  |> list.length
  |> should.equal(10)
}

pub fn log_namespace_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  log.add(c, "ns1", "src", "lvl", "msg1") |> should.be_ok()
  log.add(c, "ns2", "src", "lvl", "msg2") |> should.be_ok()
  case log.list(c, "ns1", [], 100) {
    Ok([log]) -> log.message |> should.equal("msg1")
    _ -> should.fail()
  }
}

pub fn log_source_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  log.add(c, "ns", "src1", "lvl", "msg") |> should.be_ok()
  log.add(c, "ns", "src2", "lvl", "msg") |> should.be_ok()
  case log.list(c, "ns", [Source("src1")], 100) {
    Ok([log]) -> log.source |> should.equal("src1")
    _ -> should.fail()
  }
}

pub fn log_level_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns") |> should.be_ok()
  log.add(c, "ns", "src", "lvl1", "msg") |> should.be_ok()
  log.add(c, "ns", "src", "lvl2", "msg") |> should.be_ok()
  case log.list(c, "ns", [Level("lvl1")], 100) {
    Ok([log]) -> log.level |> should.equal("lvl1")
    _ -> should.fail()
  }
}

pub fn log_multiple_filter_test() {
  use c <- db.db_connection(":memory:")
  namespace_service.add(c, "ns1") |> should.be_ok()
  namespace_service.add(c, "ns2") |> should.be_ok()
  log.add(c, "ns1", "src1", "lvl1", "msg") |> should.be_ok()
  log.add(c, "ns1", "src2", "lvl1", "msg") |> should.be_ok()
  log.add(c, "ns2", "src1", "lvl1", "msg") |> should.be_ok()
  log.add(c, "ns2", "src2", "lvl1", "msg") |> should.be_ok()
  log.add(c, "ns1", "src1", "lvl2", "msg") |> should.be_ok()
  log.add(c, "ns1", "src2", "lvl2", "msg") |> should.be_ok()
  log.add(c, "ns2", "src1", "lvl2", "msg") |> should.be_ok()
  log.add(c, "ns2", "src2", "lvl2", "msg") |> should.be_ok()

  case log.list(c, "ns1", [Source("src1"), Level("lvl1")], 100) {
    Ok([log]) -> {
      log.source |> should.equal("src1")
      log.level |> should.equal("lvl1")
    }
    _ -> should.fail()
  }
}
