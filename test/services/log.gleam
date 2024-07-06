import gleam/list
import gleam/result
import gleeunit/should
import suburb/db
import suburb/services/log.{Level, Namespace, Source}

pub fn log_empty_test() {
  use conn <- db.db_connection(":memory:")
  log.list(conn, [], 100) |> should.equal(Ok([]))
}

pub fn log_entry_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns", "src", "lvl", "msg") |> should.equal(Ok(Nil))
  case log.list(conn, [], 100) {
    Ok([log]) -> {
      log.namespace |> should.equal("ns")
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
    log.add(conn, "ns", "src", "lvl", "msg") |> should.equal(Ok(Nil))
  })

  log.list(conn, [], 10) |> result.unwrap([]) |> list.length |> should.equal(10)
}

pub fn log_namespace_filter_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns1", "src", "lvl", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns2", "src", "lvl", "msg") |> should.equal(Ok(Nil))
  case log.list(conn, [Namespace("ns1")], 100) {
    Ok([log]) -> log.namespace |> should.equal("ns1")
    _ -> should.fail()
  }
}

pub fn log_source_filter_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns", "src1", "lvl", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns", "src2", "lvl", "msg") |> should.equal(Ok(Nil))
  case log.list(conn, [Source("src1")], 100) {
    Ok([log]) -> log.source |> should.equal("src1")
    _ -> should.fail()
  }
}

pub fn log_level_filter_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns", "src", "lvl1", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns", "src", "lvl2", "msg") |> should.equal(Ok(Nil))
  case log.list(conn, [Level("lvl1")], 100) {
    Ok([log]) -> log.level |> should.equal("lvl1")
    _ -> should.fail()
  }
}

pub fn log_multiple_filter_test() {
  use conn <- db.db_connection(":memory:")
  log.add(conn, "ns1", "src1", "lvl1", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns1", "src2", "lvl1", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns2", "src1", "lvl1", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns2", "src2", "lvl1", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns1", "src1", "lvl2", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns1", "src2", "lvl2", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns2", "src1", "lvl2", "msg") |> should.equal(Ok(Nil))
  log.add(conn, "ns2", "src2", "lvl2", "msg") |> should.equal(Ok(Nil))

  case log.list(conn, [Namespace("ns1"), Source("src1"), Level("lvl1")], 100) {
    Ok([log]) -> {
      log.namespace |> should.equal("ns1")
      log.source |> should.equal("src1")
      log.level |> should.equal("lvl1")
    }
    _ -> should.fail()
  }
}
