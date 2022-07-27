import CoreBluetooth

public struct Characteristic: Equatable {
  let rawValue: CBCharacteristic?
  
  public let uuid: CBUUID
  public let service: Service?
  public let value: Data?
  public let descriptors: [Descriptor]?
  public let properties: CBCharacteristicProperties
  public let isNotifying: Bool

  init(from characteristic: CBCharacteristic) {
    rawValue = characteristic
    uuid = characteristic.uuid
    service = characteristic.service.map(Service.init(from:))
    value = characteristic.value
    descriptors = characteristic.descriptors?.map(Descriptor.init(from:))
    properties = characteristic.properties
    isNotifying = characteristic.isNotifying
  }

  init(
    identifier: CBUUID,
    service: Service?,
    value: Data?,
    descriptors: [Descriptor]?,
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

extension Characteristic {

  public static func mock(
    identifier: CBUUID,
    service: Service?,
    value: Data?,
    descriptors: [Descriptor]?,
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
