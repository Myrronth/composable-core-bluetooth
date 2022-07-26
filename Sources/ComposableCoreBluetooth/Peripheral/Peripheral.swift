import ComposableArchitecture
import CoreBluetooth

public struct Peripheral {
  /// Actions that correspond to `CBPeripheralDelegate` methods.
  ///
  /// See `CBPeripheralDelegate` for more information.
  public enum Action: Equatable {
    // Discovering Services
    case didDiscoverServices(Error?)
    case didDiscoverIncludedServicesFor(CBService, Error?)

    // Discovering Characteristics and their Descriptors
    case didDiscoverCharacteristicFor(CBService, Error?)
    case didDiscoverDescriptorsFor(CBCharacteristic, Error?)

    // Retrieving Characteristic and Descriptor Values
    case didUpdateValueForCharacteristic(CBCharacteristic, Error?)
    case didUpdateValueForDescriptor(CBDescriptor, Error?)

    // Writing Characteristic and Descriptor Values
    case didWriteValueForCharacteristic(CBCharacteristic, Error?)
    case didWriteValueForDescriptor(CBDescriptor, Error?)
    case isReadyToSendWriteWithoutResponse

    // Managing Notifications for a Characteristic’s Value
    case didUpdateNotificationStateFor(CBCharacteristic, Error?)

    // Retrieving a Peripheral’s RSSI Data
    case didReadRSSI(NSNumber, Error?)

    // Monitoring Changes to a Peripheral’s Properties
    case didUpdateName
    case didModifyServices([CBService])
    case didUpdateState(CBPeripheralState)
    case didUpdateCanSendWriteWithoutResponse(Bool)
    case didUpdateAncsAuthorized(Bool)

    // Monitoring L2CAP Channels
    case didOpen(CBL2CAPChannel?, Error?)
  }

  public var rawValue: CBPeripheral?

  // Identifying a Peripheral
  public var identifier: UUID
  public var name: () -> String?
  public var delegate: () -> Effect<CentralManager.Action, Never>

  // Discovering Services
  public var discoverServices: ([CBUUID]?) -> Effect<Never, Never>
  public var discoverIncludedServices: ([CBUUID]?, CBService) -> Effect<Never, Never>
  public var services: () -> [CBService]?

  // Discovering Characteristics and Descriptors
  public var discoverCharacteristics: ([CBUUID]?, CBService) -> Effect<Never, Never>
  public var discoverDescriptors: (CBCharacteristic) -> Effect<Never, Never>

  // Reading Characteristic and Descriptor Values
  public var readValueForCharateristic: (CBCharacteristic) -> Effect<Never, Never>
  public var readValueForDescriptor: (CBDescriptor) -> Effect<Never, Never>

  // Writing Characteristic and Descriptor Values
  public var writeValueForCharacteristic: (Data, CBCharacteristic, CBCharacteristicWriteType) -> Effect<Never, Never>
  public var writeValueForDescriptor: (Data, CBDescriptor) -> Effect<Never, Never>
  public var maximumWriteValueLength: (CBCharacteristicWriteType) -> Int

  // Setting Notifications for a Characteristic’s Value
  public var setNotifyValue: (Bool, CBCharacteristic) -> Effect<Never, Never>

  // Monitoring a Peripheral’s Connection State
  public var state: () -> CBPeripheralState
  public var canSendWriteWithoutResponse: () -> Bool

  // Accessing a Peripheral’s Signal Strength
  public var readRSSI: () -> Effect<Never, Never>

  // Working with L2CAP Channels
  public var openL2CAPChannel: (CBL2CAPPSM) -> Effect<Never, Never>

  // Working with Apple Notification Center Service (ANCS)
  public var ancsAuthorized: () -> Bool
}

extension Peripheral: Equatable {
  public static func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
    lhs.identifier == rhs.identifier &&
    lhs.name() == rhs.name() &&
    lhs.services() == rhs.services() &&
    lhs.state() == rhs.state() &&
    lhs.canSendWriteWithoutResponse() == rhs.canSendWriteWithoutResponse() &&
    lhs.ancsAuthorized() == rhs.ancsAuthorized()
  }

}
