import XCTestDynamicOverlay

public func _fail(_ failingFuncName: String) {
  XCTFail("\(failingFuncName) - A failing environment function is invoked.")
}

public func _unimplemented(_ function: StaticString, file: StaticString = #file, line: UInt = #line) -> Never {
  fatalError(
    """
    `\(function)` was called but is not implemented. \
    Be sure to provide an implementation for this endpoint when creating the mock.
    """,
    file: file,
    line: line
  )
}

func couldNotFindRawPeripheralValue() {
  assertionFailure(
        """
        The supplied peripheral did not have a raw value. This is considered a programmer error. \
        You should use the .live static function to initialize a peripheral.
        """
  )
}
