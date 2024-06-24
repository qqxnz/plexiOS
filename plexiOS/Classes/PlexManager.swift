//
//  PlexClient.swift
//  plexiOS
//
//  Created by lv on 2024/6/24.
//

import UIKit

open class PlexManager: NSObject {
    public static let shared = PlexManager()
    let client = PlexTCPService.shared
    
    open func connent(){
        client.connectToHost(host: "117.50.198.225", onPort: 9578)
//        DispatchQueue.main.async {
//            self.client.sendMessage(message: "AAAABBBB")
//        }
    }
    
}
