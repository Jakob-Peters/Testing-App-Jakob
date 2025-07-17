# AdSDK - Modular Ad Integration Framework

A modular Swift framework for integrating web-based ads with Didomi consent management and dynamic ad sizing.

## Overview

This framework provides a complete solution for displaying web-based ads in iOS applications with:
- Didomi consent management integration
- Dynamic ad sizing and responsive layout
- Modular architecture for easy integration
- Debug mode toggle for development
- Console logging bridge between JavaScript and Swift

## Features

- 🎯 **Modular Design**: Easy to integrate into any iOS project
- 🔒 **Consent Management**: Full Didomi SDK integration
- 📱 **Responsive Ads**: Dynamic sizing based on ad content
- 🐛 **Debug Mode**: Toggle for development and testing
- 🔗 **JavaScript Bridge**: Seamless communication between web and native
- 📊 **Console Logging**: JavaScript logs forwarded to Xcode console

## Architecture

```
AdSDK/
├── Models/
│   ├── AdConfiguration.swift       # Configuration and settings
│   └── AdDebugger.swift           # Debug mode management
├── Controllers/
│   └── AdWebViewController.swift   # Main ad web view controller
├── Views/
│   ├── AdWebView.swift            # SwiftUI wrapper
│   └── ConsentManagementView.swift # Didomi consent UI
├── Utils/
│   ├── AdURLBuilder.swift         # URL construction utilities
│   └── ConsoleLogHandler.swift    # JavaScript console bridge
└── Resources/
    └── ad-template.html           # HTML template for ads
```

## Quick Start

### 1. Integration

Add the AdSDK sources to your project and ensure you have the required dependencies:

```swift
// In your Package.swift or project dependencies
.package(url: "https://github.com/didomi/swift-sdk", from: "1.0.0")
.package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "9.0.0")
```

### 2. AppDelegate Setup

```swift
import UIKit
import AdSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize AdSDK with your configuration
        AdSDK.shared.initialize(
            didomiApiKey: "your-didomi-api-key",
            yieldManagerId: "your-yield-manager-id"
        )
        
        return true
    }
}
```

### 3. Basic Usage

```swift
import SwiftUI
import AdSDK

struct ContentView: View {
    @State private var adSize = CGSize(width: 320, height: 250)
    
    var body: some View {
        VStack {
            // Your content here
            
            AdWebView(
                adUnitId: "your-ad-unit-id",
                adSize: $adSize,
                debugMode: false
            )
            .frame(width: adSize.width, height: adSize.height)
            
            // More content
        }
    }
}
```

## Configuration

### Ad Configuration

```swift
let config = AdConfiguration(
    baseURL: "https://your-domain.com/ad-template.html",
    didomiApiKey: "your-didomi-api-key",
    yieldManagerId: "your-yield-manager-id",
    debugMode: true // Enable for development
)
```

### Debug Mode

Debug mode provides:
- Detailed console logging
- `aym_debug=true` query parameter
- JavaScript error forwarding
- Network request logging

```swift
// Enable debug mode globally
AdSDK.shared.setDebugMode(true)

// Or per ad unit
AdWebView(adUnitId: "test-ad", debugMode: true)
```

## HTML Template

The framework includes a customizable HTML template (`ad-template.html`) that handles:

- Didomi consent management
- Yield Manager ad loading
- Dynamic size monitoring
- Console logging bridge

### Template Features

1. **Didomi Integration**: Automatic consent synchronization
2. **Size Monitoring**: Real-time ad size updates
3. **Styling**: Responsive design for various screen sizes
4. **Debug Support**: Conditional logging and debugging tools

## Advanced Usage

### Custom Ad URLs

```swift
let urlBuilder = AdURLBuilder()
    .setAdUnitId("custom-ad-unit")
    .setDebugMode(true)
    .addCustomParameter("placement", "header")
    .build()
```

### Consent Management

```swift
// Show consent preferences
ConsentManagementView()
    .onConsentChanged { consentStatus in
        // Handle consent changes
        print("Consent status: \(consentStatus)")
    }
```

### Console Logging

```swift
// Custom log handler
AdSDK.shared.setConsoleLogHandler { level, message, timestamp in
    print("[\(level)] \(timestamp): \(message)")
}
```

## Best Practices

1. **Always check consent status** before loading ads
2. **Use debug mode** during development
3. **Test on various screen sizes** for responsive design
4. **Handle ad loading failures** gracefully
5. **Respect user privacy** settings

## Troubleshooting

### Common Issues

1. **Ads not loading**: Check console for JavaScript errors
2. **Size not updating**: Ensure size monitoring is enabled
3. **Consent not working**: Verify Didomi configuration
4. **Debug logs missing**: Enable debug mode

### Debug Commands

```swift
// Enable verbose logging
AdSDK.shared.setVerboseLogging(true)

// Clear ad cache
AdSDK.shared.clearCache()

// Test consent status
print("Consent status: \(AdSDK.shared.getConsentStatus())")
```

## Requirements

- iOS 14.0+
- Swift 5.5+
- Xcode 13.0+
- Didomi SDK
- Google Mobile Ads SDK (optional)

## License

[Your License Here]

## Support

For issues and questions, please refer to the documentation or contact the development team.
