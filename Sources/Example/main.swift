import Foundation
import WebSocket
import WebSocketFoundation

let requestId = 305

do {
  let socket: any WebSocket = try await URLSessionWebSocket.connect(
    to: URL(string: "wss://echo.websocket.org/.ws")!)

  socket.onEvent = { event in
    print(event)
  }

  for i in 0... {
    socket.send("\(i)")
    try await Task.sleep(nanoseconds: NSEC_PER_SEC)
  }
} catch {
  debugPrint(error)
}
