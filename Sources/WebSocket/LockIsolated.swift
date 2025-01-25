import Foundation

/// A thread-safe wrapper around a value using a recursive lock for synchronization.
///
/// `LockIsolated` ensures that access to the wrapped value is thread-safe by using
/// an `NSRecursiveLock`. This allows for safe concurrent reads and writes to the value.
///
/// - Note: This class is marked as `@unchecked Sendable` because the compiler cannot
///   guarantee thread safety. The thread safety is ensured by the use of the lock.
///
/// - Parameters:
///   - Value: The type of the value to be wrapped.
///
/// - Example:
/// ```swift
/// let lockIsolated = LockIsolated(0)
/// lockIsolated.withValue { $0 += 1 }
/// print(lockIsolated.value) // 1
/// ```
package final class LockIsolated<Value: Sendable>: @unchecked Sendable {
  private let lock = NSRecursiveLock()
  private var _value: Value

  /// The current value, accessed in a thread-safe manner.
  ///
  /// Accessing this property will acquire the lock to ensure thread safety.
  package var value: Value {
    lock.withLock { _value }
  }

  /// Initializes a new instance of `LockIsolated` with the given value.
  ///
  /// - Parameter value: The initial value to be wrapped.
  package init(_ value: Value) {
    self._value = value
  }

  /// Executes a closure with a mutable reference to the wrapped value in a thread-safe manner.
  ///
  /// This method acquires the lock, passes a mutable reference to the wrapped value to the closure,
  /// and then releases the lock. The value is updated with any changes made within the closure.
  ///
  /// - Parameter body: A closure that takes an `inout` reference to the value and returns a result.
  /// - Returns: The result of the closure.
  /// - Throws: Any error thrown by the closure.
  package func withValue<R>(_ body: (inout Value) throws -> R) rethrows -> R {
    var copy = self._value
    defer { self._value = copy }
    return try lock.withLock { try body(&copy) }
  }
}
