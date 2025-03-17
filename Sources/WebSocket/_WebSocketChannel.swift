//
//  _WebSocketChannel.swift
//  WebSocket
//
//  Created by Guilherme Souza on 18/12/24.
//

import Foundation

public struct _WebSocketChannel: AsyncSequence {
  private let _conn = LockIsolated<(any WebSocket)?>(nil)
  private let connBuilder: () async throws -> any WebSocket

  public init(wrapping builder: @escaping () async throws -> any WebSocket) {
    self.connBuilder = builder
  }

  public var ready: Void {
    get async throws {
      let conn = try await connBuilder()
      _conn.withValue { $0 = conn }
    }
  }

  private var conn: any WebSocket {
    _conn.withValue { $0! }
  }

  public func send(text: String) {
    conn.send(text: text)
  }

  public func send(binary: Data) {
    conn.send(binary: binary)
  }

  public func close(code: WebSocketCloseCode? = nil, reason: String? = nil) {
    conn.close(code: code, reason: reason)
  }

  public func makeAsyncIterator() -> some AsyncIteratorProtocol {
    conn.events.makeAsyncIterator()
  }
}
