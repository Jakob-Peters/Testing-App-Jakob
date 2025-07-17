import SwiftUI
import UIKit

/// SwiftUI wrapper for AdWebViewController
public struct AdWebView: UIViewControllerRepresentable {
    // MARK: - Properties
    
    /// Ad unit configuration
    private let adUnitConfig: AdUnitConfiguration
    
    /// Global configuration
    private let globalConfig: AdConfiguration
    
    /// Binding for ad size updates
    @Binding private var adSize: CGSize
    
    /// Optional callback for additional size handling
    private let onSizeChanged: ((CGSize) -> Void)?
    
    /// Optional callback for loading state changes
    private let onStateChanged: ((AdLoadingState) -> Void)?
    
    // MARK: - Initialization
    
    /// Initialize with configurations
    /// - Parameters:
    ///   - adUnitConfig: Ad unit configuration
    ///   - globalConfig: Global configuration
    ///   - adSize: Binding for ad size
    ///   - onSizeChanged: Optional size change callback
    ///   - onStateChanged: Optional state change callback
    public init(
        adUnitConfig: AdUnitConfiguration,
        globalConfig: AdConfiguration,
        adSize: Binding<CGSize>,
        onSizeChanged: ((CGSize) -> Void)? = nil,
        onStateChanged: ((AdLoadingState) -> Void)? = nil
    ) {
        self.adUnitConfig = adUnitConfig
        self.globalConfig = globalConfig
        self._adSize = adSize
        self.onSizeChanged = onSizeChanged
        self.onStateChanged = onStateChanged
    }
    
    /// Convenience initializer with ad unit ID
    /// - Parameters:
    ///   - adUnitId: Ad unit identifier
    ///   - adSize: Binding for ad size
    ///   - debugMode: Debug mode override
    ///   - onSizeChanged: Optional size change callback
    ///   - onStateChanged: Optional state change callback
    public init(
        adUnitId: String,
        adSize: Binding<CGSize>,
        debugMode: Bool? = nil,
        onSizeChanged: ((CGSize) -> Void)? = nil,
        onStateChanged: ((AdLoadingState) -> Void)? = nil
    ) {
        self.adUnitConfig = AdUnitConfiguration(
            adUnitId: adUnitId,
            debugMode: debugMode
        )
        self.globalConfig = AdSDK.shared.configuration
        self._adSize = adSize
        self.onSizeChanged = onSizeChanged
        self.onStateChanged = onStateChanged
    }
    
    /// Legacy initializer for backward compatibility
    /// - Parameters:
    ///   - adUrl: Ad URL
    ///   - adSize: Binding for ad size
    public init(
        adUrl: URL?,
        adSize: Binding<CGSize>
    ) {
        self.adUnitConfig = AdUnitConfiguration(adUnitId: "legacy")
        self.globalConfig = AdConfiguration(
            baseURL: adUrl?.absoluteString ?? "",
            didomiApiKey: "",
            yieldManagerId: ""
        )
        self._adSize = adSize
        self.onSizeChanged = nil
        self.onStateChanged = nil
    }
    
    // MARK: - UIViewControllerRepresentable
    
    public func makeUIViewController(context: Context) -> AdWebViewController {
        let controller = AdWebViewController(
            adUnitConfig: adUnitConfig,
            globalConfig: globalConfig
        ) { size in
            // Update binding
            DispatchQueue.main.async {
                self.adSize = size
            }
            
            // Call additional callback
            self.onSizeChanged?(size)
        }
        
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: AdWebViewController, context: Context) {
        // Handle any updates if needed
        if let stateCallback = onStateChanged {
            stateCallback(uiViewController.getLoadingState())
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public static func dismantleUIViewController(_ uiViewController: AdWebViewController, coordinator: Coordinator) {
        AdDebugger.shared.debug("AdWebView being dismantled")
        uiViewController.stopLoading()
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: NSObject {
        var parent: AdWebView
        
        init(parent: AdWebView) {
            self.parent = parent
        }
    }
}

// MARK: - View Modifiers

extension AdWebView {
    /// Set custom parameters for the ad
    /// - Parameter parameters: Custom parameters
    /// - Returns: Modified view
    public func customParameters(_ parameters: [String: String]) -> AdWebView {
        // Would need to modify AdUnitConfiguration to be mutable or create a new one
        return self
    }
    
    /// Set placement parameter
    /// - Parameter placement: Placement identifier
    /// - Returns: Modified view
    public func placement(_ placement: String) -> AdWebView {
        return customParameters(["placement": placement])
    }
    
    /// Set targeting parameters
    /// - Parameter targeting: Targeting parameters
    /// - Returns: Modified view
    public func targeting(_ targeting: [String: String]) -> AdWebView {
        var params: [String: String] = [:]
        for (key, value) in targeting {
            params["targeting_\(key)"] = value
        }
        return customParameters(params)
    }
}

// MARK: - Preview Support

#if DEBUG
struct AdWebView_Previews: PreviewProvider {
    @State static var adSize = CGSize(width: 320, height: 250)
    
    static var previews: some View {
        VStack {
            AdWebView(
                adUnitId: "div-gpt-ad-mobile_1",
                adSize: $adSize,
                debugMode: true
            )
            .frame(width: adSize.width, height: adSize.height)
            .border(Color.gray)
            
            Text("Ad Size: \(Int(adSize.width)) x \(Int(adSize.height))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
#endif

// MARK: - Convenience Views

/// A simple ad banner view with predefined size
public struct AdBannerView: View {
    @State private var adSize = CGSize(width: 320, height: 50)
    private let adUnitId: String
    private let debugMode: Bool
    
    public init(adUnitId: String, debugMode: Bool = false) {
        self.adUnitId = adUnitId
        self.debugMode = debugMode
    }
    
    public var body: some View {
        AdWebView(
            adUnitId: adUnitId,
            adSize: $adSize,
            debugMode: debugMode
        )
        .frame(width: adSize.width, height: max(adSize.height, 50))
        .clipped()
    }
}

/// A medium rectangle ad view
public struct AdMediumRectangleView: View {
    @State private var adSize = CGSize(width: 300, height: 250)
    private let adUnitId: String
    private let debugMode: Bool
    
    public init(adUnitId: String, debugMode: Bool = false) {
        self.adUnitId = adUnitId
        self.debugMode = debugMode
    }
    
    public var body: some View {
        AdWebView(
            adUnitId: adUnitId,
            adSize: $adSize,
            debugMode: debugMode
        )
        .frame(width: adSize.width, height: max(adSize.height, 250))
        .clipped()
    }
}

/// A responsive ad view that adapts to container size
public struct AdResponsiveView: View {
    @State private var adSize = CGSize(width: 320, height: 250)
    private let adUnitId: String
    private let debugMode: Bool
    private let maxWidth: CGFloat
    
    public init(adUnitId: String, maxWidth: CGFloat = 400, debugMode: Bool = false) {
        self.adUnitId = adUnitId
        self.maxWidth = maxWidth
        self.debugMode = debugMode
    }
    
    public var body: some View {
        AdWebView(
            adUnitId: adUnitId,
            adSize: $adSize,
            debugMode: debugMode
        )
        .frame(width: min(adSize.width, maxWidth), height: adSize.height)
        .clipped()
    }
}
