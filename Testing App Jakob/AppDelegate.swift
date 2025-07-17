import UIKit
import Didomi
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Initialize the AdSDK with configuration
        AdSDK.shared.initialize(
            baseURL: "https://adops.stepdev.dk/wp-content/ad-template-app.html",
            didomiApiKey: "d0661bea-d696-4069-b308-11057215c4c4",
            yieldManagerId: "AFtbN2xnQGXShTYuo",
            debugMode: true // Enable debug mode for development
        )
        
        return true
    }
}
