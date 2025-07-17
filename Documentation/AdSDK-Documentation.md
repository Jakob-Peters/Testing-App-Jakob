# AdSDK Documentation

## Overview

AdSDK is a modular iOS SDK designed to provide seamless integration of web-based advertisements with built-in consent management using the Didomi CMP (Consent Management Platform). The SDK supports dynamic ad sizing, debugging capabilities, and comprehensive logging.

## Features

- **Modular Architecture**: Clean separation of concerns with dedicated modules for Views, Controllers, Models, and Utilities
- **Web-based Ad Rendering**: HTML template-based ad display with JavaScript size monitoring
- **Didomi Integration**: Built-in consent management with GDPR compliance
- **Google Mobile Ads Support**: Integration with Google Mobile Ads SDK
- **Dynamic Sizing**: Automatic ad unit resizing based on content
- **Debug Tools**: Comprehensive debugging and logging capabilities
- **Customizable Configuration**: Flexible configuration options for different ad scenarios

## Architecture

### Core Components

```
Sources/AdSDK/
├── AdSDK.swift              # Main SDK class with singleton pattern
├── Controllers/             # View controllers for ad management
│   └── AdWebViewController.swift
├── Models/                  # Data models and configuration
│   ├── AdConfiguration.swift
│   └── AdDebugger.swift
├── Utils/                   # Utility classes and helpers
│   ├── AdSDKDebugToggle.swift
│   ├── AdURLBuilder.swift
│   └── ConsoleLogHandler.swift
├── Views/                   # SwiftUI and UIKit views
│   ├── AdWebView.swift
│   └── ConsentManagementView.swift
└── Resources/               # HTML templates and assets
    └── ad-template.html
```

### Dependencies

- **Didomi SDK**: v2.26.2 for consent management
- **Google Mobile Ads SDK**: v12.7.0 for ad serving
- **iOS**: Minimum deployment target 18.5
- **Swift**: Version 5.0+

## Getting Started

### Installation

1. **Swift Package Manager**: Add the following dependencies to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/didomi/didomi-ios-sdk-spm", from: "2.26.2"),
    .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "12.7.0")
]
```

2. **Xcode Project**: Add the AdSDK source files to your project.

### Basic Usage

```swift
import SwiftUI
import AdSDK

struct ContentView: View {
    var body: some View {
        VStack {
            AdWebView(
                configuration: AdConfiguration(
                    baseURL: "https://your-ad-server.com",
                    didomiApiKey: "your-didomi-api-key",
                    yieldManagerId: "your-yield-manager-id"
                )
            )
            .frame(minHeight: 250)
        }
    }
}
```

### Configuration

#### AdConfiguration

```swift
let configuration = AdConfiguration(
    baseURL: "https://your-ad-server.com",
    didomiApiKey: "your-didomi-api-key",
    yieldManagerId: "your-yield-manager-id",
    debugMode: true,
    customParameters: ["key": "value"],
    consoleLoggingEnabled: true
)
```

#### Using the Builder Pattern

```swift
let configuration = AdConfigurationBuilder()
    .setBaseURL("https://your-ad-server.com")
    .setDidomiApiKey("your-didomi-api-key")
    .setYieldManagerId("your-yield-manager-id")
    .setDebugMode(true)
    .setConsoleLoggingEnabled(true)
    .build()
```

## Core Classes

### AdSDK

The main SDK class providing singleton access to core functionality.

```swift
// Initialize the SDK
AdSDK.shared.initialize(with: configuration)

// Get current configuration
let config = AdSDK.shared.configuration

// Check if debug mode is enabled
let isDebugMode = AdSDK.shared.isDebugMode
```

### AdWebView

SwiftUI view for displaying web-based advertisements.

```swift
AdWebView(
    configuration: configuration,
    onSizeChange: { size in
        // Handle size changes
    },
    onError: { error in
        // Handle errors
    }
)
```

### ConsentManagementView

SwiftUI view for managing user consent with Didomi.

```swift
ConsentManagementView(
    didomiApiKey: "your-api-key",
    onConsentStatusChanged: { status in
        // Handle consent status changes
    }
)
```

### AdWebViewController

UIKit view controller for advanced ad management scenarios.

```swift
let controller = AdWebViewController(configuration: configuration)
controller.delegate = self
present(controller, animated: true)
```

## Advanced Features

### Custom HTML Templates

The SDK uses HTML templates for ad rendering. You can customize the template in `Resources/ad-template.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ad Unit</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
        }
        /* Your custom styles */
    </style>
