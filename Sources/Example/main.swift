import Foundation
import WebSocket

//import WebSocketFoundation
//
//let requestId = 305
//
//do {
//  let socket: any WebSocket = try await URLSessionWebSocket.connect(
//    to: URL(string: "wss://api.whitebit.com/ws")!)
//
//  socket.listen { event in
//    do {
//      switch event {
//      case .text(let text):
//        let data = Data(text.utf8)
//        let json = try JSONSerialization.jsonObject(with: data)
//        print(json)
//      case .binary:
//        print("Unexpected binary data from server.")
//        try socket.close()
//      case .close(let code, let reason):
//        print("Closed with code \(code ?? 0), reason: \(reason)")
//      }
//    } catch {
//      print("Error: \(error)")
//    }
//  }
//
//  try socket.send(
//    text: """
//    {
//      "id": \(requestId),
//      "method": "candles_subscribe",
//      "params": ["BTC_USD", 5]
//    }
//    """
//  )
//
//} catch {
//  debugPrint(error)
//}

func fakeTimeServer(_ webSocket: any WebSocket, time: String) async {
  for await event in webSocket.events {
    switch event {
    case .text, .binary:
      webSocket.send(text: time)
    default: break
    }
  }
}

func getTime(_ webSocket: any WebSocket) async throws -> Date? {
  webSocket.send(text: "")
  let time: Date? =
    switch await webSocket.events.first(where: { _ in true }) {
    case .text(let text): ISO8601DateFormatter().date(from: text)!
    default: nil
    }
  webSocket.close()
  return time
}

let (client, server) = FakeWebSocket.fakes()

Task {
  await fakeTimeServer(server, time: "2024-05-15T01:18:10.456Z")
}
let time = try await getTime(client)
assert(time == Date(timeIntervalSince1970: 16114560.456))
