import Foundation
import CoreBluetooth

public struct Central: Equatable {

  let rawValue: CBCentral?
  public let identifier: UUID
  public let maximumUpdateValueLength: Int

  init(from central: CBCentral) {
    rawValue = central
    identifier = central.identifier
    maximumUpdateValueLength = central.maximumUpdateValueLength
  }

  init(identifier: UUID, maximumUpdateValueLength: Int) {
    rawValue = nil
    self.identifier = identifier
    self.maximumUpdateValueLength = maximumUpdateValueLength
  }
}

extension Central {
  
  public static func mock(
    identifier: UUID,
    maximumUpdateValueLength: Int
  ) -> Self {
    return Central(
      identifier: identifier,
      maximumUpdateValueLength: maximumUpdateValueLength
    )
  }
}