</head>
<body>
    <div id="didomi-host"></div>
    <div id="ad-container">
        <!-- Ad content will be injected here -->
    </div>
    
    <script>
        // Size monitoring and reporting
        function reportSize() {
            const container = document.getElementById('ad-container');
            const size = {
                width: container.offsetWidth,
                height: container.offsetHeight
            };
            window.webkit.messageHandlers.sizeHandler.postMessage(size);
        }
        
        // Report size changes
        window.addEventListener('resize', reportSize);
        window.addEventListener('load', reportSize);
        
        // Mutation observer for content changes
        const observer = new MutationObserver(reportSize);
        observer.observe(document.body, {
            childList: true,
            subtree: true,
            attributes: true
        });
    </script>
</body>
</html>
```

### Debugging and Logging

#### Enable Debug Mode

```swift
// Global debug toggle
AdSDK.shared.setDebugMode(true)

// Console logging
AdSDK.shared.setConsoleLoggingEnabled(true)

// Verbose logging
AdSDK.shared.setVerboseLoggingEnabled(true)
```

#### Debug Toggle UI

```swift
struct DebugControlsView: View {
    @State private var debugMode = false
    @State private var consoleLogging = false
    @State private var verboseLogging = false
    
    var body: some View {
        VStack {
            AdSDKDebugToggle(
                debugMode: $debugMode,
                consoleLogging: $consoleLogging,
                verboseLogging: $verboseLogging
            )
        }
    }
}
```

### Event Handling

#### Consent Status Changes

```swift
AdSDK.shared.onConsentChanged = { status in
    switch status {
    case .granted:
        print("Consent granted")
    case .denied:
        print("Consent denied")
    case .unknown:
        print("Consent status unknown")
    }
}
```

#### Ad Loading Events

```swift
AdWebView(configuration: configuration)
    .onAdLoaded {
        print("Ad loaded successfully")
    }
    .onAdFailed { error in
        print("Ad failed to load: \(error)")
    }
    .onAdSizeChanged { size in
        print("Ad size changed to: \(size)")
    }
```

## Error Handling

The SDK provides comprehensive error handling:

```swift
enum AdSDKError: Error {
    case configurationError(String)
    case networkError(String)
    case consentError(String)
    case webViewError(String)
    
    var localizedDescription: String {
        switch self {
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .consentError(let message):
            return "Consent error: \(message)"
        case .webViewError(let message):
            return "WebView error: \(message)"
        }
    }
}
```

## Best Practices

### 1. Configuration Management

- Store sensitive API keys securely
- Use different configurations for debug/release builds
- Validate configurations before use

### 2. Performance Optimization

- Use lazy loading for ad content
- Implement proper caching strategies
- Monitor memory usage with web views

### 3. User Experience

- Provide loading indicators
- Handle consent flows gracefully
- Implement proper error messaging

### 4. Testing

- Test with different ad sizes
- Verify consent management flows
- Test error scenarios

## Troubleshooting

### Common Issues

1. **Ad not loading**: Check network connectivity and URL configuration
2. **Consent not working**: Verify Didomi API key and configuration
3. **Size issues**: Ensure proper CSS and JavaScript implementation
4. **Memory leaks**: Properly deallocate web views and observers

### Debug Logging

Enable verbose logging to diagnose issues:

```swift
AdSDK.shared.setVerboseLoggingEnabled(true)
```

Check console output for detailed information about:
- Network requests
- Consent status changes
- Web view events
- JavaScript execution

### Performance Monitoring

Monitor key metrics:
- Ad load times
- Memory usage
- Consent completion rates
- Error rates

## Migration Guide

### From Previous Versions

1. Update import statements
2. Replace deprecated APIs
3. Update configuration format
4. Test consent flows

### Breaking Changes

- `AdWebView` now requires explicit configuration
- Consent management is now mandatory
- Debug mode is disabled by default

## Examples

### Basic Integration

```swift
import SwiftUI
import AdSDK

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AdSDK.shared.initialize(with: AdConfiguration(
                        baseURL: "https://your-ad-server.com",
                        didomiApiKey: "your-didomi-api-key",
                        yieldManagerId: "your-yield-manager-id"
                    ))
                }
        }
    }
}
```

### Advanced Usage

```swift
struct AdvancedAdView: View {
    @State private var adSize: CGSize = .zero
    @State private var consentStatus: ConsentStatus = .unknown
    
    var body: some View {
        VStack {
            ConsentManagementView(
                didomiApiKey: "your-api-key",
                onConsentStatusChanged: { status in
                    consentStatus = status
                }
            )
            
            if consentStatus == .granted {
                AdWebView(
                    configuration: AdConfiguration(
                        baseURL: "https://your-ad-server.com",
                        didomiApiKey: "your-didomi-api-key",
                        yieldManagerId: "your-yield-manager-id"
                    ),
                    onSizeChange: { size in
                        adSize = size
                    }
                )
                .frame(width: adSize.width, height: adSize.height)
            }
        }
    }
}
```

## Support

For issues and questions:
1. Check the troubleshooting section
2. Enable debug logging
3. Review console output
4. Create detailed issue reports

## License

This SDK is provided under the MIT License. See LICENSE file for details.
