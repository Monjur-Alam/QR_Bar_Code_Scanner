//
//  AppDelegate.swift
//  QR_Bar_Code_Scanner
//
//  Created by MunjurAlam on 15/9/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        let rootViewController = UINavigationController(rootViewController: ScannerViewController())
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        return true
    }


}

