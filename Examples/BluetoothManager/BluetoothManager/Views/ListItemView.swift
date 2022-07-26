import ComposableArchitecture
import ComposableCoreBluetooth
import CoreBluetooth
import SwiftUI

struct ListItemView: View {
  let store: Store<PeripheralState, PeripheralAction>

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

struct ListItemView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      List {
        ForEach([
          CBPeripheralState.disconnected,
          CBPeripheralState.connecting,
          CBPeripheralState.connected,
          CBPeripheralState.disconnecting
        ], id: \.rawValue) { state in
          ListItemView(
            store: Store(
              initialState: PeripheralState(
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
              reducer: peripheralReducer,
              environment: PeripheralEnvironment(
                bluetoothManager: CentralManager.mock(delegate: { .none })
              )
            )
          )
        }
      }
    }
  }
}
