import UIKit
import WebKit
import Didomi

/// Main ad web view controller that handles web-based ad loading and display
public class AdWebViewController: UIViewController {
    // MARK: - Properties
    
    /// The web view for displaying ads
    public private(set) var webView: WKWebView!
    
    /// Ad unit configuration
    private let adUnitConfig: AdUnitConfiguration
    
    /// Global configuration
    private let globalConfig: AdConfiguration
    
    /// Size change callback
    private var onSizeChanged: ((CGSize) -> Void)?
    
    /// Initial URL loaded in the web view
    private var initialURL: URL?
    
    /// Current loading state
    private var loadingState: AdLoadingState = .idle
    
    /// Console log handler
    private let consoleLogHandler = ConsoleLogHandler.shared
    
    /// Size observer for ad content
    private var sizeObserver: NSKeyValueObservation?
    
    // MARK: - Initialization
    
    /// Initialize with configurations
    /// - Parameters:
    ///   - adUnitConfig: Ad unit configuration
    ///   - globalConfig: Global configuration
    ///   - onSizeChanged: Size change callback
    public init(
        adUnitConfig: AdUnitConfiguration,
        globalConfig: AdConfiguration,
        onSizeChanged: @escaping (CGSize) -> Void
    ) {
        self.adUnitConfig = adUnitConfig
        self.globalConfig = globalConfig
        self.onSizeChanged = onSizeChanged
        super.init(nibName: nil, bundle: nil)
    }
    
    /// Convenience initializer with URL
    /// - Parameters:
    ///   - adUrl: Ad URL
    ///   - onSizeChanged: Size change callback
    public convenience init(
        adUrl: URL?,
        onSizeChanged: @escaping (CGSize) -> Void
    ) {
        // Create default configurations
        let adUnitConfig = AdUnitConfiguration(adUnitId: "default")
        let globalConfig = AdConfiguration(
            baseURL: adUrl?.absoluteString ?? "",
            didomiApiKey: "",
            yieldManagerId: ""
        )
        
        self.init(
            adUnitConfig: adUnitConfig,
            globalConfig: globalConfig,
            onSizeChanged: onSizeChanged
        )
        
        self.initialURL = adUrl
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupConsoleLogging()
        loadAdContent()
    }
    
    deinit {
        AdDebugger.shared.debug("AdWebViewController deinit - cleaning up")
        sizeObserver?.invalidate()
        webView?.stopLoading()
        webView?.removeFromSuperview()
    }
    
    // MARK: - Setup Methods
    
