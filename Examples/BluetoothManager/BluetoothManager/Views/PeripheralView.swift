import ComposableArchitecture
import ComposableCoreBluetooth
import SwiftUI

struct DetailView: View {
  var store: Store<PeripheralState, PeripheralAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      let name = viewStore.peripheral.name() ?? viewStore.advertismentData?.localName
      let services = viewStore.services

      List {
        Section(content: {
          if let services = services {
            ForEach(services, id: \.uuid) { service in
              VStack(alignment: .leading) {
                Text(service.uuid.uuidString)

                Toggle("Is Primary?", isOn: .constant(service.isPrimary))
                  .disabled(true)

                if let includedServices = service.includedServices {
                  ForEach(Array(zip(includedServices.indices, includedServices)), id: \.1.uuid) { index, service in
                    VStack(alignment: .leading) {
                      Text("Included Service \(index)")
                    }
                  }
                  .font(.footnote)
                  .foregroundColor(Color.gray)
                }
                else {
                  Button("Discover Included Services") { viewStore.send(.discoverIncludedServices(nil, service)) }
                    .buttonStyle(.borderless)
                    .font(.footnote)
                }

                if let characteristics = service.characteristics() {
                  ForEach(characteristics, id: \.uuid) { characteristic in
                    VStack(alignment: .leading) {
                      Text("Characteristic \(characteristic.uuid)")

                      if let descriptors = characteristic.descriptors() {
                        ForEach(descriptors, id: \.uuid) { descriptors in
                          VStack(alignment: .leading) {
                            Text("Descriptors \(descriptors.uuid):")

                            switch descriptors.value {
                              case let .characteristicExtendedProperties(number),
                                let .clientCharacteristicConfiguration(number),
                                let .serverCharacteristicConfiguration(number):

                                if let number = number {
                                  Text("\t\(number)")
                                }

                              case let .characteristicUserDescription(string):
                                if let string = string {
                                  Text("\t\(string)")
                                }

                              default: EmptyView()
                            }
                          }
                        }
                        .font(.caption)
                        .foregroundColor(Color.gray)
                      }
                    }
                    .padding(.top, 4)
                  }
                  .font(.footnote)
                  .foregroundColor(Color.orange)
                }
                else {
                  Button("Discover Characteristics and Descriptors") {
                    viewStore.send(.discoverCharacteristicsAndDescriptors(nil, service))
                  }
                    .buttonStyle(.borderless)
                    .font(.footnote)
                }
              }
            }
          }
          else {
            Button("Discover Services") { viewStore.send(.discoverServices(nil)) }
          }
        }, header: {
          Text("Services")
        })
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
