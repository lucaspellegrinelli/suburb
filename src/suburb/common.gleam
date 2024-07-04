pub type ServiceError {
  InvalidKey(String)
  ResourceDoesNotExist(String)
  ConnectorError(String)
}
