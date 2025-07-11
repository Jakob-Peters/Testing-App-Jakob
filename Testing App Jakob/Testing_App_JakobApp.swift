//
//  Testing_App_JakobApp.swift
//  Testing App Jakob
//
//  Created by Jakob Svanborg Peters on 11/07/2025.
//

import SwiftUI
import GoogleMobileAds // Import the SDK

@main
struct AdTechTestbedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate // You'll create this AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

