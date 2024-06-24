//
//  PlexTCPClient.swift
//  plexiOS
//
//  Created by lv on 2024/6/24.
//

import UIKit
import CocoaAsyncSocket



class PlexTCPService: NSObject {
    static let shared = PlexTCPService()
    var socket: GCDAsyncSocket!
    let queue = DispatchQueue(label: "plex.socket")
    override init() {
        super.init()
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: queue)
    }

    func connectToHost(host: String, onPort port: UInt16) {
        do {
            try socket.connect(toHost: host, onPort: port, withTimeout: 30.0)
        } catch let error {
            print("Error connecting: \(error.localizedDescription)")
        }
    }

    func sendMessage(message: PlexMessage) {
        self.queue.async {
            let data = message.toJSON().data(using: .utf8)!
            // 消息长度
            var messageLength = UInt32(data.count).bigEndian
            let lengthData = Data(bytes: &messageLength, count: MemoryLayout<UInt32>.size)
            
            // 先发送消息长度
            self.socket.write(lengthData, withTimeout: -1, tag: 0)
            self.socket.write(data, withTimeout: -1, tag: 0)
        }
    }
}

extension PlexTCPService: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Connected to \(host):\(port)")
        let message = PlexMessage.authServer(body: "223")
        sendMessage(message: message)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let message = PlexMessage.heartbeat()
            self.sendMessage(message: message)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let message = PlexMessage.init(uri: "/logic/test", body: "test")
            self.sendMessage(message: message)
        }
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("Data sent \(tag)")
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("didRead\(data.count)    tag:\(tag)")
        if let message = String(data: data, encoding: .utf8) {
            print("Received: \(message)")
            // 根据需要处理收到的消息
        }
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError error: Error?) {
        if let error = error {
            print("Disconnected with error: \(error.localizedDescription)")
        } else {
            print("Disconnected")
        }
    }
}
