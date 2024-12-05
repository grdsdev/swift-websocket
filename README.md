# swift-websocket

A WebSocket interface for Swift.

## Getting started

```swift
import WebSocket
import WebSocketFoundation

let ws: any WebSocket = try await URLSessionWebSocket.connect(
  to: URL(string: "wss://echo.websocket.org/.ws")!
)

ws.onEvent = { event in
  print("received", event)
}

ws.send(text: "Hello, WebSocket!")

ws.close()
```
