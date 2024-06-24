//
//  PlexMessage.swift
//  plexiOS
//
//  Created by lv on 2024/6/24.
//

import UIKit
import YYModel


@objcMembers class PlexMessage: NSObject {

    
    private(set) var seq:Int64 = 0
    private(set) var uri:String = ""
    private(set) var body:String = ""
    
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
    static func heartbeat()-> PlexMessage{
        return PlexMessage.init(uri: "/heartbeat", body: "")
    }
    static func authServer(body:String)-> PlexMessage{
        return PlexMessage.init(uri: "/auth/server", body: body)
    }
}
