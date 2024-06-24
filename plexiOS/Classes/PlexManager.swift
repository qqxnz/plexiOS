//
//  PlexClient.swift
//  plexiOS
//
//  Created by lv on 2024/6/24.
//

import UIKit
import Reachability



open class PlexManager: NSObject {
    public static let shared = PlexManager()
    let client = PlexTCPService.shared
    private var reachbility:Reachability?
    private(set) var internetStatus:PlexInternetStatus = .None
    
    public override init() {
        super.init()
        internetAddObserver()
    }
    
    open func connent(){

        
        client.connectToHost(host: "117.50.198.225", onPort: 9578)
//        DispatchQueue.main.async {
//            self.client.sendMessage(message: "AAAABBBB")
//        }
    }
    
}



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

