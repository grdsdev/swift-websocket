import Foundation

public enum WebSocketEvent: Sendable {
  case text(String)
  case binary(Data)
  case close(code: WebSocketCloseCode?, reason: String)
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
public protocol WebSocket: Sendable, AnyObject {
  var closeCode: WebSocketCloseCode? { get }
  var closeReason: String? { get }

  /// Sends text data to the connected peer.
  func send(text: String)

  /// Sends binary data to the connected peer.
  func send(binary: Data)

  /// Closes the WebSocket connection and the ``events`` `AsyncStream`.
  ///
  /// Sends a Close frame to the peer. If the optional `code` and `reason` arguments are given, they will be included in the Close frame. If no `code` is set then the peer will see a 1005 status code. If no `reason` is set then the peer will not receive a reason string.
  func close(code: WebSocketCloseCode?, reason: String?)

  /// Listen for event messages in the connection.
  var onEvent: (@Sendable (WebSocketEvent) -> Void)? { get set }

  /// The WebSocket subprotocol negotiated with the peer.
  ///
  /// Will be the empty string if no subprotocol was negotiated.
  ///
  /// See [RFC-6455 1.9](https://datatracker.ietf.org/doc/html/rfc6455#section-1.9).
  var `protocol`: String { get }

  /// Whether connection is closed.
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
    self.onEvent = { event in
      continuation.yield(event)

      if case .close = event {
        continuation.finish()
      }
    }

    continuation.onTermination = { _ in
      self.onEvent = nil
    }
    return stream
  }
}

public struct WebSocketCloseCode: RawRepresentable, Sendable, Hashable {
  public var rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Indicates a normal closure, meaning that the purpose for which the connection was established has been fulfilled.
  public static let normalClosure = WebSocketCloseCode(rawValue: 1000)

  /// Indicates that an endpoint is "going away", such as a server going down or a browser having navigated away from a page.
  public static let goingAway = WebSocketCloseCode(rawValue: 1001)

  /// Indicates that an endpoint is terminating the connection due to a protocol error.
  public static let protocolError = WebSocketCloseCode(rawValue: 1002)

  /// Indicates that an endpoint is terminating the connection because it has received a type of data it cannot accept (e.g., an endpoint that understands only text data MAY send this if it receives a binary message).
  public static let unsupportedData = WebSocketCloseCode(rawValue: 1003)

  /// Is a reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. It is designated for use in applications expecting a status code to indicate that no status code was actually present.
  public static let noStatusReceived = WebSocketCloseCode(rawValue: 1005)

  /// Is a reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. It is designated for use in applications expecting a status code to indicate that the connection was closed abnormally, e.g., without sending or receiving a Close control frame.
  public static let abnormalClosure = WebSocketCloseCode(rawValue: 1006)

  /// Indicates that an endpoint is terminating the connection because it has received data within a message that was not consistent with the type of the message (e.g., non-UTF-8 [RFC3629] data within a text message).
  public static let invalidFramePayloadData = WebSocketCloseCode(rawValue: 1007)

  /// Indicates that an endpoint is terminating the connection because it has received a message that violates its policy. This is a generic status code that can be returned when there is no other more suitable status code (e.g., 1003 or 1009) or if there is a need to hide specific details about the policy.
  public static let policyViolation = WebSocketCloseCode(rawValue: 1008)

  /// Indicates that an endpoint is terminating the connection because it has received a message that is too big for it to process.
  public static let messageTooBig = WebSocketCloseCode(rawValue: 1009)

  /// Indicates that an endpoint (client) is terminating the connection because it has expected the server to negotiate one or more extension, but the server didn't return them in the response message of the WebSocket handshake. The list of extensions that are needed SHOULD appear in the `reason` part of the Close frame. Note that this status code is not used by the server, because it can fail the WebSocket handshake instead.
  public static let mandatoryExtensionMissing = WebSocketCloseCode(rawValue: 1010)

  /// Indicates that a server is terminating the connection because it encountered an unexpected condition that prevented it from fulfilling the request.
  public static let internalServerError = WebSocketCloseCode(rawValue: 1011)

  /// Is a reserved value and MUST NOT be set as a status code in a Close control frame by an endpoint. It is designated for use in applications expecting a status code to indicate that the connection was closed due to a failure to perform a TLS handshake (e.g., the server certificate can't be verified).
  public static let tlsHandshakeFailure = WebSocketCloseCode(rawValue: 1015)
}
