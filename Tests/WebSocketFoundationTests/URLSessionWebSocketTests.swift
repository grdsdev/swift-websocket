import XCTest

@testable import WebSocketFoundation

final class URLSessionWebSocketTests: XCTestCase {
  func testWebSocketWithHTTPURL() async throws {
    let url = URL(string: "https://echo.websocket.org/.ws")!
    _ = try await URLSessionWebSocket.connect(to: url)
  }

  func testWebSocketSendText() async throws {
    let url = URL(string: "wss://echo.websocket.org/.ws")!
    let webSocket = try await URLSessionWebSocket.connect(to: url)
    let expectation = XCTestExpectation(description: "Receive text message")

    Task {
      for await case .text(let message) in webSocket.events.dropFirst() {
        XCTAssertEqual(message, "Hello, WebSocket!")
        expectation.fulfill()
      }
    }

    await Task.yield()

    webSocket.send("Hello, WebSocket!")
    await fulfillment(of: [expectation], timeout: 10)
  }

  func testWebSocketSendBinary() async throws {
    let url = URL(string: "wss://echo.websocket.org/.ws")!
    let webSocket = try await URLSessionWebSocket.connect(to: url)
    let expectation = XCTestExpectation(description: "Receive binary message")
    let data = "Hello, WebSocket!".data(using: .utf8)!

    webSocket.onEvent = { event in
      if case .binary(let receivedData) = event {
        XCTAssertEqual(receivedData, data)
        expectation.fulfill()
      }
    }

    webSocket.send(data)
    await fulfillment(of: [expectation], timeout: 10)
  }

  func testWebSocketClose() async throws {
    let url = URL(string: "wss://echo.websocket.org/.ws")!
    let webSocket = try await URLSessionWebSocket.connect(to: url)
    let expectation = XCTestExpectation(description: "WebSocket closed")

    webSocket.onEvent = { event in
      if case .close(let code, let reason) = event {
        XCTAssertEqual(code, 1000)
        XCTAssertEqual(reason, "Normal closure")
        expectation.fulfill()
      }
    }

    webSocket.close(code: 1000, reason: "Normal closure")
    webSocket.close()
    await fulfillment(of: [expectation], timeout: 10)

    XCTAssertEqual(webSocket.closeCode, 1000)
    XCTAssertEqual(webSocket.closeReason, "Normal closure")
  }
}
