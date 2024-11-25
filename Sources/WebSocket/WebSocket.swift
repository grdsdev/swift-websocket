import Foundation

public enum WebSocketEvent: Sendable {
  case text(String)
  case binary(Data)
  case close(code: Int?, reason: String)
}

public enum WebSocketError: Error, LocalizedError {
  /// An error occurred while connecting to the peer.
  case connection(message: String, error: any Error)

  public var errorDescription: String? {
    switch self {
    case .connection(let message, let error): "\(message) \(error.localizedDescription)"
    }
  }
}

/// The interface for WebSocket connection.
public protocol WebSocket: Sendable {
  /// Sends text data to the connected peer.
  func send(text: String)

  /// Sends binary data to the connected peer.
  func send(binary: Data)

  /// Closes the WebSocket connection and the ``events`` `AsyncStream`.
  ///
  /// Sends a Close frame to the peer. If the optional `code` and `reason` arguments are given, they will be included in the Close frame. If no `code` is set then the peer will see a 1005 status code. If no `reason` is set then the peer will not receive a reason string.
  func close(code: Int?, reason: String?)

  @discardableResult
  func listen(_ callback: @escaping @Sendable (WebSocketEvent) -> Void) -> ObservationToken

  /// The WebSocket subprotocol negotiated with the peer.
  ///
  /// Will be the empty string if no subprotocol was negotiated.
  ///
  /// See [RFC-6455 1.9](https://datatracker.ietf.org/doc/html/rfc6455#section-1.9).
  var `protocol`: String { get }

  var isClosed: Bool { get }
}

extension WebSocket {
  /// Closes the WebSocket connection and the ``events`` `AsyncStream`.
  ///
  /// Sends a Close frame to the peer. If the optional `code` and `reason` arguments are given, they will be included in the Close frame. If no `code` is set then the peer will see a 1005 status code. If no `reason` is set then the peer will not receive a reason string.
  public func close() {
    self.close(code: nil, reason: nil)
  }

  /// An `AsyncStream` of ``WebSocketEvent`` received from the peer.
  ///
  /// Data received by the peer will be delivered as a ``WebSocketEvent/text(_:)`` or ``WebSocketEvent/binary(_:)``.
  ///
  /// If a ``WebSocketEvent/close(code:reason:)`` event is received then the `AsyncStream` will be closed. A ``WebSocketEvent/close(code:reason:)`` event indicates either that:
  ///
  /// - A close frame was received from the peer. `code` and `reason` will be set by the peer.
  /// - A failure occurred (e.g. the peer disconnected). `code` and `reason` will be a failure code defined by [RFC-6455](https://www.rfc-editor.org/rfc/rfc6455.html#section-7.4.1) (e.g. 1006).
  ///
  /// Errors will never appear in this `AsyncStream`.
  public var events: AsyncStream<WebSocketEvent> {
    let (stream, continuation) = AsyncStream<WebSocketEvent>.makeStream()
    let token = self.listen { event in
      continuation.yield(event)

      if case .close = event {
        continuation.finish()
      }
    }

    continuation.onTermination = { _ in token.cancel() }
    return stream
  }
}

public struct ObservationToken: Sendable {
  var onCancel: @Sendable () -> Void

  package init(_ onCancel: @escaping @Sendable () -> Void) {
    self.onCancel = onCancel
  }

  public func cancel() {
    onCancel()
  }
}
