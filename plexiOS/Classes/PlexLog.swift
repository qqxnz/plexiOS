//
//  PlexLog.swift
//  plexiOS
//
//  Created by lv on 2024/6/26.
//

import UIKit

class PlexLog: NSObject {
    
    static var showLog:Bool = false
    
    static func showInfo(_ text:String){
        NSLog("Plex Info:==>%@\n", text)
    }
    
    static func showWarn(_ text:String){
        NSLog("Plex Warn:==>%@\n", text)
    }
    
    static func showError(_ text:String){
        NSLog("Plex Error:==>%@\n", text)
    }

}
