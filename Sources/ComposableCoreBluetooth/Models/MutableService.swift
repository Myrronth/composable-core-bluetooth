import CoreBluetooth

public struct MutableService {
  public let uuid: CBUUID
  public let isPrimary: Bool
  public var characteristics: [Characteristic]?
  public var includedServices: [Service]?

  public var rawValue: CBMutableService {
    let mutableService = CBMutableService(type: uuid, primary: isPrimary)
    mutableService.characteristics = characteristics?.compactMap(\.rawValue)
    mutableService.includedServices = includedServices?.compactMap(\.rawValue)
    return mutableService
  }

  init(type: CBUUID, primary: Bool) {
    self.uuid = type
    isPrimary = primary
  }
}
