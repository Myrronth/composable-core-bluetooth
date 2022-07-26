import ComposableArchitecture
import ComposableCoreBluetooth
import SwiftUI
import CoreBluetooth

let appView: () -> BluetoothPeripheralListView = {
  let bluetoothManager = CentralManager.live()
  let reducer = BluetoothPeripheralListReducer

  return BluetoothPeripheralListView(
    store: Store(
      initialState: BluetoothPeripheralListState(
        shouldStartBluetoothScanningWhenPoweredOn: true,
        isBluetoothScanning: false
      ),
      reducer: reducer,
      environment: BluetoothPeripheralListEnvironment(
        bluetoothManager: bluetoothManager,
        mainQueue: DispatchQueue.main.eraseToAnyScheduler()
      )
    )
  )
}

@main
struct WeatherProAppWrapper {
  static func main() {
    if #available(iOS 14.0, *) {
      BluetoothManagerApp.main()
    }
    else {
      UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(SceneDelegate.self))
    }
  }
}

@available(iOS 14.0, *)
struct BluetoothManagerApp: App {
  var body: some Scene {
    WindowGroup {
      appView()
    }
  }
}
