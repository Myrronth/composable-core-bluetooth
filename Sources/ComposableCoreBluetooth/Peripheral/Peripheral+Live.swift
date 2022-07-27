import Combine
import ComposableArchitecture
import CoreBluetooth

extension Peripheral {
  /// The live implementation of the `Peripheral` interface. This implementation is capable of
  /// creating real `CBPeripheral` instances, listening to its delegate methods, and invoking
  /// its methods. You will typically use this when building for the device:
  ///
  // TODO: Add example
  public static func live(from peripheral: CBPeripheral) -> Self {
    let identifier = peripheral.identifier
    let delegate = Effect<CentralManager.Action, Never>.run { subscriber in
      let delegate = PeripheralDelegate(subscriber)
      peripheral.delegate = delegate

      return AnyCancellable {
        _ = delegate
      }
    }
      .share()
      .eraseToEffect()

    let deferredStatePublisher = Deferred {
      peripheral
        .publisher(for: \.state)
        .map { CentralManager.Action.peripheral(identifier, .didUpdateState($0)) }
        .eraseToAnyPublisher()
    }
      .share()
      .eraseToEffect()

    let deferredCanSendWriteWithoutResponsePublisher = Deferred {
      peripheral
        .publisher(for: \.canSendWriteWithoutResponse)
        .map{ CentralManager.Action.peripheral(identifier, .didUpdateCanSendWriteWithoutResponse($0)) }
        .eraseToAnyPublisher()
    }
      .share()
      .eraseToEffect()

    let deferredAncsAuthorizedPublisher = Deferred {
      peripheral
        .publisher(for: \.ancsAuthorized)
        .map{ CentralManager.Action.peripheral(identifier, .didUpdateAncsAuthorized($0)) }
        .eraseToAnyPublisher()
    }
      .share()
      .eraseToEffect()
    
    return Self(
      rawValue: peripheral,
      identifier: identifier,
      name: { peripheral.name },
      delegate: { .merge(
        delegate,
        deferredStatePublisher,
        deferredCanSendWriteWithoutResponsePublisher,
        deferredAncsAuthorizedPublisher
      ) },
      discoverServices: { serviceUUIDs in
        .fireAndForget {
          peripheral.discoverServices(serviceUUIDs)
        }
      },
      discoverIncludedServices: { serviceUUIDs, service in
        guard let service = service.rawValue
        else {
          couldNotFindRawServiceValue()
          return .none
        }

        return .fireAndForget {
          peripheral.discoverIncludedServices(serviceUUIDs, for: service)
        }
      },
      services: { peripheral.services?.map(Service.init(from:)) },
      discoverCharacteristics: { characteristicUUIDs, service in
        guard let service = service.rawValue
        else {
          couldNotFindRawServiceValue()
          return .none
        }

        return .fireAndForget {
          peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
      },
      discoverDescriptors: { characteristic in
        guard let characteristic = characteristic.rawValue
        else {
          couldNotFindRawCharacteristicValue()
          return .none
        }

        return .fireAndForget {
          peripheral.discoverDescriptors(for: characteristic)
        }
      },
      readValueForCharateristic: { characteristic in
        guard let characteristic = characteristic.rawValue
        else {
          couldNotFindRawCharacteristicValue()
          return .none
        }

        return .fireAndForget {
          peripheral.readValue(for: characteristic)
        }
      },
      readValueForDescriptor: { descriptor in
        guard let descriptor = descriptor.rawValue
        else {
          couldNotFindRawDescriptorValue()
          return .none
        }

        return .fireAndForget {
          peripheral.readValue(for: descriptor)
        }
      },
      writeValueForCharacteristic: { data, characteristic, characteristicWriteType in
        guard let characteristic = characteristic.rawValue
        else {
          couldNotFindRawCharacteristicValue()
          return .none
        }

        return .fireAndForget {
          peripheral.writeValue(data, for: characteristic, type: characteristicWriteType)
        }
      },
      writeValueForDescriptor: { data, descriptor in
        guard let descriptor = descriptor.rawValue
        else {
          couldNotFindRawDescriptorValue()
          return .none
        }

        return .fireAndForget {
          peripheral.writeValue(data, for: descriptor)
        }
      },
      maximumWriteValueLength: { characteristicWriteType in
        peripheral.maximumWriteValueLength(for: characteristicWriteType)
      },
      setNotifyValue: { enabled, characteristic in
        guard let characteristic = characteristic.rawValue
        else {
          couldNotFindRawCharacteristicValue()
          return .none
        }

        return .fireAndForget {
          peripheral.setNotifyValue(enabled, for: characteristic)
        }
      },
      state: { peripheral.state },
      canSendWriteWithoutResponse: { peripheral.canSendWriteWithoutResponse },
      readRSSI: {
        .fireAndForget {
          peripheral.readRSSI()
        }
      },
      openL2CAPChannel: { PSM in
        .fireAndForget {
          peripheral.openL2CAPChannel(PSM)
        }
      },
      ancsAuthorized: { peripheral.canSendWriteWithoutResponse }
    )
  }
}

private class PeripheralDelegate: NSObject, CBPeripheralDelegate {
  let subscriber: Effect<CentralManager.Action, Never>.Subscriber

  init(_ subscriber: Effect<CentralManager.Action, Never>.Subscriber) {
    self.subscriber = subscriber
  }

  // Discovering Services

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didDiscoverServices(.init(error))
    ))
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didDiscoverIncludedServicesFor(Service.init(from: service), .init(error))
    ))
  }

  // Discovering Characteristics and their Descriptors

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didDiscoverCharacteristicsFor(Service.init(from: service), .init(error))
    ))
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverDescriptorsFor characteristic: CBCharacteristic,
    error: Swift.Error?
  ) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didDiscoverDescriptorsFor(Characteristic.init(from: characteristic), .init(error))
    ))
  }

  // Retrieving Characteristic and Descriptor Values

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didUpdateValueForCharacteristic(Characteristic.init(from: characteristic), .init(error))
    ))
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didUpdateValueForDescriptor(Descriptor.init(from: descriptor), .init(error))
    ))
  }

  // Writing Characteristic and Descriptor Values

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didWriteValueForCharacteristic(Characteristic.init(from: characteristic), .init(error))
    ))
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didWriteValueForDescriptor(Descriptor.init(from: descriptor), .init(error))
    ))
  }

  func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .isReadyToSendWriteWithoutResponse
    ))
  }

  // Managing Notifications for a Characteristic’s Value

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateNotificationStateFor characteristic: CBCharacteristic,
    error: Swift.Error?
  ) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didUpdateNotificationStateFor(Characteristic.init(from: characteristic), .init(error))
    ))
  }

  // Retrieving a Peripheral’s RSSI Data

  func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didReadRSSI(RSSI, .init(error))
    ))
  }

  // Monitoring Changes to a Peripheral’s Name or Services

  func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didUpdateName
    ))
  }

  func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didModifyServices(invalidatedServices.map(Service.init(from:)))
    ))
  }

  // Monitoring L2CAP Channels

  func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didOpen(channel, .init(error))
    ))
  }

}
