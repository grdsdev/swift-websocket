import Foundation

public final class FakeWebSocket: WebSocket {
  struct MutableState {
    var isClosed: Bool = false
    var callbacks: [(id: UUID, handler: @Sendable (WebSocketEvent) -> Void)] = []
    weak var other: FakeWebSocket?
  }

  private let mutableState = LockIsolated(MutableState())

  private init(`protocol`: String) {
    self.`protocol` = `protocol`
  }

  public func close(code: Int?, reason: String?) {
    mutableState.withValue { s in
      if s.isClosed { return }

      s.isClosed = true
      if s.other?.isClosed == false {
        s.other?._trigger(.close(code: code ?? 1005, reason: reason ?? ""))
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

  @discardableResult
  public func listen(_ callback: @escaping @Sendable (WebSocketEvent) -> Void) -> ObservationToken {
    let id = UUID()
    let token = ObservationToken { [weak self] in
      self?.mutableState.withValue {
        $0.callbacks.removeAll {
          $0.id == id
        }
      }
    }

    mutableState.withValue {
      $0.callbacks.append((id, callback))
    }

    return token
  }

  public let `protocol`: String

  public var isClosed: Bool {
    mutableState.value.isClosed
  }

  func _trigger(_ event: WebSocketEvent) {
    mutableState.withValue {
      $0.callbacks.forEach { $0.handler(event) }

      if case .close = event {
        $0.callbacks = []
        $0.isClosed = true
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
