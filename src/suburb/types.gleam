pub type Namespace {
  Namespace(name: String)
}

pub type Queue {
  Queue(queue: String)
}

pub type FeatureFlag {
  FeatureFlag(flag: String, value: Bool)
}

pub type Log {
  Log(
    source: String,
    level: String,
    message: String,
    created_at: String,
  )
}

pub type ServiceError {
  InvalidKey(String)
  ResourceDoesNotExist(String)
  ResourceAlreadyExists(String)
  EmptyQueue(String)
  ConnectorError(String)
}
