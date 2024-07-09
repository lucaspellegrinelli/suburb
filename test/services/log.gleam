import gleam/list
import gleam/result
import gleeunit/should
import suburb/db
import suburb/services/log.{Level, Source}

pub fn log_empty_test() {
  use conn <- db.db_connection(":memory:")
  log.list(conn, "ns", [], 100) |> should.equal(Ok([]))
}

pub fn log_entry_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns", "src", "lvl", "msg") |> should.be_ok()
  case log.list(conn, "ns", [], 100) {
    Ok([log]) -> {
      log.source |> should.equal("src")
      log.level |> should.equal("lvl")
      log.message |> should.equal("msg")
    }
    _ -> should.fail()
  }
}

pub fn log_add_test() {
  use conn <- db.db_connection(":memory:")
  case log.add(conn, "ns", "src", "lvl", "msg") {
    Ok(log) -> {
      log.source |> should.equal("src")
      log.level |> should.equal("lvl")
      log.message |> should.equal("msg")
    }
    _ -> should.fail()
  }
}

pub fn log_limit_test() {
  use conn <- db.db_connection(":memory:")
  list.range(0, 20)
  |> list.each(fn(_) {
    log.add(conn, "ns", "src", "lvl", "msg") |> should.be_ok()
  })

  log.list(conn, "ns", [], 10) |> result.unwrap([]) |> list.length |> should.equal(10)
}

pub fn log_namespace_filter_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns1", "src", "lvl", "msg1") |> should.be_ok()
  log.add(conn, "ns2", "src", "lvl", "msg2") |> should.be_ok()
  case log.list(conn, "ns1", [], 100) {
    Ok([log]) -> log.message |> should.equal("msg1")
    _ -> should.fail()
  }
}

pub fn log_source_filter_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns", "src1", "lvl", "msg") |> should.be_ok()
  log.add(conn, "ns", "src2", "lvl", "msg") |> should.be_ok()
  case log.list(conn, "ns", [Source("src1")], 100) {
    Ok([log]) -> log.source |> should.equal("src1")
    _ -> should.fail()
  }
}

pub fn log_level_filter_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns", "src", "lvl1", "msg") |> should.be_ok()
  log.add(conn, "ns", "src", "lvl2", "msg") |> should.be_ok()
  case log.list(conn, "ns", [Level("lvl1")], 100) {
    Ok([log]) -> log.level |> should.equal("lvl1")
    _ -> should.fail()
  }
}

pub fn log_multiple_filter_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns1", "src1", "lvl1", "msg") |> should.be_ok()
  log.add(conn, "ns1", "src2", "lvl1", "msg") |> should.be_ok()
  log.add(conn, "ns2", "src1", "lvl1", "msg") |> should.be_ok()
  log.add(conn, "ns2", "src2", "lvl1", "msg") |> should.be_ok()
  log.add(conn, "ns1", "src1", "lvl2", "msg") |> should.be_ok()
  log.add(conn, "ns1", "src2", "lvl2", "msg") |> should.be_ok()
  log.add(conn, "ns2", "src1", "lvl2", "msg") |> should.be_ok()
  log.add(conn, "ns2", "src2", "lvl2", "msg") |> should.be_ok()

  case log.list(conn, "ns1", [Source("src1"), Level("lvl1")], 100) {
    Ok([log]) -> {
      log.source |> should.equal("src1")
      log.level |> should.equal("lvl1")
    }
    _ -> should.fail()
  }
}
