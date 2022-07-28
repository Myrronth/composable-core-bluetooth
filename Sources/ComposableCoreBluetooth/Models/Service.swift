import CoreBluetooth

public struct Service {
  let rawValue: CBService?
  
  public let uuid: CBUUID
  public let isPrimary: Bool
  public let characteristics: () -> [Characteristic]?
  public let includedServices: [Service]?

  init(from service: CBService) {
    rawValue = service

    uuid = service.uuid
    isPrimary = service.isPrimary
    characteristics = { service.characteristics?.map(Characteristic.init(from:)) }
    includedServices = service.includedServices?.map(Service.init(from:))
  }

  init(
    identifier: CBUUID,
    isPrimary: Bool,
    characteristics: @escaping () -> [Characteristic]?,
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

extension Service: Equatable {
  public static func == (lhs: Service, rhs: Service) -> Bool {
    lhs.rawValue == rhs.rawValue &&
    lhs.uuid == rhs.uuid &&
    lhs.isPrimary == rhs.isPrimary &&
    lhs.characteristics() == rhs.characteristics() &&
    lhs.includedServices == rhs.includedServices
  }
}

extension Service: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(self, children: [
      "rawValue": rawValue as Any,
      "uuid": uuid,
      "isPrimary": isPrimary,
      // TODO: How to fix infinite loop?
//      "characteristics": characteristics() as Any,
      "includedServices": includedServices as Any
    ], displayStyle: .struct)
  }
}

extension Service {

  public static func mock(
    identifier: CBUUID,
    isPrimary: Bool,
    characteristics: @escaping () -> [Characteristic]?,
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
