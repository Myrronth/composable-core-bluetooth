import Combine
import ComposableArchitecture
import CoreBluetooth

extension Peripheral {
  public static func failing(
    identifier: UUID,
    name: @escaping () -> String? = {
      _fail("name")
      return nil
    },
    delegate: @escaping () -> Effect<CentralManager.Action, Never> = {
      .unimplemented("delegate")
    },
    discoverServices: @escaping ([CBUUID]?) -> Effect<Never, Never> = { _ in
      .unimplemented("discoverServices")
    },
    discoverIncludedServices: @escaping ([CBUUID]?, Service) -> Effect<Never, Never> = { _, _ in
      .unimplemented("discoverIncludedServices")
    },
    services: @escaping () -> [Service]? = {
      _fail("services")
      return nil
    },
    discoverCharacteristics: @escaping ([CBUUID]?, Service) -> Effect<Never, Never> = { _, _ in
      .unimplemented("discoverCharacteristics")
    },
    discoverDescriptors: @escaping (Characteristic) -> Effect<Never, Never> = { _ in
      .unimplemented("discoverDescriptors")
    },
    readValueForCharateristic: @escaping (Characteristic) -> Effect<Never, Never> = { _ in
      .unimplemented("readValueForCharateristic")
    },
    readValueForDescriptor: @escaping (Descriptor) -> Effect<Never, Never> = { _ in
      .unimplemented("readValueForDescriptor")
    },
    writeValueForCharacteristic: @escaping (Data, Characteristic, CBCharacteristicWriteType)
    -> Effect<Never, Never> = { _, _, _ in
      .unimplemented("writeValueForCharacteristic")
    },
    writeValueForDescriptor: @escaping (Data, Descriptor) -> Effect<Never, Never> = { _, _ in
      .unimplemented("writeValueForDescriptor")
    },
    maximumWriteValueLength: @escaping (CBCharacteristicWriteType) -> Int = { _ in
      _fail("maximumWriteValueLength")
      return 0
    },
    setNotifyValue: @escaping (Bool, Characteristic) -> Effect<Never, Never> = { _, _ in
      .unimplemented("setNotifyValue")
    },
    state: @escaping () -> CBPeripheralState = {
      _fail("state")
      return .disconnected
    },
    canSendWriteWithoutResponse: @escaping () -> Bool = {
      _fail("canSendWriteWithoutResponse")
      return false
    },
    readRSSI: @escaping () -> Effect<Never, Never> = {
      .unimplemented("readRSSI")
    },
    openL2CAPChannel: @escaping (CBL2CAPPSM) -> Effect<Never, Never> = { _ in
      .unimplemented("openL2CAPChannel")
    },
    ancsAuthorized: @escaping () -> Bool = {
      _fail("ancsAuthorized")
      return false
    }
  ) -> Self {
    Self(
      identifier: identifier,
      name: name,
      delegate: delegate,
      discoverServices: discoverServices,
      discoverIncludedServices: discoverIncludedServices,
      services: services,
      discoverCharacteristics: discoverCharacteristics,
      discoverDescriptors: discoverDescriptors,
      readValueForCharateristic: readValueForCharateristic,
      readValueForDescriptor: readValueForDescriptor,
      writeValueForCharacteristic: writeValueForCharacteristic,
      writeValueForDescriptor: writeValueForDescriptor,
      maximumWriteValueLength: maximumWriteValueLength,
      setNotifyValue: setNotifyValue,
      state: state,
      canSendWriteWithoutResponse: canSendWriteWithoutResponse,
      readRSSI: readRSSI,
      openL2CAPChannel: openL2CAPChannel,
      ancsAuthorized: ancsAuthorized
    )
  }
}
