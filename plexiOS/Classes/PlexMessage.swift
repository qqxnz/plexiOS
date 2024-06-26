//
//  PlexMessage.swift
//  plexiOS
//
//  Created by lv on 2024/6/24.
//

import UIKit
import YYModel

@objcMembers public class PlexMessage: NSObject {
    
    static let messageHead:Int = -100
    static let messageBody:Int = -101
    
    private(set) var seq:Int64 = 0
    private(set) var uri:String = ""
    private(set) var body:String = ""
    
    static func withJSONString(_ json:String) -> PlexMessage?{
       return PlexMessage.yy_model(withJSON: json)
    }
    
    static func modelCustomPropertyMapper() -> [String : Any]? {
        return [:]
    }
    
    
    static func modelContainerPropertyGenericClass() -> [String : Any]? {
        return [:]
    }
    
    override init() {
        super.init()
    }
    
    convenience init(uri:String,body:String) {
        self.init()
        self.uri = uri
        self.body = body
    }
    
    func toJSON()->String {
       let message = self.yy_modelToJSONString() ?? ""
        return message
    }
}


extension PlexMessage {
    
    /// 心跳
    static let heartbeatUri = "/heartbeat"
    /// 认证
    static let authServerUri = "/auth/server"
    /// 认证成功
    static let authSuccessUri = "/auth/success"
    
    
    static func heartbeat()-> PlexMessage{
        return PlexMessage.init(uri: heartbeatUri, body: "")
    }
    
    static func authServer(body:String)-> PlexMessage{
        return PlexMessage.init(uri: authServerUri, body: body)
    }
}
