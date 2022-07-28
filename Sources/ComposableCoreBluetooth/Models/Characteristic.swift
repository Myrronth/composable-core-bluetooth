import CoreBluetooth

public struct Characteristic {
  let rawValue: CBCharacteristic?
  
  public let uuid: CBUUID
  public let service: Service?
  public let value: Data?
  public let descriptors: () -> [Descriptor]?
  public let properties: CBCharacteristicProperties
  public let isNotifying: Bool

  init(from characteristic: CBCharacteristic) {
    rawValue = characteristic
    uuid = characteristic.uuid
    service = characteristic.service.map(Service.init(from:))
    value = characteristic.value
    descriptors = { characteristic.descriptors?.map(Descriptor.init(from:)) }
    properties = characteristic.properties
    isNotifying = characteristic.isNotifying
  }

  init(
    identifier: CBUUID,
    service: Service?,
    value: Data?,
    descriptors: @escaping () -> [Descriptor]?,
    properties: CBCharacteristicProperties,
    isNotifying: Bool
  ) {
    rawValue = nil
    self.uuid = identifier
    self.service = service
    self.value = value
    self.descriptors = descriptors
    self.properties = properties
    self.isNotifying = isNotifying
  }
}

extension Characteristic: Identifiable {
  public var id: CBUUID { uuid }
}

extension Characteristic: Equatable {
  public static func == (lhs: Characteristic, rhs: Characteristic) -> Bool {
    lhs.rawValue == rhs.rawValue &&
    lhs.uuid == rhs.uuid &&
    lhs.value == rhs.value &&
    lhs.descriptors() == rhs.descriptors() &&
    lhs.properties == rhs.properties &&
    lhs.isNotifying == rhs.isNotifying &&
    // Here we explicitly check for service property without
    // checking its characteristics for equality
    // to avoid recursion which leads to stack overflow
    lhs.service?.rawValue == rhs.service?.rawValue &&
    lhs.service?.uuid == rhs.service?.uuid &&
    lhs.service?.characteristics()?.count == rhs.service?.characteristics()?.count &&
    lhs.service?.includedServices == rhs.service?.includedServices &&
    lhs.service?.isPrimary == rhs.service?.isPrimary
  }
}

extension Characteristic: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(self, children: [
      "rawValue": rawValue as Any,
      "uuid": uuid,
      "service": service as Any,
      "value": value as Any,
      // TODO: How to fix infinite loop?
//      "descriptors": descriptors() as Any,
      "properties": properties,
      "isNotifying": isNotifying
    ], displayStyle: .struct)
  }
}

extension Characteristic {

  public static func mock(
    identifier: CBUUID,
    service: Service?,
    value: Data?,
    descriptors: @escaping () -> [Descriptor]?,
    properties: CBCharacteristicProperties,
    isNotifying: Bool
  ) -> Self {
    return Self(
      identifier: identifier,
      service: service,
      value: value,
      descriptors: descriptors,
      properties: properties,
      isNotifying: isNotifying
    )
  }
}
