import CoreBluetooth

public struct MutableCharacteristic {
  public let uuid: CBUUID
  public var value: Data?
  public var descriptors: [MutableDescriptor]?
  public var properties: CBCharacteristicProperties
  public var permissions: CBAttributePermissions

  public var rawValue: CBMutableCharacteristic {
    let mutableCharacteristic = CBMutableCharacteristic(
      type: uuid,
      properties: properties,
      value: value,
      permissions: permissions
    )
    mutableCharacteristic.descriptors = descriptors?.map(\.rawValue)
    return mutableCharacteristic
  }

  init(
    type: CBUUID,
    properties: CBCharacteristicProperties,
    value: Data?,
    permissions: CBAttributePermissions
  ) {
    self.uuid = type
    self.properties = properties
    self.value = value
    self.permissions = permissions
  }
}
