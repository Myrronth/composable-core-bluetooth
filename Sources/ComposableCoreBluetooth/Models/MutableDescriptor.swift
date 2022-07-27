import CoreBluetooth

public struct MutableDescriptor {
  public var uuid: CBUUID { value.cbuuid }
  public let value: Descriptor.Value

  public var rawValue: CBMutableDescriptor {
    CBMutableDescriptor(type: value.cbuuid, value: value.associatedValue)
  }

  init(value: Descriptor.Value) {
    self.value = value
  }
}
