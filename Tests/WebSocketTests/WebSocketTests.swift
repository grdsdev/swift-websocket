import XCTest

@testable import WebSocket

final class WebSocketTests: XCTestCase {
  func testExample() {
    let (client, server) = FakeWebSocket.fakes()

    client.onEvent = { event in
      print("client", event)
    }

    server.onEvent = { event in
      print("server", event)
    }

    client.send(text: "ping")
    server.send(text: "pong")

    client.close()
    _ = ()
  }
}
