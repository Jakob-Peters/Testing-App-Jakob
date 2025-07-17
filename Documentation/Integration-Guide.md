# AdSDK Integration Guide

## Installation

### 1. Add AdSDK to Your Project

Add the AdSDK sources to your Xcode project:

```
YourProject/
├── Sources/
│   └── AdSDK/
│       ├── AdSDK.swift
│       ├── Models/
│       ├── Views/
│       ├── Controllers/
│       ├── Utils/
│       └── Resources/
```

### 2. Dependencies

Ensure you have the required dependencies in your project:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/didomi/swift-sdk", from: "1.0.0"),
    .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "9.0.0")
]
```

## Basic Setup

### 1. AppDelegate Configuration

```swift
import UIKit
import AdSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize AdSDK
        AdSDK.shared.initialize(
            baseURL: "https://your-domain.com/ad-template.html",
            didomiApiKey: "your-didomi-api-key",
            yieldManagerId: "your-yield-manager-id",
            debugMode: true // Set to false for production
        )
        
        return true
    }
}
```

### 2. SwiftUI App Integration

```swift
import SwiftUI
import AdSDK

@main
struct YourApp: App {
    init() {
        // Initialize AdSDK
        let config = AdSDK.configurationBuilder()
            .setBaseURL("https://your-domain.com/ad-template.html")
            .setDidomiApiKey("your-didomi-api-key")
            .setYieldManagerId("your-yield-manager-id")
            .setDebugMode(true)
            .setVerboseLogging(true)
            .build()
        
        AdSDK.shared.initialize(with: config)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Using AdWebView

### Basic Usage

```swift
import SwiftUI
import AdSDK

struct ContentView: View {
    @State private var adSize = CGSize(width: 320, height: 250)
    
    var body: some View {
        VStack {
            Text("Your content here")
            
            AdWebView(
                adUnitId: "your-ad-unit-id",
                adSize: $adSize,
                debugMode: true
            )
            .frame(width: adSize.width, height: adSize.height)
            .border(Color.gray)
            
            Text("More content")
        }
    }
}
```

### Advanced Usage with Configuration

```swift
struct AdvancedAdView: View {
    @State private var adSize = CGSize(width: 300, height: 250)
    @State private var loadingState: AdLoadingState = .idle
    
    var body: some View {
        let adUnitConfig = AdUnitConfiguration(
            adUnitId: "your-ad-unit-id",
            debugMode: true,
            customParameters: [
                "placement": "main-content",
                "targeting_age": "25-34"
            ]
        )
        
        AdWebView(
            adUnitConfig: adUnitConfig,
            globalConfig: AdSDK.shared.configuration,
            adSize: $adSize,
            onSizeChanged: { size in
                print("Ad size changed to: \(size)")
            },
            onStateChanged: { state in
                loadingState = state
            }
        )
        .frame(width: adSize.width, height: adSize.height)
        .overlay(
            loadingIndicator,
            alignment: .center
        )
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        if case .loading = loadingState {
            ProgressView("Loading ad...")
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
        }
    }
}
```

## Convenience Views

### Banner Ad

```swift
struct BannerAdExample: View {
    var body: some View {
        VStack {
            Text("Article content")
            
            AdBannerView(
                adUnitId: "banner-ad-unit",
                debugMode: true
            )
            
            Text("More content")
        }
    }
}
```

### Medium Rectangle Ad

```swift
struct MediumRectangleExample: View {
    var body: some View {
        VStack {
            Text("Article content")
            
            AdMediumRectangleView(
                adUnitId: "medium-rectangle-ad-unit",
                debugMode: true
            )
            
            Text("More content")
        }
    }
}
```

### Responsive Ad

```swift
struct ResponsiveAdExample: View {
    var body: some View {
        VStack {
            Text("Article content")
            
            AdResponsiveView(
                adUnitId: "responsive-ad-unit",
                maxWidth: 400,
                debugMode: true
            )
            
            Text("More content")
        }
    }
}
```

## Consent Management

### Basic Consent Button

```swift
struct ConsentExample: View {
    var body: some View {
        VStack {
            Text("Your app content")
            
            ConsentButton(
                title: "Manage Privacy Settings",
                onConsentChanged: { status in
                    print("Consent status: \(status)")
                }
            )
        }
    }
}
```

### Consent Banner

```swift
struct ConsentBannerExample: View {
    var body: some View {
        VStack {
            Text("Your app content")
            
            Spacer()
            
            ConsentBanner { status in
                print("Consent updated: \(status)")
            }
        }
    }
}
```

### Manual Consent Management

```swift
struct ManualConsentExample: View {
    @State private var consentStatus: ConsentStatus = .unknown
    
    var body: some View {
        VStack {
            Text("Consent Status: \(consentStatus)")
            
            Button("Show Consent Preferences") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    AdSDK.shared.showConsentPreferences(from: rootVC)
                }
            }
            
            Button("Reset Consent") {
                AdSDK.shared.resetConsent()
            }
        }
        .onAppear {
            consentStatus = AdSDK.shared.getConsentStatus()
        }
    }
}
```

## Debug Mode

### Enabling Debug Mode

```swift
// Global debug mode
AdSDK.shared.setDebugMode(true)

// Per-ad debug mode
AdWebView(
    adUnitId: "test-ad",
    adSize: $adSize,
    debugMode: true
)
```

### Debug Features

When debug mode is enabled, you get:

- Detailed console logging
- `aym_debug=true` query parameter in ad URLs
- JavaScript error forwarding
- Size change notifications
- Network request logging

### Custom Debug Logging

```swift
// Set custom log handler
AdSDK.shared.setConsoleLogHandler { level, message, timestamp in
    print("[\(level)] \(timestamp): \(message)")
}

// Enable verbose logging
AdSDK.shared.setVerboseLogging(true)
```

## HTML Template Customization

### Basic Template Structure

The HTML template includes:

1. **Didomi CMP Integration**: Automatic consent management
2. **Yield Manager Integration**: Ad serving
3. **Size Monitoring**: Dynamic size updates
4. **Debug Support**: Conditional logging
5. **Responsive Styling**: Flexible layout

### Template Parameters

The template accepts these URL parameters:

- `adUnitId`: Ad unit identifier
- `aym_debug`: Debug mode (true/false)
- `didomi_key`: Didomi API key
- `yield_manager`: Yield Manager ID
- `placement`: Ad placement identifier
- `targeting_*`: Targeting parameters

### Custom Parameters

```swift
let adUnitConfig = AdUnitConfiguration(
    adUnitId: "custom-ad",
    customParameters: [
        "placement": "header",
        "targeting_age": "25-34",
        "targeting_gender": "male"
    ]
)
```

## Error Handling

### Loading State Management

```swift
struct ErrorHandlingExample: View {
    @State private var adSize = CGSize(width: 320, height: 250)
    @State private var loadingState: AdLoadingState = .idle
    
    var body: some View {
        VStack {
            switch loadingState {
            case .idle:
                Text("Ad not loaded")
            case .loading:
                ProgressView("Loading ad...")
            case .loaded:
                AdWebView(
                    adUnitId: "example-ad",
                    adSize: $adSize,
                    onStateChanged: { state in
                        loadingState = state
                    }
                )
                .frame(width: adSize.width, height: adSize.height)
            case .failed(let error):
                Text("Ad failed to load: \(error.localizedDescription)")
                    .foregroundColor(.red)
            case .sizeUpdated(let size):
                Text("Ad size updated: \(size)")
                    .foregroundColor(.blue)
            }
        }
    }
}
```

## Best Practices

### 1. Initialization

- Initialize AdSDK in `AppDelegate` or `App.init()`
- Use production configuration for App Store builds
- Enable debug mode only during development

### 2. Ad Placement

- Use appropriate ad sizes for your layout
- Implement proper error handling
- Respect user consent preferences

### 3. Debug Mode

- Always disable debug mode in production
- Use verbose logging for development
- Monitor console output for issues

### 4. Performance

- Reuse ad views when possible
- Implement proper cleanup in `deinit`
- Monitor memory usage

### 5. Privacy

- Always check consent status before showing ads
- Provide clear privacy controls
- Respect user preferences

## Troubleshooting

### Common Issues

1. **Ads not loading**: Check debug console for JavaScript errors
2. **Size not updating**: Ensure size monitoring is enabled
3. **Consent not working**: Verify Didomi API key
4. **Debug logs missing**: Enable debug mode and console logging

### Debug Commands

```swift
// Check SDK status
print("SDK initialized: \(AdSDK.shared.isSDKInitialized())")

// Get debug info
print("Debug info: \(AdSDK.shared.getDebugInfo())")

// Clear cache
AdSDK.shared.clearCache()

// Check consent status
print("Consent: \(AdSDK.shared.getConsentStatus())")
```
