import Combine
import ComposableArchitecture
import CoreBluetooth

extension Peripheral {
  public static func mock(
    identifier: UUID,
    name: @escaping () -> String? = {
      _unimplemented("name")
    },
    delegate: @escaping () -> Effect<CentralManager.Action, Never> = {
      _unimplemented("delegate")
    },
    discoverServices: @escaping ([CBUUID]?) -> Effect<Never, Never> = { _ in
      _unimplemented("discoverServices")
    },
    discoverIncludedServices: @escaping ([CBUUID]?, Service) -> Effect<Never, Never> = { _, _ in
      _unimplemented("discoverIncludedServices")
    },
    services: @escaping () -> [Service]? = {
      _unimplemented("services")
    },
    discoverCharacteristics: @escaping ([CBUUID]?, Service) -> Effect<Never, Never> = { _, _ in
      _unimplemented("discoverCharacteristics")
    },
    discoverDescriptors: @escaping (Characteristic) -> Effect<Never, Never> = { _ in
      _unimplemented("discoverDescriptors")
    },
    readValueForCharateristic: @escaping (Characteristic) -> Effect<Never, Never> = { _ in
      _unimplemented("readValueForCharateristic")
    },
    readValueForDescriptor: @escaping (Descriptor) -> Effect<Never, Never> = { _ in
      _unimplemented("readValueForDescriptor")
    },
    writeValueForCharacteristic: @escaping (Data, Characteristic, CBCharacteristicWriteType)
    -> Effect<Never, Never> = { _, _, _ in
      _unimplemented("writeValueForCharacteristic")
    },
    writeValueForDescriptor: @escaping (Data, Descriptor) -> Effect<Never, Never> = { _, _ in
      _unimplemented("writeValueForDescriptor")
    },
    maximumWriteValueLength: @escaping (CBCharacteristicWriteType) -> Int = { _ in
      _unimplemented("maximumWriteValueLength")
    },
    setNotifyValue: @escaping (Bool, Characteristic) -> Effect<Never, Never> = { _, _ in
      _unimplemented("setNotifyValue")
    },
    state: @escaping () -> CBPeripheralState = {
      _unimplemented("state")
    },
    canSendWriteWithoutResponse: @escaping () -> Bool = {
      _unimplemented("canSendWriteWithoutResponse")
    },
    readRSSI: @escaping () -> Effect<Never, Never> = {
      _unimplemented("readRSSI")
    },
    openL2CAPChannel: @escaping (CBL2CAPPSM) -> Effect<Never, Never> = { _ in
      _unimplemented("openL2CAPChannel")
    },
    ancsAuthorized: @escaping () -> Bool = {
      _unimplemented("ancsAuthorized")
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
