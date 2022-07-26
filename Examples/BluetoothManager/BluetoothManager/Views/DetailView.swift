import ComposableArchitecture
import ComposableCoreBluetooth
import SwiftUI

struct DetailView: View {
  var store: Store<PeripheralState, PeripheralAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      let name = viewStore.peripheral.name() ?? viewStore.advertismentData?.localName

      List {
        Text("test")
      }
      .navigationBarTitle(name ?? "Unnamed")
    }
  }
}

struct DetailView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      DetailView(
        store: Store(
          initialState: PeripheralState(
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
