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

    let deferred = Deferred {
      peripheral
        .publisher(for: \.state)
        .map { state in
          CentralManager.Action.peripheral(identifier, .didUpdateState(state))
        }
        .eraseToAnyPublisher()
    }
      .share()
      .eraseToEffect()
    
    return Self(
      rawValue: peripheral,
      identifier: identifier,
      name: { peripheral.name },
      delegate: { .merge(delegate, deferred) },
      discoverServices: { serviceUUIDs in
        .fireAndForget {
          peripheral.discoverServices(serviceUUIDs)
        }
      },
      discoverIncludedServices: { serviceUUIDs, service in
        .fireAndForget {
          peripheral.discoverIncludedServices(serviceUUIDs, for: service)
        }
      },
      services: { peripheral.services },
      discoverCharacteristics: { characteristicUUIDs, service in
        .fireAndForget {
          peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
      },
      discoverDescriptors: { characteristic in
        .fireAndForget {
          peripheral.discoverDescriptors(for: characteristic)
        }
      },
      readValueForCharateristic: { characteristic in
        .fireAndForget {
          peripheral.readValue(for: characteristic)
        }
      },
      readValueForDescriptor: { descriptor in
        .fireAndForget {
          peripheral.readValue(for: descriptor)
        }
      },
      writeValueForCharacteristic: { data, characteristic, characteristicWriteType in
        .fireAndForget {
          peripheral.writeValue(data, for: characteristic, type: characteristicWriteType)
        }
      },
      writeValueForDescriptor: { data, descriptor in
        .fireAndForget {
          peripheral.writeValue(data, for: descriptor)
        }
      },
      maximumWriteValueLength: { characteristicWriteType in
        peripheral.maximumWriteValueLength(for: characteristicWriteType)
      },
      setNotifyValue: { enabled, characteristic in
        .fireAndForget {
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
      .didDiscoverIncludedServicesFor(service, .init(error))
    ))
  }

  // Discovering Characteristics and their Descriptors

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didDiscoverCharacteristicFor(service, .init(error))
    ))
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverDescriptorsFor characteristic: CBCharacteristic,
    error: Swift.Error?
  ) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didDiscoverDescriptorsFor(characteristic, .init(error))
    ))
  }

  // Retrieving Characteristic and Descriptor Values

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didUpdateValueForCharacteristic(characteristic, .init(error))
    ))
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didUpdateValueForDescriptor(descriptor, .init(error))
    ))
  }

  // Writing Characteristic and Descriptor Values

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didWriteValueForCharacteristic(characteristic, .init(error))
    ))
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Swift.Error?) {
    subscriber.send(.peripheral(
      peripheral.identifier,
      .didWriteValueForDescriptor(descriptor, .init(error))
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
      .didUpdateNotificationStateFor(characteristic, .init(error))
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
      .didModifyServices(invalidatedServices)
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
