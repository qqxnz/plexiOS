//
//  ViewController.swift
//  plexiOS
//
//  Created by lv on 06/24/2024.
//  Copyright (c) 2024 lv. All rights reserved.
//

import UIKit
import plexiOS

class ViewController: UIViewController {

    @IBOutlet weak var statusLab: UILabel!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        NotificationCenter.default.addObserver(self, selector: #selector(plexConnectionStatus(notification: )), name: PlexManager.connectionStatusNotification, object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            PlexManager.shared.setServerWithHttp("https://plex.developer.icu/plex/v1/host")
            PlexManager.shared.setAuth("223")
            PlexManager.shared.connent()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func plexConnectionStatus(notification:Notification){
        if let manager = notification.object as? PlexManager {
            if manager.connectionStatus == .None {
                self.statusLab.text = "未连接"
            }else if manager.connectionStatus == .Connecting {
                self.statusLab.text = "连接中"
            }else if manager.connectionStatus == .Connected {
                self.statusLab.text = "已连接"
            }else if manager.connectionStatus == .Disconnected {
                self.statusLab.text = "已断开连接"
            }
        }
    }

}

