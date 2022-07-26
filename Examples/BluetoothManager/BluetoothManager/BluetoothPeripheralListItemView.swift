import ComposableArchitecture
import ComposableCoreBluetooth
import CoreBluetooth
import SwiftUI

struct BluetoothPeripheralListItemState: Equatable, Identifiable {
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

enum BluetoothPeripheralListItemAction: Equatable {
  // TODO: Whats the best way to make certain actions "private"?
  case onAppear
  case onDisappear

  case connect
  case disconnect
  case bluetoothManager(CentralManager.Action)
//  case peripheral(Peripheral.Action)
}

struct BluetoothPeripheralListItemEnvironment {
  let bluetoothManager: CentralManager
}

private func connectedEffect(_ peripheral: Peripheral) -> Effect<BluetoothPeripheralListItemAction, Never> {
  return peripheral
    .readRSSI()
    .fireAndForget()
}


let bluetoothPeripheralListItemReducer =
Reducer<BluetoothPeripheralListItemState, BluetoothPeripheralListItemAction, BluetoothPeripheralListItemEnvironment> {
  state, action, environment in

  switch action {
    case .onAppear:
      let peripheral = state.peripheral

      var effects: Effect<BluetoothPeripheralListItemAction, Never> = .merge(
        environment.bluetoothManager
          .delegate()
          .map(BluetoothPeripheralListItemAction.bluetoothManager),
        state.peripheral
          .delegate()
          .map(BluetoothPeripheralListItemAction.bluetoothManager)
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

struct BluetoothPeripheralListItemView: View {
  let store: Store<BluetoothPeripheralListItemState, BluetoothPeripheralListItemAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      let localName = viewStore.advertismentData?.localName

      HStack {
        VStack(alignment: .leading) {
          Text(localName ?? "Unnamed")
            .foregroundColor(localName == nil ? Color.gray : nil)

          if let rssi = viewStore.rssi {
            Text("RSSI: \(rssi)")
              .font(.footnote)
              .foregroundColor(Color.gray)
          }
        }

        Spacer()

        switch viewStore.peripheralState {
          case .connecting:
            Text("Connecting…")
              .foregroundColor(Color.gray)
          case .connected:
            Button("Disconnect") { viewStore.send(.disconnect) }
              .buttonStyle(.borderless)
          case .disconnecting:
            Text("Disconnecting…")
              .foregroundColor(Color.gray)
          case .disconnected:
            Button("Connect") { viewStore.send(.connect) }
              .buttonStyle(.borderless)
          @unknown default:
            EmptyView()
        }
      }
      .onAppear {
        viewStore.send(.onAppear)
      }
      .onDisappear {
        // TODO: Wait for https://github.com/pointfreeco/swift-composable-architecture/pull/1189
//        viewStore.send(.onDisappear)
      }
    }
  }
}

struct BluetoothPeripheralListItemView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      List {
        ForEach([
          CBPeripheralState.disconnected,
          CBPeripheralState.connecting,
          CBPeripheralState.connected,
          CBPeripheralState.disconnecting
        ], id: \.rawValue) { state in
          BluetoothPeripheralListItemView(
            store: Store(
              initialState: BluetoothPeripheralListItemState(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                peripheral: Peripheral.mock(
                  identifier: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                  name: { nil },
                  delegate: { .none },
                  services: { nil },
                  state: { state },
                  canSendWriteWithoutResponse: { false },
                  readRSSI: { .none },
                  ancsAuthorized: { false }
                ),
                advertismentData: .init(
                  localName: "MEATER+E",
                  manufacturerData: nil,
                  serviceData: nil,
                  serviceUUIDs: nil,
                  overflowServiceUUIDs: nil,
                  solicitedServiceUUIDs: nil,
                  txPowerLevel: nil,
                  isConnectable: true
                ),
                rssi: -51,
                cancellableID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
              ),
              reducer: bluetoothPeripheralListItemReducer,
              environment: BluetoothPeripheralListItemEnvironment(
                bluetoothManager: CentralManager.mock(delegate: { .none })
              )
            )
          )
        }
      }
    }
  }
}
