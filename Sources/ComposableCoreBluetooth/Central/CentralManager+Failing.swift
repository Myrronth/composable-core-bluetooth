import Combine
import ComposableArchitecture
import CoreBluetooth

extension CentralManager {
  public static func failing(
    delegate: @escaping () -> Effect<Action, Never> = {
      .unimplemented("delegate")
    },
    state: @escaping () -> CBManagerState = {
      _fail("state")
      return .unknown
    },
    authorization: @escaping () -> CBManagerAuthorization = {
      _fail("authorization")
      return .notDetermined
    },
    connect: @escaping (Peripheral, ConnectionOptions?) -> Effect<Never, Never> = { _, _ in
        .unimplemented("connect")
    },
    cancelPeripheralConnection: @escaping (Peripheral) -> Effect<Never, Never> = { _ in
        .unimplemented("cancelPeripheralConnection")
    },
    retrieveConnectedPeripheralsWithServices: @escaping ([CBUUID]) -> [Peripheral] = { _ in
      _fail("retrieveConnectedPeripheralsWithServices")
      return []
    },
    retrievePeripheralsWithIdentifiers: @escaping ([UUID]) -> [Peripheral] = { _ in
      _fail("retrievePeripheralsWithIdentifiers")
      return []
    },
    scanForPeripheralsWithServices: @escaping ([CBUUID]?, ScanOptions?) -> Effect<Never, Never> = { _, _ in
        .unimplemented("scanForPeripheralsWithServices")
    },
    stopScan: @escaping () -> Effect<Never, Never> = {
      .unimplemented("stopScan")
    },
    isScanning: @escaping () -> Bool = {
      _fail("isScanning")
      return false
    },
    supports: @escaping (CBCentralManager.Feature) -> Bool = { _ in
      _fail("supports")
      return false
    },
    registerForConnectionEvents: @escaping (ConnectionEventOptions?) -> Effect<Never, Never> = { _ in
        .unimplemented("registerForConnectionEvents")
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
