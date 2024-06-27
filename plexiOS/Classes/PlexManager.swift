//
//  PlexClient.swift
//  plexiOS
//
//  Created by lv on 2024/6/24.
//

import UIKit
import Reachability

@objc enum PlexInternetStatus:Int {
    /// 未知
    case None = 0
    /// 无网络
    case NoConnect
    /// WIFI网络
    case WiFi
    /// 移动网络
    case WWAN
}

@objc public enum PlexserverType:Int {
    /// 使用固定IP地址
    case ip = 0
    /// 使用URL获取
    case url
}
@objc public enum PlexConnectionStatus:Int {
    /// 未知
    case None = 0
    /// 连接中
    case Connecting
    /// 已连接
    case Connected
    /// 已断开连接
    case Disconnected
}

@objcMembers public class PlexManager: NSObject {
    public static let shared = PlexManager()
    public static let connectionStatusNotification = Notification.Name("PlexManagerConnectionStatusNotification")
    private let queue = DispatchQueue(label: "plexiOS.opt")
    /// 服务器设置参数
    private(set) var server:String = ""
    /// 服务器设置类型
    private(set) var serverType:PlexserverType = .ip
    /// 服务器连接IP
    private(set) var serverIp:String?
    /// 服务器连接端口
    private(set) var serverPort:UInt16?
    /// 认证参数
    private(set) var authBody:String = ""
    /// 认证是否成功
    private(set) var isAuthSuccess:Bool = false
    /// TCP连接对象
    private var tcpService:PlexTCPService?
    private var _connectionStatusVaule:PlexConnectionStatus = .None
    /// 连接状态
     private(set) var connectionStatusValue:PlexConnectionStatus {
        get{
            return _connectionStatusVaule
        }
        set{
            if _connectionStatusVaule != newValue {
                _connectionStatusVaule = newValue
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: PlexManager.connectionStatusNotification, object: self, userInfo: ["status":newValue.rawValue])
                }
            }
        }
    }
    
    /// 连接状态
    public var connectionStatus: PlexConnectionStatus {
        get {
            return connectionStatusValue
        }
    }
    
    private var reachbility:Reachability?
    private(set) var internetStatus:PlexInternetStatus = .None
    
    public override init() {
        super.init()
        internetAddObserver()
    }
    
    // MARK: - 参数设置
    
    /// 是否显示日志
    /// - Parameter show: true=显示
    public func showLog(_ show:Bool){
        PlexLog.showLog = show
    }
    
    /// 设置服务器地址[https://plex.developer.icu/plex/v1/server]
    public func setServerWithHttp(_ server:String) {
        //TODO: 连接中等状态设置无效
        self.server = server
        self.serverType = .url
    }
    /// 设置服务器地址[117.50.198.225:0578]
    public func setServerWithIpAndPort(_ server:String) {
        //TODO: 连接中等状态设置无效
        self.server = server
        self.serverType = .ip
        if let rangeOfColon = server.range(of: ":") {
            let ip = String(server[..<rangeOfColon.lowerBound])
            let portStr = String(server[rangeOfColon.upperBound...])
            self.serverIp = ip
            if let port = UInt16(portStr) {
                self.serverPort = port
            }
        }
    }
    
    /// 设置认证参数
    /// - Parameter body: 回调
    public func setAuth(_ body:String){
        self.authBody = body
    }
    
    // MARK: - 功能操作
    
    /// 连接服务器
    public func connent(){
        queue.async {
            self.connectionStatusValue = .Connecting
            if self.serverType == .url {//获取真实服务器地址
                PlexLog.showInfo("通过URL获取服务器IP")
                let semaphore = DispatchSemaphore(value: 0)
                self.fetchHost(from: self.server) { result in
                    switch result {
                    case .success(let json):
                        if let host = json?["host"] as? String {
                            if let rangeOfColon = host.range(of: ":") {
                                let ip = String(host[..<rangeOfColon.lowerBound])
                                let portStr = String(host[rangeOfColon.upperBound...])
                                self.serverIp = ip
                                if let port = UInt16(portStr) {
                                    self.serverPort = port
                                }
                            }
                        }
                    case .failure(let error):
                        PlexLog.showError("获取服务IP失败:\(error.localizedDescription)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }
        queue.async {
            if let ip = self.serverIp, let port = self.serverPort {//连接服务器
                PlexLog.showInfo("开始连接服务器 ->\(ip):\(port)")
                let tcp = PlexTCPService(server: ip, port: port)
                tcp.delegate = self
                tcp.connect()
                self.tcpService = tcp
            }else if self.serverType == .url{//如果通过url获取服务进行重新连接操作
                
                PlexLog.showError("服务器IP或端口错误")
                self.connectionStatusValue = .None
                DispatchQueue.main.async {
                    //TODO: 重连次数检查
                    self.connent()
                }
            }else{
                
                PlexLog.showError("服务器IP或端口错误")
                self.connectionStatusValue = .None
            }
        }
        
        //        client.connectToserver(server: "172.16.5.142", onPort: 3000)
        //        DispatchQueue.main.async {
        //            self.client.sendMessage(message: "AAAABBBB")
        //        }
    }
    
    
    
    /// 断开连接
    public func disconnect(){
        queue.async {
            if let tcp = self.tcpService {
                tcp.disconnect()
            }
            self.isAuthSuccess = false
        }
    }
    
    /// 重启连接
    public func reconnect(){
        if let tcp = tcpService {
            tcp.disconnect()
            tcp.connect()
        }else{
            //TODO: 当前无连接报错
            PlexLog.showError("当前未连接服务器,无法执行重新连接操作")
            self.connectionStatusValue = .None
        }
    }
    
}

extension PlexManager: PlexTCPServiceDelegate {
    
    
    func tcpConnected(_ tcp: PlexTCPService, toServer server: String, port: UInt16) {
        PlexLog.showInfo("服务器连接成功 ->\(server):\(port)")
        self.connectionStatusValue = .Connected
//        let heartbeat = PlexMessage.heartbeat()
//        tcp.sendMessage(heartbeat)
        let auth = PlexMessage.authServer(body: self.authBody)
        tcp.sendMessage(auth)//发送认证消息
    }
    
    func tcpConnectFail(_ tcp: PlexTCPService, withError error: (any Error)?) {
        PlexLog.showInfo("连接失败:\(error?.localizedDescription ?? "")")
        self.connectionStatusValue = .Disconnected
    }
    
    func tcpDisconnect(_ tcp: PlexTCPService, withError error: (any Error)?) {
        PlexLog.showInfo("断开连接:\(error?.localizedDescription ?? "")")
        self.connectionStatusValue = .Disconnected
    }
    
    func tcpSendSuccess(_ tcp: PlexTCPService, withMessage message: PlexMessage) {
        PlexLog.showInfo("消息发送成功 ->\(message.uri)")
    }
    
    func tcpReceive(_ tcp: PlexTCPService, withMessage message: PlexMessage) {
        PlexLog.showInfo("消息接收成功 ->\(message.uri)")
        if message.uri == PlexMessage.authSuccessUri {//认证成功
            
        }else if message.uri == PlexMessage.authFailedUri {//认证失败
            
        } else if message.uri == PlexMessage.heartbeatUri {//心跳包
            
        }
    }
}


extension PlexManager {
    
    @objc func internetAddObserver(){
        self.reachbility = Reachability.forInternetConnection()
        self.reachbility?.startNotifier()
        self.internetReachabilityChange()
        NotificationCenter.default.addObserver(self, selector: #selector(internetReachabilityChange), name: Notification.Name.init("kReachabilityChangedNotification"), object: nil)
    }
    
    @objc func internetReachabilityChange(){
        if Reachability.forInternetConnection().currentReachabilityStatus() == .ReachableViaWWAN {
            NSLog("Plex-InternetConnection移动蜂窝")
            self.internetStatus = .WWAN
        }else if Reachability.forInternetConnection().currentReachabilityStatus() == .ReachableViaWiFi {
            NSLog("Plex-InternetConnection无线网络")
            self.internetStatus = .WiFi
        }else if  Reachability.forInternetConnection().currentReachabilityStatus() == .NotReachable {
            NSLog("Plex-InternetConnection无网络")
            self.internetStatus = .NoConnect
        }else{
            self.internetStatus = .None
        }
    }
}

extension PlexManager {
    /// 通过URL获取服务器IP
    /// - Parameters:
    ///   - url: URL地址
    ///   - completion: 回调
    func fetchHost(from url: String, completion: @escaping(Result<[String: Any]?, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                // 这里假设服务器返回的是JSON格式的数据
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    completion(.success(json)) // 你可以根据需要处理json对象
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
