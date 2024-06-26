//
//  PlexTCPClient.swift
//  plexiOS
//
//  Created by lv on 2024/6/24.
//

import UIKit
import CocoaAsyncSocket

@objc protocol PlexTCPServiceDelegate:NSObjectProtocol {
    /// 连接服务器成功
    /// - Parameters:
    ///   - tcp: 连接对象
    ///   - host: 服务器IP
    ///   - port: 服务器端口
    func tcpConnected(_ tcp:PlexTCPService,toHost host: String, port: UInt16)
    /// 连接服务器失败
    /// - Parameters:
    ///   - tcp: 连接对象
    ///   - error: 错误信息
    func tcpConnectFail(_ tcp:PlexTCPService,withError error: Error?)
    /// 与服务器断开连接
    /// - Parameters:
    ///   - tcp: 连接对象
    ///   - error: 错误信息
    func tcpDisconnect(_ tcp:PlexTCPService,withError error: Error?)
}

@objcMembers class PlexTCPService: NSObject {
    let socket = GCDAsyncSocket()
    let queue = DispatchQueue(label: "plexiOS.tcp")
    
    weak var delegate:PlexTCPServiceDelegate?
    
    override init() {
        super.init()
        self.socket.setDelegate(self, delegateQueue: self.queue)
    }

    func connectToHost(_ host: String, onPort port: UInt16) {
        do {
            try socket.connect(toHost: host, onPort: port, withTimeout: 5.0)//TODO: 超时时间
        } catch let error {
            PlexLog.showError("Error connecting: \(error.localizedDescription)")
            self.delegate?.tcpConnectFail(self, withError: error)
        }
    }

    func sendMessage(_ message: PlexMessage) {
        self.queue.async {
            let data = message.toJSON().data(using: .utf8)!
            // 消息长度
            var messageLength = UInt32(data.count).bigEndian
            let lengthData = Data(bytes: &messageLength, count: MemoryLayout<UInt32>.size)
            
            // 先发送消息长度
            self.socket.write(lengthData, withTimeout: -1, tag: PlexMessage.messageHead)
            self.socket.write(data, withTimeout: -1, tag: PlexMessage.messageBody)
        }
    }
    
    private func receiveMessage(_ message: PlexMessage){
        if message.uri == PlexMessage.heartbeatUri {//跳包
            
        }else if message.uri == PlexMessage.authSuccessUri {
            
        }
    }
}

extension PlexTCPService: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        PlexLog.showInfo("Connected ->\(host):\(port)")
        self.delegate?.tcpConnected(self, toHost: host, port: port)
        self.socket.readData(toLength: UInt(MemoryLayout<UInt32>.size), withTimeout: -1, tag: PlexMessage.messageHead)
//        let message = PlexMessage.authServer(body: "223")
//        sendMessage(message)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            let message = PlexMessage.heartbeat()
//            self.sendMessage(message)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            let message = PlexMessage.init(uri: "/logic/test", body: "test")
//            self.sendMessage(message)
//        }
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        PlexLog.showInfo("Send Data Success ->\(tag)")
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if tag == PlexMessage.messageHead {//消息头
            let messageLength = data.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            PlexLog.showInfo("Received Head: data body length --> \(messageLength)")
            self.socket.readData(toLength: UInt(messageLength), withTimeout: -1, tag: PlexMessage.messageBody)
        }else{
            if let json = String(data: data, encoding: .utf8) {
                PlexLog.showInfo("Received Body:\(json)")
                if let message = PlexMessage.withJSONString(json) {
                    receiveMessage(message)
                }else{
                    PlexLog.showError("Received Body Parsing Failed")
                }
            }
            self.socket.readData(toLength: UInt(MemoryLayout<UInt32>.size), withTimeout: -1, tag: PlexMessage.messageHead)
        }

    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError error: Error?) {
        if let error = error {
            PlexLog.showError("Disconnected with error: \(error.localizedDescription)")
        } else {
            PlexLog.showWarn("Disconnected")
        }
        self.delegate?.tcpDisconnect(self, withError: error)
    }
}
