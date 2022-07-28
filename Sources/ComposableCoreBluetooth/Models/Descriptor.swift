import CoreBluetooth

public struct Descriptor {
  let rawValue: CBDescriptor?

  public let uuid: CBUUID
  public let characteristic: Characteristic?
  public let value: Value?

  init(from descriptor: CBDescriptor) {
    rawValue = descriptor
    uuid = descriptor.uuid
    characteristic = descriptor.characteristic.map(Characteristic.init(from:))
    value = Self.anyToValue(uuid: uuid, descriptor.value)
  }

  init(identifier: CBUUID, characteristic: Characteristic?, value: Value?) {
    rawValue = nil
    self.uuid = identifier
    self.characteristic = characteristic
    self.value = value
  }

  static func anyToValue(uuid: CBUUID, _ value: Any?) -> Value? {
    switch uuid.uuidString {
      case CBUUIDCharacteristicExtendedPropertiesString: return .characteristicExtendedProperties(value as? NSNumber)
      case CBUUIDCharacteristicUserDescriptionString: return .characteristicUserDescription(value as? String)
      case CBUUIDClientCharacteristicConfigurationString: return .clientCharacteristicConfiguration(value as? NSNumber)
      case CBUUIDServerCharacteristicConfigurationString: return .serverCharacteristicConfiguration(value as? NSNumber)
      case CBUUIDCharacteristicFormatString: return .characteristicFormat(value as? Data)
      case CBUUIDCharacteristicAggregateFormatString: return .characteristicAggregateFormat(value as? Data)
      default: return nil
    }
  }
}

extension Descriptor {
  public enum Value: Equatable {
    case characteristicExtendedProperties(NSNumber?)
    case characteristicUserDescription(String?)
    case clientCharacteristicConfiguration(NSNumber?)
    case serverCharacteristicConfiguration(NSNumber?)
    case characteristicFormat(Data?)
    case characteristicAggregateFormat(Data?)

    var associatedValue: Any? {
      switch self {
        case let .characteristicExtendedProperties(number): return number
        case let .characteristicUserDescription(string): return string
        case let .clientCharacteristicConfiguration(number): return number
        case let .serverCharacteristicConfiguration(number): return number
        case let .characteristicFormat(data): return data
        case let .characteristicAggregateFormat(data): return data
      }
    }

    var cbuuid: CBUUID {
      switch self {
        case .characteristicExtendedProperties: return CBUUID(string: CBUUIDCharacteristicExtendedPropertiesString)
        case .characteristicUserDescription: return CBUUID(string: CBUUIDCharacteristicUserDescriptionString)
        case .clientCharacteristicConfiguration: return CBUUID(string: CBUUIDClientCharacteristicConfigurationString)
        case .serverCharacteristicConfiguration: return CBUUID(string: CBUUIDServerCharacteristicConfigurationString)
        case .characteristicFormat: return CBUUID(string: CBUUIDCharacteristicFormatString)
        case .characteristicAggregateFormat: return CBUUID(string: CBUUIDCharacteristicAggregateFormatString)
      }
    }
  }
}

extension Descriptor: Identifiable {
  public var id: CBUUID { uuid }
}

extension Descriptor: Equatable {
  public static func == (lhs: Descriptor, rhs: Descriptor) -> Bool {
    lhs.rawValue == rhs.rawValue &&
    lhs.uuid == rhs.uuid &&
    lhs.value == rhs.value &&
    // Here we explicitly check for characteristic property without
    // checking its descriptors for equality
    // to avoid recursion which leads to stack overflow
    lhs.characteristic?.rawValue == rhs.characteristic?.rawValue &&
    lhs.characteristic?.uuid == rhs.characteristic?.uuid &&
    lhs.characteristic?.value == rhs.characteristic?.value &&
    lhs.characteristic?.descriptors()?.count == rhs.characteristic?.descriptors()?.count &&
    lhs.characteristic?.properties == rhs.characteristic?.properties &&
    lhs.characteristic?.isNotifying == rhs.characteristic?.isNotifying &&
    // Here we explicitly check for service property without
    // checking its characteristics for equality
    // to avoid recursion which leads to stack overflow
    lhs.characteristic?.service?.rawValue == rhs.characteristic?.service?.rawValue &&
    lhs.characteristic?.service?.uuid == rhs.characteristic?.service?.uuid &&
    lhs.characteristic?.service?.characteristics()?.count == rhs.characteristic?.service?.characteristics()?.count &&
    lhs.characteristic?.service?.includedServices == rhs.characteristic?.service?.includedServices &&
    lhs.characteristic?.service?.isPrimary == rhs.characteristic?.service?.isPrimary
  }
}

extension Descriptor {

  public static func mock(identifier: CBUUID, characteristic: Characteristic?, value: Value?) -> Self {
    return Self(
      identifier: identifier,
      characteristic: characteristic,
      value: value
    )
  }
}
