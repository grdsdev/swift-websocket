import Foundation

package final class LockIsolated<Value>: @unchecked Sendable {
  private let lock = NSRecursiveLock()
  private var _value: Value

  package var value: Value {
    lock.withLock { _value }
  }

  package init(_ value: Value) {
    self._value = value
  }

  package func withValue<R>(_ body: (inout Value) throws -> R) rethrows -> R {
    var copy = self._value
    defer { self._value = copy }
    return try lock.withLock { try body(&copy) }
  }
}