    private func setupWebView() {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webViewConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Configure user content controller
        let userContentController = WKUserContentController()
        
        // Add size handler
        userContentController.add(SizeMessageHandler { [weak self] size in
            self?.handleSizeChange(size)
        }, name: "sizeHandler")
        
        // Configure console logging
        let isDebugMode = adUnitConfig.debugMode ?? globalConfig.debugMode
        consoleLogHandler.configureUserContentController(userContentController, debugMode: isDebugMode)
        
        webViewConfiguration.userContentController = userContentController
        
        // Create web view
        webView = WKWebView(frame: view.bounds, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.isInspectable = true
        
        view.addSubview(webView)
        
        AdDebugger.shared.debug("WebView configured and added to view")
    }
    
    private func setupConsoleLogging() {
        // Set up custom console log handler if needed
        if globalConfig.consoleLoggingEnabled {
            consoleLogHandler.setDefaultHandler { level, message, timestamp in
                AdDebugger.shared.log(level, "WebView: \(message)")
            }
        }
    }
    
    private func loadAdContent() {
        // Wait for Didomi to be ready before loading
        if Didomi.shared.isReady() {
            performAdLoad()
        } else {
            Didomi.shared.onReady { [weak self] in
                // Ensure UI operations are performed on the main thread
                DispatchQueue.main.async {
                    self?.performAdLoad()
                }
            }
        }
    }
    
    private func performAdLoad() {
        guard let url = getAdURL() else {
            AdDebugger.shared.error("Failed to construct ad URL")
            updateLoadingState(.failed(AdError.invalidURL))
            return
        }
        
        initialURL = url
        updateLoadingState(.loading)
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        AdDebugger.shared.info("Loading ad: \(url.absoluteString)")
    }
    
    private func getAdURL() -> URL? {
        if let initialURL = initialURL {
            return initialURL
        }
        
        return AdURLBuilder.buildURL(
            adUnitConfig: adUnitConfig,
            globalConfig: globalConfig
        )
    }
    
    // MARK: - Size Handling
    
    private func handleSizeChange(_ size: CGSize) {
        let constrainedSize = constrainSize(size)
        
        AdDebugger.shared.debug("Ad size changed to: \(constrainedSize)")
        
        DispatchQueue.main.async { [weak self] in
            self?.onSizeChanged?(constrainedSize)
            self?.updateLoadingState(.sizeUpdated(constrainedSize))
        }
    }
    
    private func constrainSize(_ size: CGSize) -> CGSize {
        let minSize = adUnitConfig.minimumSize
        let maxSize = adUnitConfig.maximumSize
        
        let constrainedWidth = max(minSize.width, min(size.width, maxSize.width))
        let constrainedHeight = max(minSize.height, min(size.height, maxSize.height))
        
        return CGSize(width: constrainedWidth, height: constrainedHeight)
    }
    
    // MARK: - State Management
    
    private func updateLoadingState(_ state: AdLoadingState) {
        loadingState = state
        
        switch state {
        case .idle:
            AdDebugger.shared.debug("Ad state: idle")
        case .loading:
            AdDebugger.shared.debug("Ad state: loading")
        case .loaded:
            AdDebugger.shared.debug("Ad state: loaded")
        case .failed(let error):
            AdDebugger.shared.error("Ad state: failed - \(error.localizedDescription)")
        case .sizeUpdated(let size):
            AdDebugger.shared.debug("Ad state: size updated to \(size)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Get current loading state
    public func getLoadingState() -> AdLoadingState {
        return loadingState
    }
    
    /// Reload the ad
    public func reloadAd() {
        AdDebugger.shared.info("Reloading ad")
        
        // Ensure UI operations are performed on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.loadAdContent()
        }
    }
    
    /// Stop loading the ad
    public func stopLoading() {
        AdDebugger.shared.info("Stopping ad loading")
        
        // Ensure UI operations are performed on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.webView.stopLoading()
            self?.updateLoadingState(.idle)
        }
    }
}

// MARK: - WKNavigationDelegate

extension AdWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        AdDebugger.shared.debug("WebView finished loading: \(webView.url?.absoluteString ?? "N/A")")
        
        // Inject Didomi consent
        injectDidomiConsent()
        
        // Inject debug code if needed
        injectDebugCode()
        
        updateLoadingState(.loaded)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        AdDebugger.shared.error("WebView failed to load: \(error.localizedDescription)")
        updateLoadingState(.failed(error))
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let shouldHandleExternally = ExternalURLHandler.shouldHandleExternally(
            navigationAction: navigationAction,
            initialURL: initialURL
        )
        
        if shouldHandleExternally {
            ExternalURLHandler.handleExternalURL(navigationAction.request.url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    private func injectDidomiConsent() {
        let didomiJavaScriptCode = Didomi.shared.getJavaScriptForWebView()
        webView.evaluateJavaScript(didomiJavaScriptCode) { result, error in
            if let error = error {
                AdDebugger.shared.error("Failed to inject Didomi consent: \(error.localizedDescription)")
            } else {
                AdDebugger.shared.debug("Didomi consent injected successfully")
            }
        }
    }
    
    private func injectDebugCode() {
        let isDebugMode = adUnitConfig.debugMode ?? globalConfig.debugMode
        if isDebugMode {
            let debugCode = AdDebugger.shared.getDebugJavaScriptCode()
            webView.evaluateJavaScript(debugCode) { result, error in
                if let error = error {
                    AdDebugger.shared.error("Failed to inject debug code: \(error.localizedDescription)")
                } else {
                    AdDebugger.shared.debug("Debug code injected successfully")
                }
            }
        }
    }
}

// MARK: - WKUIDelegate

extension AdWebViewController: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle popup windows by opening externally
        if let url = navigationAction.request.url {
            ExternalURLHandler.handleExternalURL(url)
        }
        return nil
    }
}

// MARK: - Message Handlers

/// Message handler for size updates
private class SizeMessageHandler: NSObject, WKScriptMessageHandler {
    private let onSizeChanged: (CGSize) -> Void
    
    init(onSizeChanged: @escaping (CGSize) -> Void) {
        self.onSizeChanged = onSizeChanged
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "sizeHandler",
              let sizeData = message.body as? [String: Any],
              let width = sizeData["width"] as? Double,
              let height = sizeData["height"] as? Double else {
            AdDebugger.shared.warn("Invalid size data received: \(message.body)")
            return
        }
        
        let size = CGSize(width: width, height: height)
        onSizeChanged(size)
    }
}

// MARK: - External URL Handler

/// Helper class for handling external URLs
private class ExternalURLHandler {
    /// Determine if URL should be handled externally
    /// - Parameters:
    ///   - navigationAction: Navigation action
    ///   - initialURL: Initial URL loaded in web view
    /// - Returns: Whether URL should be handled externally
    static func shouldHandleExternally(navigationAction: WKNavigationAction, initialURL: URL?) -> Bool {
        guard let targetURL = navigationAction.request.url else { return false }
        
        // Always handle non-HTTP/HTTPS schemes externally
        if let scheme = targetURL.scheme, !["http", "https"].contains(scheme.lowercased()) {
            return true
        }
        
        // Handle popup windows externally
        if navigationAction.targetFrame == nil {
            return true
        }
        
        // Handle different domain navigation externally
        if let initialURL = initialURL,
           let initialDomain = initialURL.host,
           let targetDomain = targetURL.host,
           initialDomain != targetDomain,
           navigationAction.targetFrame?.isMainFrame == true {
            return true
        }
        
        return false
    }
    
    /// Handle external URL opening
    /// - Parameter url: URL to open
    static func handleExternalURL(_ url: URL?) {
        guard let url = url else { return }
        
        AdDebugger.shared.info("Opening external URL: \(url.absoluteString)")
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    AdDebugger.shared.debug("Successfully opened external URL")
                } else {
                    AdDebugger.shared.error("Failed to open external URL")
                }
            }
        }
    }
}

// MARK: - Error Types

/// Ad-specific error types
public enum AdError: Error, LocalizedError {
    case invalidURL
    case loadingFailed
    case consentNotGranted
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid ad URL"
        case .loadingFailed:
            return "Ad failed to load"
        case .consentNotGranted:
            return "User consent not granted"
        case .networkError:
            return "Network error occurred"
        }
    }
}
