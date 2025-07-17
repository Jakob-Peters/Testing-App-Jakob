//
//  Testing_App_JakobApp.swift
//  Testing App Jakob
//
//  Created by Jakob Svanborg Peters on 11/07/2025.
//

import SwiftUI

@main
struct AdTechTestbedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RefactoredContentView()
        }
    }
}

