# Migration Guide: Refactoring to Modular AdSDK

This guide helps you migrate from the existing prototype to the new modular AdSDK structure.

## Overview

Your existing code has been refactored into a modular, well-documented framework with:

- Clear separation of concerns
- Centralized configuration
- Debug mode toggle
- Improved error handling
- Better documentation

## Migration Steps

### 1. Update AppDelegate

**Before:**
```swift
import UIKit
import Didomi
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let params = DidomiInitializeParameters(
            apiKey: "d0661bea-d696-4069-b308-11057215c4c4"
        )
        Didomi.shared.initialize(params)
        
        Didomi.shared.onReady {
            print("Didomi SDK is ready.")
            MobileAds.shared.start()
            print("Google Mobile Ads SDK initialized after Didomi readiness.")
        }
        
        return true
    }
}
```

**After:**
```swift
import UIKit
import AdSDK

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Initialize AdSDK with your configuration
        AdSDK.shared.initialize(
            baseURL: "https://adops.stepdev.dk/wp-content/google-test-ad.html",
            didomiApiKey: "d0661bea-d696-4069-b308-11057215c4c4",
            yieldManagerId: "AFtbN2xnQGXShTYuo",
            debugMode: true // Toggle for debug mode
        )
        
        return true
    }
}
```

### 2. Update ContentView

**Before:**
```swift
func adURL(adUnitId: String) -> URL? {
    var components = URLComponents(string: "https://adops.stepdev.dk/wp-content/google-test-ad.html")
    var items = [
        URLQueryItem(name: "adUnitId", value: adUnitId),
        URLQueryItem(name: "aym_debug", value: "true")
    ]
    components?.queryItems = items
    return components?.url
}

UIKitAdWebView(adUrl: adURL(adUnitId: "div-gpt-ad-mobile_1"), adSize: $adSizeFront)
    .frame(width: adSizeFront.width, height: max(adSizeFront.height, 100))
    .border(Color.gray, width: 1)
    .id(frontPageAdKey)
```

**After:**
```swift
AdWebView(
    adUnitId: "div-gpt-ad-mobile_1",
    adSize: $adSizeFront,
    debugMode: true // This will automatically add aym_debug=true
)
.frame(width: adSizeFront.width, height: max(adSizeFront.height, 100))
.border(Color.gray, width: 1)
.id(frontPageAdKey)
```

### 3. Update Article View

**Before:**
```swift
// First ad
UIKitAdWebView(adUrl: adURL(adUnitId: "div-gpt-ad-mobile_1"), adSize: $adSize1)
    .frame(width: adSize1.width, height: max(adSize1.height, 100))
    .border(Color.gray, width: 1)
    .id(adKey1)

// Second ad
UIKitAdWebView(adUrl: adURL(adUnitId: "div-gpt-ad-mobile_2"), adSize: $adSize2)
    .frame(width: adSize2.width, height: max(adSize2.height, 100))
    .border(Color.blue, width: 1)
    .id(adKey2)
```

**After:**
```swift
// First ad
AdWebView(
    adUnitId: "div-gpt-ad-mobile_1",
    adSize: $adSize1,
    debugMode: true
)
.frame(width: adSize1.width, height: max(adSize1.height, 100))
.border(Color.gray, width: 1)
.id(adKey1)

// Second ad
AdWebView(
    adUnitId: "div-gpt-ad-mobile_2",
    adSize: $adSize2,
    debugMode: true
)
.frame(width: adSize2.width, height: max(adSize2.height, 100))
.border(Color.blue, width: 1)
.id(adKey2)
```

### 4. Update Consent Management

**Before:**
```swift
Button(action: {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootVC = windowScene.windows.first?.rootViewController {
        if Didomi.shared.isReady() {
            Didomi.shared.showPreferences(controller: rootVC)
        } else {
            Didomi.shared.onReady {
                Didomi.shared.showPreferences(controller: rootVC)
            }
        }
    }
}) {
    Text("Change Consent (Didomi)")
        .font(.headline)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
}
```

**After:**
```swift
ConsentButton(
    title: "Change Consent (Didomi)",
    onConsentChanged: { status in
        print("Consent status changed: \(status)")
    }
)
```

### 5. Replace HTML File

**Before:** Your existing `google-test-ad.html` file

**After:** Use the new modular `ad-template.html` with:
- Dynamic configuration from URL parameters
- Enhanced debug mode support
- Better error handling
- Improved size monitoring

### 6. Debug Mode Implementation

**Before:** Hard-coded debug parameters

**After:** Centralized debug control:

```swift
// Enable debug mode globally
AdSDK.shared.setDebugMode(true)

// Enable verbose logging
AdSDK.shared.setVerboseLogging(true)

// Custom debug handler
AdSDK.shared.setConsoleLogHandler { level, message, timestamp in
    print("[\(level)] \(timestamp): \(message)")
}
```

## Key Benefits

### 1. Centralized Configuration
- All settings in one place
- Easy to switch between debug/production
- Consistent behavior across ad units

### 2. Simplified Usage
- No manual URL construction
- Automatic debug parameter injection
- Built-in error handling

### 3. Better Debug Experience
- Toggle debug mode with one setting
- Automatic JavaScript logging
- Enhanced error reporting

### 4. Modular Architecture
- Easy to integrate into new projects
- Clean separation of concerns
- Extensible design

### 5. Documentation
- Complete API documentation
- Usage examples
- Best practices guide

## Debug Mode Features

When debug mode is enabled:

### Swift Side:
- Detailed console logging
- Error reporting
- Performance monitoring
- State tracking

### JavaScript Side:
- `aym_debug=true` query parameter
- Enhanced console logging
- Error forwarding to native
- Debug panel in HTML

### HTML Template:
- Visual debug information
- Real-time status updates
- Size monitoring display
- Error indicators

## Testing Your Migration

1. **Enable Debug Mode**:
   ```swift
   AdSDK.shared.setDebugMode(true)
   ```

2. **Check Console Output**:
   - Look for AdSDK debug messages
   - Verify JavaScript console forwarding
   - Monitor ad loading states

3. **Test Ad Loading**:
   - Verify ads load correctly
   - Check size updates
   - Test error handling

4. **Test Consent**:
   - Verify consent UI appears
   - Test consent changes
   - Check consent status

## Common Migration Issues

### 1. Missing Dependencies
Make sure you have all required dependencies:
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/didomi/swift-sdk", from: "1.0.0"),
    .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "9.0.0")
]
```

### 2. Configuration Issues
Ensure proper initialization:
```swift
// Check if SDK is initialized
if !AdSDK.shared.isSDKInitialized() {
    print("AdSDK not initialized!")
}
```

### 3. Debug Mode Not Working
Verify debug mode is enabled:
```swift
// Check debug status
let debugInfo = AdSDK.shared.getDebugInfo()
print("Debug info: \(debugInfo)")
```

## Production Checklist

Before releasing to production:

- [ ] Disable debug mode: `AdSDK.shared.setDebugMode(false)`
- [ ] Update HTML template URL to production
- [ ] Verify Didomi API key is correct
- [ ] Test consent flow
- [ ] Monitor performance
- [ ] Check error handling

## Next Steps

1. **Update Your Code**: Follow the migration steps above
2. **Test Thoroughly**: Use debug mode to verify everything works
3. **Customize**: Adapt the framework to your specific needs
4. **Deploy**: Switch to production configuration for release

This modular approach will make your ad integration much more maintainable and easier to extend in the future.
