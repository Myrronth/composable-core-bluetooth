import ComposableArchitecture
import ComposableCoreBluetooth
import CoreBluetooth

enum Config {
  enum Bluetooth {
    static let allowDuplicatesAndUndiscover = false
    static let undiscoverAfterSeconds = 5
    static let splitDiscoveredAndConnectedPeripherals = true
    static let automaticallyConnectToPreviouslyConnectedPeripherals = true
    static let mandatoryServices = [
      CBUUID(string: "89145240-0C04-4713-96A4-0C88F15D6120")
    ]
  }

  enum UserDefaults {
    static let previouslyConnectedPeripheralUUIDs = "previouslyConnectedPeripheralUUIDs"
  }
}

struct AppState: Equatable {
  var shouldStartBluetoothScanningWhenPoweredOn = false
  var isBluetoothPoweredOn: Bool
  var isBluetoothScanning: Bool

  var discoveredPeripherals: IdentifiedArrayOf<PeripheralState> = []
  var connectedPeripherals: IdentifiedArrayOf<PeripheralState> = []
}

enum AppAction: Equatable {
  case onAppear
  case startBluetoothScan
  case stopBluetoothScan
  case _discoverPeripherals

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
  let userDefaults: UserDefaults
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
            return .init(value: ._discoverPeripherals)
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

      case ._discoverPeripherals:
        var retrievedPeripherals: [Peripheral] = []

        // Retrieve already connected peripherals by persisted peripherals UUIDs
        if
          let peripheralIdentifiers = environment.userDefaults
            .stringArray(forKey: Config.UserDefaults.previouslyConnectedPeripheralUUIDs)?
            .compactMap(UUID.init(uuidString:))
        {
          retrievedPeripherals.append(
            contentsOf: environment.bluetoothManager.retrievePeripheralsWithIdentifiers(peripheralIdentifiers)
          )
        }

        // Retrieve already connected peripherals by mandatory services
        retrievedPeripherals.append(
          contentsOf: environment.bluetoothManager
            .retrieveConnectedPeripheralsWithServices(Config.Bluetooth.mandatoryServices)
        )

        // Append retrieved peripherals to state
        retrievedPeripherals.forEach { peripheral in
          let peripheralStateIdentifier = peripheral.identifier

          if peripheral.state() == .connected {
            let cancellableID = state.connectedPeripherals[id: peripheralStateIdentifier]?.cancellableID
            ?? AnyHashable(UUID())

            state.connectedPeripherals.updateOrAppend(
              PeripheralState(
                id: peripheralStateIdentifier,
                peripheral: peripheral,
                cancellableID: cancellableID
              )
            )
          }
          else {
            let cancellableID = state.discoveredPeripherals[id: peripheralStateIdentifier]?.cancellableID
            ?? AnyHashable(UUID())

            state.discoveredPeripherals.updateOrAppend(
              PeripheralState(
                id: peripheralStateIdentifier,
                peripheral: peripheral,
                cancellableID: cancellableID
              )
            )
          }
        }

        // Discover new peripherals based on service UUIDs
        return environment.bluetoothManager
          .scanForPeripheralsWithServices(
            Config.Bluetooth.mandatoryServices,
            .init(
              allowDuplicates: Config.Bluetooth.allowDuplicatesAndUndiscover
            ))
          .fireAndForget()

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
            state.isBluetoothPoweredOn = true
            if state.shouldStartBluetoothScanningWhenPoweredOn {
              return .init(value: ._discoverPeripherals)
            }
            else {
              return .none
            }
          default:
            state.isBluetoothPoweredOn = false
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

        var effects: [Effect<AppAction, Never>] = []

        if Config.Bluetooth.allowDuplicatesAndUndiscover {
          effects.append(
            .init(value: .removeDiscoveredPeripheral(peripheral.identifier))
            .debounce(
              id: peripheral.identifier,
              for: .seconds(Config.Bluetooth.undiscoverAfterSeconds),
              scheduler: environment.mainQueue
            )
          )
        }

        if
          Config.Bluetooth.automaticallyConnectToPreviouslyConnectedPeripherals,
          let peripheralIdentifiers = environment.userDefaults
            .stringArray(forKey: Config.UserDefaults.previouslyConnectedPeripheralUUIDs)?
            .compactMap(UUID.init(uuidString:)),
          peripheralIdentifiers.contains(peripheral.identifier)
        {
          effects.append(
            environment.bluetoothManager
              .connect(peripheral)
              .fireAndForget()
          )
        }

        return .merge(effects)

      case let .bluetoothManager(.didConnect(peripheral)):
        // Persist peripheral UUID
        let key = Config.UserDefaults.previouslyConnectedPeripheralUUIDs
        let identifier = peripheral.identifier.uuidString
        var peripherals = environment.userDefaults.stringArray(forKey: key) ?? []
        if peripherals.firstIndex(of: identifier) == nil {
          peripherals.append(identifier)
          environment.userDefaults.set(peripherals, forKey: key)
        }

        // Add peripheral to state
        if Config.Bluetooth.splitDiscoveredAndConnectedPeripherals {
          let peripheralStateIdentifier = peripheral.identifier

          let connectedPeripheral = state.discoveredPeripherals[id: peripheralStateIdentifier] ?? {
            let cancellableID = state.connectedPeripherals[id: peripheralStateIdentifier]?.cancellableID
            ?? AnyHashable(UUID())

            return PeripheralState(
              id: peripheralStateIdentifier,
              peripheral: peripheral,
              cancellableID: cancellableID
            )
          }()

          state.connectedPeripherals.updateOrAppend(connectedPeripheral)

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
