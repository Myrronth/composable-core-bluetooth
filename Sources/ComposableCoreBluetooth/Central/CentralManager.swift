import ComposableArchitecture
import CoreBluetooth

public struct CentralManager {
  /// Actions that correspond to `CBCentralManagerDelegate` methods.
  ///
  /// See `CBCentralManagerDelegate` for more information.
  public enum Action: Equatable {
    // Monitoring Connections with Peripherals
    case didConnect(Peripheral)
    case didDisconnectPeripheral(Peripheral, error: Error?)
    case didFailToConnect(Peripheral, error: Error?)
    case connectionEventDidOccur(CBConnectionEvent, peripheral: Peripheral)

    // Discovering and Retrieving Peripherals
    case didDiscover(Peripheral, advertismentData: AdvertismentData, rssi: NSNumber)

    // Monitoring the Central Manager’s States
    case didUpdateState(CBManagerState)
    case willRestoreState(RestorationOptions)
    case didUpdateScanningState(Bool)

    // Monitoring the Central Manager’s Authorization
    case didUpdateANCSAuthorizationFor(Peripheral)

    case peripheral(UUID, Peripheral.Action)
  }

  // Monitoring Properties
  public var delegate: () -> Effect<Action, Never>

  // Accessing the Manager’s Properties
  public var state: () -> CBManagerState

  // Determining Authorization State
  public var authorization: () -> CBManagerAuthorization

  // Establishing or Canceling Connections with Peripherals
  public var connect: (Peripheral, ConnectionOptions?) -> Effect<Never, Never>
  public var cancelPeripheralConnection: (Peripheral) -> Effect<Never, Never>

  // Retrieving Lists of Peripherals
  public var retrieveConnectedPeripheralsWithServices: ([CBUUID]) -> [Peripheral]
  public var retrievePeripheralsWithIdentifiers: ([UUID]) -> [Peripheral]

  // Scanning or Stopping Scans of Peripherals
  public var scanForPeripheralsWithServices: ([CBUUID]?, ScanOptions?) -> Effect<Never, Never>
  public var stopScan: () -> Effect<Never, Never>
  public var isScanning: () -> Bool

  // Inspecting Feature Support
  public var supports: (CBCentralManager.Feature) -> Bool

  // Receiving Connection Events
  public var registerForConnectionEvents: (ConnectionEventOptions?) -> Effect<Never, Never>
}

extension CentralManager {
  public func connect(_ peripheral: Peripheral, options: ConnectionOptions? = nil) -> Effect<Never, Never> {
    connect(peripheral, options)
  }

  public func scanForPeripheralsWithServices(
    _ services: [CBUUID]? = nil,
    options: ScanOptions? = nil
  ) -> Effect<Never, Never> {
    scanForPeripheralsWithServices(services, options)
  }

  public func registerForConnectionEvents(
    _ options: ConnectionEventOptions? = nil
  ) -> Effect<Never, Never> {
    registerForConnectionEvents(options)
  }
}

extension CentralManager {
  public struct InitializationOptions: Equatable {

    public let showPowerAlert: Bool?
    public let restoreIdentifier: String?

    public init(showPowerAlert: Bool? = nil, restoreIdentifier: String? = nil) {
      self.showPowerAlert = showPowerAlert
      self.restoreIdentifier = restoreIdentifier
    }

    public init(from dictionary: [String: Any]) {
      showPowerAlert = dictionary[CBCentralManagerOptionShowPowerAlertKey] as? Bool
      restoreIdentifier = dictionary[CBCentralManagerOptionRestoreIdentifierKey] as? String
    }

    func toDictionary() -> [String: Any] {
      var dictionary: [String: Any] = [:]

      if let showPowerAlert = showPowerAlert {
        dictionary[CBCentralManagerOptionShowPowerAlertKey] = showPowerAlert
      }

      if let restoreIdentifier = restoreIdentifier {
        dictionary[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
      }

      return dictionary
    }
  }
}

extension CentralManager {
  public struct ConnectionOptions: Equatable {

    public let notifyOnConnection: Bool?
    public let notifyOnDisconnection: Bool?
    public let notifyOnNotification: Bool?
    public let enableTransportBridging: Bool?
    public let requiredANCS: Bool?
    public let startDelay: NSNumber?

    public init(
      notifyOnConnection: Bool? = nil,
      notifyOnDisconnection: Bool? = nil,
      notifyOnNotification: Bool? = nil,
      enableTransportBridging: Bool? = nil,
      requiredANCS: Bool? = nil,
      startDelay: NSNumber? = nil
    ) {
      self.notifyOnConnection = notifyOnConnection
      self.notifyOnDisconnection = notifyOnDisconnection
      self.notifyOnNotification = notifyOnNotification
      self.enableTransportBridging = enableTransportBridging
      self.requiredANCS = requiredANCS
      self.startDelay = startDelay
    }

    public init(from dictionary: [String: Any]) {
      notifyOnConnection = dictionary[CBConnectPeripheralOptionNotifyOnConnectionKey] as? Bool
      notifyOnDisconnection = dictionary[CBConnectPeripheralOptionNotifyOnDisconnectionKey] as? Bool
      notifyOnNotification = dictionary[CBConnectPeripheralOptionNotifyOnNotificationKey] as? Bool
      enableTransportBridging = dictionary[CBConnectPeripheralOptionEnableTransportBridgingKey] as? Bool
      requiredANCS = dictionary[CBConnectPeripheralOptionRequiresANCS] as? Bool
      startDelay = dictionary[CBConnectPeripheralOptionStartDelayKey] as? NSNumber
    }

