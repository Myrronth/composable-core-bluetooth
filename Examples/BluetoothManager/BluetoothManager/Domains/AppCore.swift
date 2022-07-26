import ComposableArchitecture
import ComposableCoreBluetooth
import CoreBluetooth

enum Config {
  enum Bluetooth {
    static let allowDuplicatesAndUndiscover = false
    static let undiscoverAfterSeconds = 5
    static let splitDiscoveredAndConnectedPeripherals = true
  }
}

struct AppState: Equatable {
  var shouldStartBluetoothScanningWhenPoweredOn = false
  var isBluetoothScanning: Bool

  var discoveredPeripherals: IdentifiedArrayOf<PeripheralState> = []
  var connectedPeripherals: IdentifiedArrayOf<PeripheralState> = []
}

enum AppAction: Equatable {
  case onAppear
  case startBluetoothScan
  case stopBluetoothScan

  case removeDiscoveredPeripheral(UUID)
  case _removeDiscoveredPeripheral(UUID)
  case removeAllDiscoveredPeripherals
  case _removeAllDiscoveredPeripherals
  case removeConnectedPeripheral(UUID)
  case _removeConnectedPeripheral(UUID)

  case bluetoothManager(CentralManager.Action)

  case discoveredPeripheralListItem(id: PeripheralState.ID, action: PeripheralAction)
  case connectedPeripheralListItem(id: PeripheralState.ID, action: PeripheralAction)
}

struct AppEnvironment {
  let bluetoothManager: CentralManager
  let mainQueue: AnySchedulerOf<DispatchQueue>
}

private func scanForPeripheralsEffect(_ bluetoothManager: CentralManager) -> Effect<AppAction, Never> {
  return bluetoothManager
    .scanForPeripheralsWithServices([
      CBUUID(string: "89145240-0C04-4713-96A4-0C88F15D6120")
    ], .init(
      allowDuplicates: Config.Bluetooth.allowDuplicatesAndUndiscover
    ))
    .fireAndForget()
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  peripheralReducer.forEach(
    state: \.discoveredPeripherals,
    action: /AppAction.discoveredPeripheralListItem(id:action:),
    environment: { environment in
      PeripheralEnvironment(
        bluetoothManager: environment.bluetoothManager
      )
    }
  ),
  peripheralReducer.forEach(
    state: \.connectedPeripherals,
    action: /AppAction.connectedPeripheralListItem(id:action:),
    environment: { environment in
      PeripheralEnvironment(
        bluetoothManager: environment.bluetoothManager
      )
    }
  ),
  Reducer { state, action, environment in
    switch action {
      case .onAppear:
        return environment.bluetoothManager
          .delegate()
          .map(AppAction.bluetoothManager)

      case .startBluetoothScan:
        switch environment.bluetoothManager.state() {
          case .unsupported:
            assertionFailure("Bluetooth is not supported on this device.")
            return .none
          case .unauthorized:
            assertionFailure("Please enable Bluetooth for this app in the iOS settings.")
            return .none
          case .poweredOn:
            return scanForPeripheralsEffect(environment.bluetoothManager)
          default:
            state.shouldStartBluetoothScanningWhenPoweredOn = true
            return .none
        }

      case .stopBluetoothScan:
        return .merge(
          environment.bluetoothManager
            .stopScan()
            .fireAndForget(),
          .init(value: .removeAllDiscoveredPeripherals)
        )

      case let .removeDiscoveredPeripheral(peripheralStateIdentifier):
        var effects: [Effect<AppAction, Never>] = []

        if let cancellableID = state.discoveredPeripherals[id: peripheralStateIdentifier]?.cancellableID {
          effects.append(.cancel(id: cancellableID))
        }

        effects.append(.init(value: ._removeDiscoveredPeripheral(peripheralStateIdentifier)))

        return .merge(effects)

      case let ._removeDiscoveredPeripheral(peripheralStateIdentifier):
        state.discoveredPeripherals.remove(id: peripheralStateIdentifier)
        return .none

      case .removeAllDiscoveredPeripherals:
        let cancellableIDs = state.discoveredPeripherals.compactMap({ state in
          state.cancellableID
        })

        return .merge(
          .cancel(ids: cancellableIDs),
          .init(value: ._removeAllDiscoveredPeripherals)
        )

      case ._removeAllDiscoveredPeripherals:
        state.discoveredPeripherals.removeAll()
        return .none

      case let .removeConnectedPeripheral(peripheralStateIdentifier):
        var effects: [Effect<AppAction, Never>] = []

        if let cancellableID = state.connectedPeripherals[id: peripheralStateIdentifier]?.cancellableID {
          effects.append(.cancel(id: cancellableID))
        }

        effects.append(.init(value: ._removeConnectedPeripheral(peripheralStateIdentifier)))

        return .merge(effects)

      case let ._removeConnectedPeripheral(peripheralStateIdentifier):
        state.connectedPeripherals.remove(id: peripheralStateIdentifier)
        return .none

      case .bluetoothManager(.didUpdateState):
        let bluetoothState = environment.bluetoothManager.state()
        switch bluetoothState {
          case .poweredOn:
            if state.shouldStartBluetoothScanningWhenPoweredOn {
              return scanForPeripheralsEffect(environment.bluetoothManager)
            }
            else {
              return .none
            }
          default:
            return .none
        }

      case let .bluetoothManager(.didUpdateScanningState(scanningState)):
        state.isBluetoothScanning = scanningState
        return .none

      case let .bluetoothManager(.didDiscover(peripheral, advertismentData, rssi)):
        let peripheralStateIdentifier = peripheral.identifier

        guard state.connectedPeripherals[id: peripheralStateIdentifier] == nil
        else { return .none }

        let cancellableID = state.discoveredPeripherals[id: peripheralStateIdentifier]?.cancellableID
        ?? AnyHashable(UUID())

        state.discoveredPeripherals.updateOrAppend(
          PeripheralState(
            id: peripheralStateIdentifier,
            peripheral: peripheral,
            advertismentData: advertismentData,
            rssi: rssi,
            cancellableID: cancellableID
          )
        )

        var effect: Effect<AppAction, Never> = .none

        if Config.Bluetooth.allowDuplicatesAndUndiscover {
          effect = Effect
            .init(value: .removeDiscoveredPeripheral(peripheral.identifier))
            .debounce(
              id: peripheral.identifier,
              for: .seconds(Config.Bluetooth.undiscoverAfterSeconds),
              scheduler: environment.mainQueue
            )
        }

        return effect

      case let .bluetoothManager(.didConnect(peripheral)):
        if Config.Bluetooth.splitDiscoveredAndConnectedPeripherals {
          let peripheralStateIdentifier = peripheral.identifier
          let connectedPeripheral = state.discoveredPeripherals[id: peripheralStateIdentifier] ??
          PeripheralState(
            id: peripheralStateIdentifier,
            peripheral: peripheral,
            cancellableID: UUID()
          )

          state.connectedPeripherals.append(connectedPeripheral)

          return .init(value: .removeDiscoveredPeripheral(peripheralStateIdentifier))
        }
        else {
          return .none
        }

      case let .bluetoothManager(.didDisconnectPeripheral(peripheral, error)):
        let peripheralStateIdentifier = peripheral.identifier
        return .init(value: .removeConnectedPeripheral(peripheralStateIdentifier))

      case .bluetoothManager,
          .discoveredPeripheralListItem,
          .connectedPeripheralListItem:
        return .none
    }
  }
)
