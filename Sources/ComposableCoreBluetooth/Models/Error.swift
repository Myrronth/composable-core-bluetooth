import Foundation

public struct Error: Swift.Error, Equatable {
  public let error: NSError

  public init(_ error: Swift.Error) {
    self.error = error as NSError
  }

  public init?(_ error: Swift.Error?) {
    if let error = error {
      self.error = error as NSError
    }
    else {
      return nil
    }
  }
}