    func toDictionary() -> [String: Any] {
      var dictionary: [String: Any] = [:]

      if let notifyOnConnection = notifyOnConnection {
        dictionary[CBConnectPeripheralOptionNotifyOnConnectionKey] = notifyOnConnection
      }

      if let notifyOnDisconnection = notifyOnDisconnection {
        dictionary[CBConnectPeripheralOptionNotifyOnDisconnectionKey] = notifyOnDisconnection
      }

      if let notifyOnNotification = notifyOnNotification {
        dictionary[CBConnectPeripheralOptionNotifyOnNotificationKey] = notifyOnNotification
      }

      if let enableTransportBridging = enableTransportBridging {
        dictionary[CBConnectPeripheralOptionEnableTransportBridgingKey] = enableTransportBridging
      }

      if let requiredANCS = requiredANCS {
        dictionary[CBConnectPeripheralOptionRequiresANCS] = requiredANCS
      }

      if let startDelay = startDelay {
        dictionary[CBConnectPeripheralOptionStartDelayKey] = startDelay
      }

      return dictionary
    }
  }
}

extension CentralManager {
  public struct ConnectionEventOptions: Equatable {

    let peripheralUUIDs: [UUID]?
    let serviceUUIDs: [CBUUID]?

    public init(peripheralUUIDs: [UUID]? = nil, serviceUUIDs: [CBUUID]? = nil) {
      self.peripheralUUIDs = peripheralUUIDs
      self.serviceUUIDs = serviceUUIDs
    }

    public init(from dictionary: [CBConnectionEventMatchingOption: Any]) {
      peripheralUUIDs = dictionary[.peripheralUUIDs] as? [UUID]
      serviceUUIDs = dictionary[.serviceUUIDs] as? [CBUUID]
    }

    func toDictionary() -> [CBConnectionEventMatchingOption: Any] {
      var dictionary: [CBConnectionEventMatchingOption: Any] = [:]

      if let peripheralUUIDs = peripheralUUIDs {
        dictionary[.peripheralUUIDs] = peripheralUUIDs
      }

      if let serviceUUIDs = serviceUUIDs {
        dictionary[.serviceUUIDs] = serviceUUIDs
      }

      return dictionary
    }
  }
}

extension CentralManager {
  public struct RestorationOptions: Equatable {

    public let peripherals: [CBPeripheral]?
    public let scannedServices: [CBUUID]?
    public let scanOptions: ScanOptions

    public init(
      peripherals: [CBPeripheral]? = nil,
      scannedServices: [CBUUID]? = nil,
      scanOptions: ScanOptions = ScanOptions(from: [:])
    ) {
      self.peripherals = peripherals
      self.scannedServices = scannedServices
      self.scanOptions = scanOptions
    }

    public init(from dictionary: [String: Any]) {
      peripherals = dictionary[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral]
      scannedServices = dictionary[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID]
      scanOptions = ScanOptions(from: dictionary[CBCentralManagerRestoredStateScanOptionsKey] as? [String: Any])
    }
  }
}

extension CentralManager {
  public struct ScanOptions: Equatable {

    public let allowDuplicates: Bool?
    public let solicitedServiceUUIDs: [CBUUID]?

    public init(allowDuplicates: Bool? = nil, solicitedServiceUUIDs: [CBUUID]? = nil) {
      self.allowDuplicates = allowDuplicates
      self.solicitedServiceUUIDs = solicitedServiceUUIDs
    }

    public init(from dictionary: [String: Any]?) {
      allowDuplicates = (dictionary?[CBCentralManagerScanOptionAllowDuplicatesKey] as? NSNumber)?.boolValue
      solicitedServiceUUIDs = dictionary?[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] as? [CBUUID]
    }

    func toDictionary() -> [String: Any] {
      var dictionary = [String: Any]()

      if let allowDuplicates = allowDuplicates {
        dictionary[CBCentralManagerScanOptionAllowDuplicatesKey] = NSNumber(booleanLiteral: allowDuplicates)
      }

      if let solicitedServiceUUIDs = solicitedServiceUUIDs {
        dictionary[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = solicitedServiceUUIDs as NSArray
      }

      return dictionary
    }
  }
}

extension CentralManager {
  public struct AdvertismentData: Equatable {

    public let localName: String?
    public let manufacturerData: Data?
    public let serviceData: [CBUUID: Data]?
    public let serviceUUIDs: [CBUUID]?
    public let overflowServiceUUIDs: [CBUUID]?
    public let solicitedServiceUUIDs: [CBUUID]?
    public let txPowerLevel: NSNumber?
    public let isConnectable: Bool?

    public init(
      localName: String? = nil,
      manufacturerData: Data? = nil,
      serviceData: [CBUUID: Data]? = nil,
      serviceUUIDs: [CBUUID]? = nil,
      overflowServiceUUIDs: [CBUUID]? = nil,
      solicitedServiceUUIDs: [CBUUID]? = nil,
      txPowerLevel: NSNumber? = nil,
      isConnectable: Bool? = nil
    ) {
      self.localName = localName
      self.manufacturerData = manufacturerData
      self.serviceData = serviceData
      self.serviceUUIDs = serviceUUIDs
      self.overflowServiceUUIDs = overflowServiceUUIDs
      self.solicitedServiceUUIDs = solicitedServiceUUIDs
      self.txPowerLevel = txPowerLevel
      self.isConnectable = isConnectable
    }

    init(from dictionary: [String: Any]) {
      localName = dictionary[CBAdvertisementDataLocalNameKey] as? String
      manufacturerData = dictionary[CBAdvertisementDataManufacturerDataKey] as? Data
      txPowerLevel = dictionary[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
      isConnectable = (dictionary[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue
      serviceData = dictionary[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
      serviceUUIDs = dictionary[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
      overflowServiceUUIDs = dictionary[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
      solicitedServiceUUIDs = dictionary[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
  }
}
