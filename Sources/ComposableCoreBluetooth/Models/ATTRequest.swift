import CoreBluetooth

public struct ATTRequest: Equatable {
  let rawValue: CBATTRequest?

  public let central: Central
  public let characteristic: Characteristic
  public let value: Data?
  public let offset: Int

  init(from request: CBATTRequest) {
    rawValue = request
    central = Central(from: request.central)
    characteristic = Characteristic(from: request.characteristic)
    value = request.value
    offset = request.offset
  }

  init(
    central: Central,
    characteristic: Characteristic,
    value: Data?,
    offset: Int
  ) {
    rawValue = nil
    self.central = central
    self.characteristic = characteristic
    self.value = value
    self.offset = offset
  }
}

extension ATTRequest {

  public static func mock(
    central: Central,
    characteristic: Characteristic,
    value: Data?,
    offset: Int
  ) -> Self {
    return Self(
      central: central,
      characteristic: characteristic,
      value: value,
      offset: offset
    )
  }
}
