import UIKit
import Didomi // Import the Didomi SDK
import GoogleMobileAds // Import GMA SDK

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize Didomi SDK as early as possible
        let params = DidomiInitializeParameters(
            apiKey: "d0661bea-d696-4069-b308-11057215c4c4"
            // Add other parameters if needed, e.g., localConfigurationPath, remoteConfigurationURL, etc.
        )
        Didomi.shared.initialize(params)

        // Register a listener for when the Didomi SDK is ready
        Didomi.shared.onReady {
            print("Didomi SDK is ready.")
            // Now that Didomi is ready and consent status can be retrieved,
            // initialize the Google Mobile Ads SDK.
            MobileAds.shared.start() // Initialize GMA SDK after Didomi is ready [8, 7]
            print("Google Mobile Ads SDK initialized after Didomi readiness.")

            // You can also trigger Didomi UI setup here if needed, e.g.:
            // Didomi.shared.setupUI(containerController: self.window?.rootViewController)
        }

        return true
    }
}
