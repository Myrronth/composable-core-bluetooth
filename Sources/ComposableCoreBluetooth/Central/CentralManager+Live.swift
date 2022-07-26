import Combine
import ComposableArchitecture
import CoreBluetooth

extension CentralManager {
  /// The live implementation of the `CentralManager` interface. This implementation is capable of
  /// creating real `CBCentralManager` instances, listening to its delegate methods, and invoking
  /// its methods. You will typically use this when building for the device:
  ///
  /// ```swift
  /// let store = Store(
  ///   initialState: AppState(),
  ///   reducer: appReducer,
  ///   environment: AppEnvironment(
  ///     centralManager: CentralManager.live()
  ///   )
  /// )
  /// ```
  public static func live(queue: DispatchQueue? = nil, options: InitializationOptions? = nil) -> Self {
    let manager = CBCentralManager(delegate: nil, queue: queue, options: options?.toDictionary())
    let delegate = Effect<CentralManager.Action, Never>.run { subscriber in
      let delegate = CentralManagerDelegate(subscriber)
      manager.delegate = delegate

      return AnyCancellable {
        _ = delegate
      }
    }
      .share()
      .eraseToEffect()

    let deferredIsScanningStatePublisher = Deferred {
      manager
        .publisher(for: \.isScanning)
        .map(CentralManager.Action.didUpdateScanningState)
        .eraseToAnyPublisher()
    }
    .share()
    .eraseToEffect()

    let deferredAuthorizationStatePublisher = Deferred {
      manager
        .publisher(for: \.authorization)
        .map(CentralManager.Action.didUpdateAuthorizationState)
        .eraseToAnyPublisher()
    }
      .share()
      .eraseToEffect()

    return Self(
      delegate: { .merge(
        delegate,
        deferredIsScanningStatePublisher,
        deferredAuthorizationStatePublisher
      ) },
      state: { manager.state },
      authorization: {
        if #available(iOS 13.1, *) {
          return CBCentralManager.authorization
        } else {
          return manager.authorization
        }
      },
      connect: { peripheral, options in
        guard let peripheral = peripheral.rawValue
        else {
          couldNotFindRawPeripheralValue()
          return .none
        }

        return .fireAndForget {
          manager.connect(peripheral, options: options?.toDictionary())
        }
      },
      cancelPeripheralConnection: { peripheral in
        guard let peripheral = peripheral.rawValue
        else {
          couldNotFindRawPeripheralValue()
          return .none
        }

        return .fireAndForget {
          manager.cancelPeripheralConnection(peripheral)
        }
      },
      retrieveConnectedPeripheralsWithServices: { services in
        manager.retrieveConnectedPeripherals(withServices: services).map(Peripheral.live(from:))
      },
      retrievePeripheralsWithIdentifiers: { identifiers in
        manager.retrievePeripherals(withIdentifiers: identifiers).map(Peripheral.live(from:))
      },
      scanForPeripheralsWithServices: { services, options in
        .fireAndForget {
          manager.scanForPeripherals(withServices: services, options: options?.toDictionary())
        }
      },
      stopScan: {
        .fireAndForget {
          manager.stopScan()
        }
      },
      isScanning: { manager.isScanning },
      supports: { CBCentralManager.supports($0) },
      registerForConnectionEvents: { options in
        .fireAndForget {
          manager.registerForConnectionEvents(options: options?.toDictionary())
        }
      }
    )
  }
}

private class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
  let subscriber: Effect<CentralManager.Action, Never>.Subscriber

  init(_ subscriber: Effect<CentralManager.Action, Never>.Subscriber) {
    self.subscriber = subscriber
  }

  // Monitoring Connections with Peripherals

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    subscriber.send(.didConnect(Peripheral.live(from: peripheral)))
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Swift.Error?
  ) {
    subscriber.send(.didDisconnectPeripheral(Peripheral.live(from: peripheral), error: error.map(Error.init)))
  }

  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Swift.Error?) {
    subscriber.send(.didFailToConnect(Peripheral.live(from: peripheral), error: error.map(Error.init)))
  }

  func centralManager(
    _ central: CBCentralManager,
    connectionEventDidOccur event: CBConnectionEvent,
    for peripheral: CBPeripheral
  ) {
    subscriber.send(.connectionEventDidOccur(event, peripheral: Peripheral.live(from: peripheral)))
  }

  // Discovering and Retrieving Peripherals

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String : Any],
    rssi RSSI: NSNumber
  ) {
    subscriber.send(.didDiscover(
      Peripheral.live(from: peripheral),
      advertismentData: .init(from: advertisementData),
      rssi: RSSI
    ))
  }

  // Monitoring the Central Manager’s State

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    subscriber.send(.didUpdateState(central.state))
  }

  func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    subscriber.send(.willRestoreState(.init(from: dict)))
  }

  // Monitoring the Central Manager’s Authorization

  func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
    subscriber.send(.didUpdateANCSAuthorizationFor(Peripheral.live(from: peripheral)))
  }

}
