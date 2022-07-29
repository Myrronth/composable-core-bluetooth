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
  fileprivate(set) var services: [Service]?

  fileprivate var automaticallyDiscoverDescriptorsAfterCharacteristicsAreDiscovered = false

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
  case onAppear
  case onDisappear

  case connect
  case disconnect
  case discoverServices([CBUUID]?)
  case discoverIncludedServices([CBUUID]?, Service)
  case discoverCharacteristicsAndDescriptors([CBUUID]?, Service)

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
        .connect(state.peripheral)
        .fireAndForget()

    case .disconnect:
      return environment.bluetoothManager
        .cancelPeripheralConnection(state.peripheral)
        .fireAndForget()

    case let .discoverServices(serviceUUIDs):
      return state.peripheral
        .discoverServices(serviceUUIDs)
        .fireAndForget()

    case let .discoverIncludedServices(serviceUUIDs, service):
      return state.peripheral
        .discoverIncludedServices(serviceUUIDs, service)
        .fireAndForget()

    case let .discoverCharacteristicsAndDescriptors(characteristicUUIDs, service):
      state.automaticallyDiscoverDescriptorsAfterCharacteristicsAreDiscovered = true
      return state.peripheral
        .discoverCharacteristics(characteristicUUIDs, service)
        .fireAndForget()

    case let .bluetoothManager(.didConnect(peripheral)):
      return connectedEffect(peripheral)

    case let .bluetoothManager(.peripheral(identifier, .didReadRSSI(rssi, error))):
      guard identifier == state.peripheral.identifier
      else { return .none }

      if error == nil {
        state.rssi = rssi
      }
      return .none

    case let .bluetoothManager(.peripheral(identifier, .didUpdateState(peripheralState))):
      guard identifier == state.peripheral.identifier
      else { return .none }

      state.peripheralState = peripheralState
      return .none

    case let .bluetoothManager(.peripheral(identifier, .didDiscoverServices(error))):
      guard identifier == state.peripheral.identifier
      else { return .none }

      if error == nil {
        state.services = state.peripheral.services() ?? []
      }
      return .none

    case let .bluetoothManager(.peripheral(identifier, .didDiscoverIncludedServicesFor(service, error))):
      guard identifier == state.peripheral.identifier
      else { return .none }

      if error == nil {
        state.services = state.peripheral.services() ?? []
      }
      return .none

    case let .bluetoothManager(.peripheral(identifier, .didDiscoverCharacteristicsFor(service, error))):
      guard identifier == state.peripheral.identifier
      else { return .none }

      if error == nil {
        state.services = state.peripheral.services() ?? []

        if
          let services = state.services,
          state.automaticallyDiscoverDescriptorsAfterCharacteristicsAreDiscovered
        {
          let effects: [Effect<PeripheralAction, Never>] = services
            .flatMap { service in
              service.characteristics() ?? []
            }
            .map { characteristic in
              state.peripheral
                .discoverDescriptors(characteristic)
                .fireAndForget()
            }

          return .merge(effects)
        }
      }
      return .none

    case let .bluetoothManager(.peripheral(identifier, .didDiscoverDescriptorsFor(characteristic, error))):
      guard identifier == state.peripheral.identifier
      else { return .none }

      state.automaticallyDiscoverDescriptorsAfterCharacteristicsAreDiscovered = false
      if error == nil {
        state.services = state.peripheral.services() ?? []
      }
      return .none

    case .bluetoothManager:
      return .none
  }
}
