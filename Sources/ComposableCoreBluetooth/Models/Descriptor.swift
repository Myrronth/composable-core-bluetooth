import CoreBluetooth

public struct Descriptor: Equatable {
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
        case .characteristicExtendedProperties(let number): return number
        case .characteristicUserDescription(let string): return string
        case .clientCharacteristicConfiguration(let number): return number
        case .serverCharacteristicConfiguration(let number): return number
        case .characteristicFormat(let data): return data
        case .characteristicAggregateFormat(let data): return data
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

extension Descriptor {

  public static func mock(identifier: CBUUID, characteristic: Characteristic?, value: Value?) -> Self {
    return Self(
      identifier: identifier,
      characteristic: characteristic,
      value: value
    )
  }
}
