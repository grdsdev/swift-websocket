# swift-websocket

A lightweight, protocol-based WebSocket interface for Swift applications. This
library provides a clean abstraction for WebSocket connections with both real
and mock implementations for testing.

## Features

- Protocol-based WebSocket interface
- Foundation-based implementation using URLSession
- Mock WebSocket implementation for testing
- Support for text and binary messages
- Async/await API support
- Comprehensive error handling
- Cross-platform support (iOS, macOS, tvOS, watchOS)

## Installation

Add the following to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/yourusername/swift-websocket.git", from: "1.0.0")
]
```

Then add the dependencies to your target:

```swift
.target(
  name: "YourTarget",
  dependencies: [
    .product(name: "WebSocket", package: "swift-websocket"),
    .product(name: "WebSocketFoundation", package: "swift-websocket")
  ]
)
```

## Usage

### Basic Usage

```swift
import WebSocket
import WebSocketFoundation

// Connect to a WebSocket server
let ws: any WebSocket = try await URLSessionWebSocket.connect(
  to: URL(string: "wss://echo.websocket.org/.ws")!
)

// Set up event handler
ws.onEvent = { event in
  switch event {
  case .text(let text):
    print("Received text: \(text)")
  case .binary(let data):
    print("Received binary data: \(data)")
  case .close(let code, let reason):
    print("Connection closed: \(code ?? 0) - \(reason)")
  }
}

// Send messages
ws.send("Hello, WebSocket!")

// Send binary data
let data = "Hello".data(using: .utf8)!
ws.send(data)

// Close the connection
ws.close(code: 1000, reason: "Normal closure")
```

### Using AsyncStream

The library provides an `AsyncStream` interface for handling WebSocket events:

```swift
// Using async/await with events stream
for await event in ws.events {
  switch event {
  case .text(let text):
    print("Received: \(text)")
  case .binary(let data):
    print("Received binary: \(data)")
  case .close(let code, let reason):
    print("Connection closed: \(code ?? 0) - \(reason)")
  }
}
```

### Testing with `FakeWebSocket`

The library includes a `FakeWebSocket` implementation for testing purposes. It
allows you to create a pair of connected WebSockets for testing your
WebSocket-based features:

```swift
import XCTest
import WebSocket

class YourTests: XCTestCase {
  func testWebSocketCommunication() {
    // Create a pair of connected fake WebSockets
    let (client, server) = FakeWebSocket.fakes()
    
    // Set up expectations
    let expectation = XCTestExpectation(description: "Message received")
    
    // Handle server-side events
    server.onEvent = { event in
      if case .text(let text) = event {
        XCTAssertEqual(text, "Hello")
        expectation.fulfill()
      }
    }
    
    // Send message from client
    client.send("Hello")
    
    // Verify message was received
    wait(for: [expectation], timeout: 1.0)
    
    // Verify sent/received events
    XCTAssertEqual(client.sentEvents.count, 1)
    XCTAssertEqual(server.receivedEvents.count, 1)
  }
}
```

## Error Handling

The library provides a `WebSocketError` enum for handling connection-related
errors:

```swift
do {
  let ws = try await URLSessionWebSocket.connect(to: url)
  // Use websocket
} catch let error as WebSocketError {
  switch error {
  case .connection(let message, let underlyingError):
    print("Connection failed: \(message) - \(underlyingError)")
  }
}
```

## Platform Support

- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+

## License

[Add your license information here]
