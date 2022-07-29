import ComposableArchitecture
import ComposableCoreBluetooth
import SwiftUI

struct BluetoothPeripheralListView: View {
  let store: Store<AppState, AppAction>

  init(store: Store<AppState, AppAction>) {
    self.store = store
  }

  // TODO: Add auto-connect
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationView {
        List {
          if Config.Bluetooth.splitDiscoveredAndConnectedPeripherals {
            Section(content: {
              ForEachStore(
                store.scope(
                  state: \.connectedPeripherals,
                  action: AppAction.connectedPeripheralListItem(id:action:)
                )
              ) { peripheralStore in
                NavigationLink(destination: DetailView(store: peripheralStore)) {
                  ListItemView(store: peripheralStore)
                }
              }
            }, header: {
              Text("Connected peripherals")
            })
          }

          Section(content: {
            ForEachStore(
              store.scope(
                state: \.discoveredPeripherals,
                action: AppAction.discoveredPeripheralListItem(id:action:)
              )
            ) { peripheralStore in
              ListItemView(store: peripheralStore)
            }
          }, header: {
            if Config.Bluetooth.splitDiscoveredAndConnectedPeripherals {
              Text("Discovered peripherals")
            }
          })
        }
        .animation(.default, value: viewStore.discoveredPeripherals.map(\.id))
        .navigationBarTitle("Bluetooth")
        .navigationBarItems(trailing: HStack {
          let buttonTitle = viewStore.isBluetoothScanning ? "Stop Bluetooth Scan" : "Start Bluetooth Scan"
          Button(buttonTitle) {
            viewStore.send(viewStore.isBluetoothScanning ? .stopBluetoothScan : .startBluetoothScan)
          }
          .disabled(!viewStore.isBluetoothPoweredOn)
        })
      }
      .navigationViewStyle(.stack)
      .onAppear {
        viewStore.send(.onAppear)
      }
    }
  }
}

struct BluetoothPeripheralListView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      let bluetoothManager = CentralManager.mock(delegate: { .none })

      BluetoothPeripheralListView(
        store: Store(
          initialState: AppState(
            isBluetoothPoweredOn: bluetoothManager.state() == .poweredOn,
            isBluetoothScanning: bluetoothManager.isScanning()
          ),
          reducer: appReducer,
          environment: AppEnvironment(
            bluetoothManager: bluetoothManager,
            mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
            userDefaults: UserDefaults.standard
          )
        )
      )

      BluetoothPeripheralListView(
        store: Store(
          initialState: AppState(
            isBluetoothPoweredOn: bluetoothManager.state() == .poweredOn,
            isBluetoothScanning: bluetoothManager.isScanning(),
            discoveredPeripherals: IdentifiedArrayOf(uniqueElements: [
              PeripheralState(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                peripheral: Peripheral.mock(
                  identifier: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                  name: { nil },
                  delegate: { .none },
                  services: { nil },
                  state: { .disconnected },
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
              )
            ]),
            connectedPeripherals: IdentifiedArrayOf(uniqueElements: [
              PeripheralState(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                peripheral: Peripheral.mock(
                  identifier: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                  name: { nil },
                  delegate: { .none },
                  services: { nil },
                  state: { .connected },
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
              )
            ])
          ),
          reducer: appReducer,
          environment: AppEnvironment(
            bluetoothManager: bluetoothManager,
            mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
            userDefaults: UserDefaults.standard
          )
        )
      )
    }
  }
}

