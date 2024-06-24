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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            PlexManager.shared.connent()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

