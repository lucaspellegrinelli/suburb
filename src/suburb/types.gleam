pub type Queue {
  Queue(namespace: String, queue: String)
}

pub type FeatureFlag {
  FeatureFlag(namespace: String, flag: String, value: String)
}

pub type Log {
  Log(
    namespace: String,
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
