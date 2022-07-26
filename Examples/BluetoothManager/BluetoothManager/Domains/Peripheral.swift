import ComposableArchitecture
import ComposableCoreBluetooth
import CoreBluetooth

struct PeripheralState: Equatable, Identifiable {
  let id: UUID
  fileprivate(set) var peripheralState: CBPeripheralState
  let peripheral: Peripheral
  let advertismentData: CentralManager.AdvertismentData?
  fileprivate(set) var rssi: NSNumber?
  let cancellableID: AnyHashable

  init(
    id: UUID,
    peripheral: Peripheral,
    advertismentData: CentralManager.AdvertismentData? = nil,
    rssi: NSNumber? = nil,
    cancellableID: AnyHashable
  ) {
    self.id = id
    self.peripheralState = peripheral.state()
    self.peripheral = peripheral
    self.advertismentData = advertismentData
    self.rssi = rssi
    self.cancellableID = cancellableID
  }
}

enum PeripheralAction: Equatable {
  // TODO: Whats the best way to make certain actions "private"?
  case onAppear
  case onDisappear

  case connect
  case disconnect
  case bluetoothManager(CentralManager.Action)
}

struct PeripheralEnvironment {
  let bluetoothManager: CentralManager
}

private func connectedEffect(_ peripheral: Peripheral) -> Effect<PeripheralAction, Never> {
  return peripheral
    .readRSSI()
    .fireAndForget()
}

let peripheralReducer =
Reducer<PeripheralState, PeripheralAction, PeripheralEnvironment> { state, action, environment in
  switch action {
    case .onAppear:
      let peripheral = state.peripheral

      var effects: Effect<PeripheralAction, Never> = .merge(
        environment.bluetoothManager
          .delegate()
          .map(PeripheralAction.bluetoothManager),
        state.peripheral
          .delegate()
          .map(PeripheralAction.bluetoothManager)
      )
        .cancellable(id: state.cancellableID)

      if peripheral.state() == .connected {
        effects = .merge(effects, connectedEffect(peripheral))
      }

      return effects

    case .onDisappear:
      // TODO: Wait for https://github.com/pointfreeco/swift-composable-architecture/pull/1189
      return .none

    case .connect:
      return environment.bluetoothManager
        .connect(state.peripheral, nil)
        .fireAndForget()

    case .disconnect:
      return environment.bluetoothManager
        .cancelPeripheralConnection(state.peripheral)
        .fireAndForget()

    case let .bluetoothManager(.didConnect(peripheral)):
      return connectedEffect(peripheral)

    case let .bluetoothManager(.peripheral(identifier, .didReadRSSI(rssi, error))):
      state.rssi = rssi
      return .none

    case let .bluetoothManager(.peripheral(identifier, .didUpdateState(peripheralState))):
      state.peripheralState = peripheralState
      return .none

    case .bluetoothManager:
      return .none
  }
}
