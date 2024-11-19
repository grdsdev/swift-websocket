//
//  main.swift
//  WebSocket
//
//  Created by Guilherme Souza on 19/11/24.
//

import Foundation
import WebSocket
import WebSocketFoundation

let requestId = 305

do {
  let socket: any WebSocket = try await URLSessionWebSocket.connect(
    to: URL(string: "wss://api.whitebit.com/ws")!)

  socket.listen { event in
    do {
      switch event {
      case .text(let text):
        let data = Data(text.utf8)
        let json = try JSONSerialization.jsonObject(with: data)
        print(json)
      case .binary:
        print("Unexpected binary data from server.")
        try socket.close()
      case .close(let code, let reason):
        print("Closed with code \(code ?? 0), reason: \(reason)")
      }
    } catch {
      print("Error: \(error)")
    }
  }

  try socket.send(
    text: """
    {
      "id": \(requestId),
      "method": "candles_subscribe",
      "params": ["BTC_USD", 5]
    }
    """
  )

} catch {
  debugPrint(error)
}
