import Combine
import ComposableArchitecture
import CoreBluetooth

extension CentralManager {
  public static func mock(
    delegate: @escaping () -> Effect<Action, Never> = {
      _unimplemented("delegate")
    },
    state: @escaping () -> CBManagerState = {
      _unimplemented("state")
    },
    authorization: @escaping () -> CBManagerAuthorization = {
      _unimplemented("authorization")
    },
    connect: @escaping (Peripheral, ConnectionOptions?) -> Effect<Never, Never> = { _, _ in
      _unimplemented("connect")
    },
    cancelPeripheralConnection: @escaping (Peripheral) -> Effect<Never, Never> = { _ in
      _unimplemented("cancelPeripheralConnection")
    },
    retrieveConnectedPeripheralsWithServices: @escaping ([CBUUID]) -> [Peripheral] = { _ in
      _unimplemented("retrieveConnectedPeripheralsWithServices")
    },
    retrievePeripheralsWithIdentifiers: @escaping ([UUID]) -> [Peripheral] = { _ in
      _unimplemented("retrievePeripheralsWithIdentifiers")
    },
    scanForPeripheralsWithServices: @escaping ([CBUUID]?, ScanOptions?) -> Effect<Never, Never> = { _, _ in
      _unimplemented("scanForPeripheralsWithServices")
    },
    stopScan: @escaping () -> Effect<Never, Never> = {
      _unimplemented("stopScan")
    },
    isScanning: @escaping () -> Bool = {
      _unimplemented("isScanning")
    },
    supports: @escaping (CBCentralManager.Feature) -> Bool = { _ in
      _unimplemented("supports")
    },
    registerForConnectionEvents: @escaping (ConnectionEventOptions?) -> Effect<Never, Never> = { _ in
      _unimplemented("registerForConnectionEvents")
    }
  ) -> Self {
    Self(
      delegate: delegate,
      state: state,
      authorization: authorization,
      connect: connect,
      cancelPeripheralConnection: cancelPeripheralConnection,
      retrieveConnectedPeripheralsWithServices: retrieveConnectedPeripheralsWithServices,
      retrievePeripheralsWithIdentifiers: retrievePeripheralsWithIdentifiers,
      scanForPeripheralsWithServices: scanForPeripheralsWithServices,
      stopScan: stopScan,
      isScanning: isScanning,
      supports: supports,
      registerForConnectionEvents: registerForConnectionEvents
    )
  }
}
