import Foundation

public final class FakeWebSocket: WebSocket {
  struct MutableState {
    var isClosed: Bool = false
    weak var other: FakeWebSocket?
    var onEvent: (@Sendable (WebSocketEvent) -> Void)?

    var sentEvents: [WebSocketEvent] = []
    var closeCode: WebSocketCloseCode?
    var closeReason: String?
  }

  private let mutableState = LockIsolated(MutableState())

  private init(`protocol`: String) {
    self.`protocol` = `protocol`
  }

  public var sentEvents: [WebSocketEvent] {
    mutableState.value.sentEvents
  }

  public var receivedEvents: [WebSocketEvent] {
    mutableState.value.other?.sentEvents ?? []
  }

  public var closeCode: WebSocketCloseCode? {
    mutableState.value.closeCode
  }

  public var closeReason: String? {
    mutableState.value.closeReason
  }

  public func close(code: WebSocketCloseCode?, reason: String?) {
    mutableState.withValue { s in
      if s.isClosed { return }

      s.isClosed = true
      if s.other?.isClosed == false {
        s.other?._trigger(.close(code: code ?? .noStatusReceived, reason: reason ?? ""))
      }
    }
  }

  public func send(text: String) {
    mutableState.withValue {
      guard !$0.isClosed else { return }

      if $0.other?.isClosed == false {
        $0.other?._trigger(.text(text))
      }
    }
  }

  public func send(binary: Data) {
    mutableState.withValue {
      guard !$0.isClosed else { return }

      if $0.other?.isClosed == false {
        $0.other?._trigger(.binary(binary))
      }
    }
  }

  public var onEvent: (@Sendable (WebSocketEvent) -> Void)? {
    get { mutableState.value.onEvent }
    set { mutableState.withValue { $0.onEvent = newValue } }
  }

  public let `protocol`: String

  public var isClosed: Bool {
    mutableState.value.isClosed
  }

  func _trigger(_ event: WebSocketEvent) {
    mutableState.withValue {
      $0.sentEvents.append(event)
      $0.onEvent?(event)

      if case .close(let code, let reason) = event {
        $0.onEvent = nil
        $0.isClosed = true
        $0.closeCode = code
        $0.closeReason = reason
      }
    }
  }

  /// Creates a pair of fake ``WebSocket``s that are connected to each other.
  ///
  /// Sending a message on one ``WebSocket`` will result in that same message being
  /// received by the other.
  ///
  /// This can be useful in constructing tests.
  public static func fakes(`protocol`: String = "") -> (FakeWebSocket, FakeWebSocket) {
    let (peer1, peer2) = (FakeWebSocket(protocol: `protocol`), FakeWebSocket(protocol: `protocol`))

    peer1.mutableState.withValue { $0.other = peer2 }
    peer2.mutableState.withValue { $0.other = peer1 }

    return (peer1, peer2)
  }
}
