import CoreBluetooth

public struct Service: Equatable {
  let rawValue: CBService?
  
  public let uuid: CBUUID
  public let isPrimary: Bool
  public let characteristics: [Characteristic]?
  public let includedServices: [Service]?

  init(from service: CBService) {
    rawValue = service

    uuid = service.uuid
    isPrimary = service.isPrimary
    characteristics = service.characteristics?.map(Characteristic.init(from:))
    includedServices = service.includedServices?.map(Service.init(from:))
  }

  init(
    identifier: CBUUID,
    isPrimary: Bool,
    characteristics: [Characteristic]?,
    includedServices: [Service]?
  ) {
    rawValue = nil
    self.uuid = identifier
    self.isPrimary = isPrimary
    self.characteristics = characteristics
    self.includedServices = includedServices
  }
}

extension Service: Identifiable {
  public var id: CBUUID { uuid }
}

extension Service {

  public static func mock(
    identifier: CBUUID,
    isPrimary: Bool,
    characteristics: [Characteristic]?,
    includedServices: [Service]?
  ) -> Self {
    return Self(
      identifier: identifier,
      isPrimary: isPrimary,
      characteristics: characteristics,
      includedServices: includedServices
    )
  }
}
