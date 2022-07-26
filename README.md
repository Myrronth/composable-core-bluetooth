# Composable Core Bluetooth

Composable Core Bluetooth is library that bridges [the Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) and [Core Bluetooth](https://developer.apple.com/documentation/corebluetooth).

* [Example](#example)
* [Basic usage](#basic-usage)
* [Installation](#installation)
* [Documentation](#documentation)
* [Help](#help)

## Example

Check out the [BluetoothManager](./Examples/BluetoothManager) demo to see ComposableCoreBluetooth in practice.

## Basic Usage

To use ComposableCoreBluetooth in your application, you can add an action to your domain that represents all of the actions the central manager and peripherals can emit via the `CBCentralManagerDelegate` and `CBPeripheralDelegate` methods:

```swift
import ComposableCoreBluetooth

enum AppAction {
  case bluetoothManager(CentralManager.Action)

  // Your domain's other actions:
  ...
}
```

**WIP**

## Installation

You can add ComposableCoreBluetooth to an Xcode project by adding it as a package dependency.

  1. From the **File** menu, select **Swift Packages › Add Package Dependency…**
  2. Enter "https://github.com/myrronth/composable-core-bluetooth" into the package repository URL text field

## Documentation

**WIP**

## Help

**WIP**

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
