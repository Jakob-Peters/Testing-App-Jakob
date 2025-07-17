import Foundation
import UIKit
import Didomi

/// Main AdSDK class for managing ad configurations and global state
public class AdSDK {
    // MARK: - Singleton
    
    /// Shared instance of AdSDK
    public static let shared = AdSDK()
    
    // MARK: - Properties
    
    /// Current configuration
    public private(set) var configuration: AdConfiguration
    
    /// Initialization state
    private var isInitialized = false
    
    /// Consent change observers
    private var consentChangeObservers: [UUID: (ConsentStatus) -> Void] = [:]
    
    /// Didomi event listener
    private let didomiEventListener = AdSDKEventListener()
    
    // MARK: - Initialization
    
    private init() {
        // Default configuration
        self.configuration = AdConfiguration(
            baseURL: "",
            didomiApiKey: "",
            yieldManagerId: "",
            debugMode: false
        )
    }
    
    // MARK: - Public Methods
    
    /// Initialize the AdSDK with configuration
    /// - Parameter configuration: Ad configuration
    public func initialize(with configuration: AdConfiguration) {
        self.configuration = configuration
        self.isInitialized = true
        
        // Configure debug mode
        AdDebugger.shared.setDebugMode(configuration.debugMode)
        AdDebugger.shared.setVerboseLogging(configuration.verboseLogging)
        AdDebugger.shared.setConsoleLogging(configuration.consoleLoggingEnabled)
        
        // Initialize Didomi
        initializeDidomi()
        
        // Set up consent change listener
        setupConsentChangeListener()
        
        AdDebugger.shared.info("AdSDK initialized with configuration: \(configuration.debugMode ? "DEBUG" : "PRODUCTION")")
    }
    
    /// Convenience initializer with individual parameters
    /// - Parameters:
    ///   - baseURL: Base URL for ad template
    ///   - didomiApiKey: Didomi API key
    ///   - yieldManagerId: Yield Manager ID
    ///   - debugMode: Debug mode enabled
    public func initialize(
        baseURL: String,
        didomiApiKey: String,
        yieldManagerId: String,
        debugMode: Bool = false
    ) {
        let config = AdConfiguration(
            baseURL: baseURL,
            didomiApiKey: didomiApiKey,
            yieldManagerId: yieldManagerId,
            debugMode: debugMode
        )
        
        initialize(with: config)
    }
    
    /// Check if SDK is initialized
    /// - Returns: Whether SDK is initialized
    public func isSDKInitialized() -> Bool {
        return isInitialized
    }
    
    /// Update configuration
    /// - Parameter configuration: New configuration
    public func updateConfiguration(_ configuration: AdConfiguration) {
        self.configuration = configuration
        AdDebugger.shared.info("Configuration updated")
    }
    
    /// Set debug mode
    /// - Parameter enabled: Whether debug mode should be enabled
    public func setDebugMode(_ enabled: Bool) {
        // Create new configuration with updated debug mode
        // (Would need to make AdConfiguration mutable or create a builder)
        
        AdDebugger.shared.setDebugMode(enabled)
        AdDebugger.shared.info("Debug mode \(enabled ? "enabled" : "disabled") globally")
    }
    
    /// Set verbose logging
    /// - Parameter enabled: Whether verbose logging should be enabled
    public func setVerboseLogging(_ enabled: Bool) {
        AdDebugger.shared.setVerboseLogging(enabled)
    }
    
    /// Set console logging
    /// - Parameter enabled: Whether console logging should be enabled
    public func setConsoleLogging(_ enabled: Bool) {
        AdDebugger.shared.setConsoleLogging(enabled)
    }
    
    /// Set custom console log handler
    /// - Parameter handler: Custom log handler
    public func setConsoleLogHandler(_ handler: @escaping (ConsoleLogLevel, String, String) -> Void) {
        AdDebugger.shared.setCustomLogHandler(handler)
    }
    
    /// Get debug information
    /// - Returns: Debug information dictionary
    public func getDebugInfo() -> [String: Any] {
        var info = AdDebugger.shared.getDebugInfo()
        info["sdkInitialized"] = isInitialized
        info["configuration"] = [
            "baseURL": configuration.baseURL,
            "debugMode": configuration.debugMode,
            "consoleLogging": configuration.consoleLoggingEnabled,
            "verboseLogging": configuration.verboseLogging
        ]
        return info
    }
    
    // MARK: - Consent Methods
    
    /// Get current consent status
    /// - Returns: Current consent status
    public func getConsentStatus() -> ConsentStatus {
        guard Didomi.shared.isReady() else {
            return .unknown
        }
        
        // This would need to be implemented based on actual Didomi SDK
        return .unknown
    }
    
    /// Add consent change observer
    /// - Parameter observer: Observer closure
    /// - Returns: Observer ID for removal
    @discardableResult
    public func addConsentChangeObserver(_ observer: @escaping (ConsentStatus) -> Void) -> UUID {
        let id = UUID()
        consentChangeObservers[id] = observer
        return id
    }
    
    /// Remove consent change observer
    /// - Parameter id: Observer ID
    public func removeConsentChangeObserver(_ id: UUID) {
        consentChangeObservers.removeValue(forKey: id)
    }
    
    /// Show consent preferences
    /// - Parameter viewController: View controller to present from
    public func showConsentPreferences(from viewController: UIViewController) {
        if Didomi.shared.isReady() {
            Didomi.shared.showPreferences(controller: viewController)
        } else {
            Didomi.shared.onReady {
                Didomi.shared.showPreferences(controller: viewController)
            }
        }
    }
    
    /// Reset consent
    public func resetConsent() {
        if Didomi.shared.isReady() {
            Didomi.shared.reset()
            AdDebugger.shared.info("Consent reset")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Clear cache
    public func clearCache() {
        // Clear any cached data
        URLCache.shared.removeAllCachedResponses()
        AdDebugger.shared.info("Cache cleared")
    }
    
    /// Get SDK version
    /// - Returns: SDK version string
    public func getVersion() -> String {
        return "1.0.0"
    }
    
    /// Create ad unit configuration
    /// - Parameters:
    ///   - adUnitId: Ad unit ID
    ///   - debugMode: Debug mode override
    /// - Returns: Ad unit configuration
    public func createAdUnitConfiguration(
        adUnitId: String,
        debugMode: Bool? = nil
    ) -> AdUnitConfiguration {
        return AdUnitConfiguration(
            adUnitId: adUnitId,
            debugMode: debugMode
        )
    }
    
    /// Build ad URL
    /// - Parameters:
    ///   - adUnitId: Ad unit ID
    ///   - debugMode: Debug mode override
    /// - Returns: Ad URL
    public func buildAdURL(adUnitId: String, debugMode: Bool? = nil) -> URL? {
        let adUnitConfig = createAdUnitConfiguration(adUnitId: adUnitId, debugMode: debugMode)
        return AdURLBuilder.buildURL(adUnitConfig: adUnitConfig, globalConfig: configuration)
    }
    
    // MARK: - Private Methods
    
    private func initializeDidomi() {
        guard !configuration.didomiApiKey.isEmpty else {
            AdDebugger.shared.warn("Didomi API key not provided")
            return
        }
        
        let params = DidomiInitializeParameters(
            apiKey: configuration.didomiApiKey
        )
        
        Didomi.shared.initialize(params)
        
        Didomi.shared.onReady {
            AdDebugger.shared.info("Didomi SDK ready")
        }
    }
    
    private func setupConsentChangeListener() {
        didomiEventListener.onConsentChanged = { [weak self] status in
            self?.notifyConsentChangeObservers(status)
        }
        
        Didomi.shared.addEventListener(listener: didomiEventListener.didomiListener)
    }
    
    private func notifyConsentChangeObservers(_ status: ConsentStatus) {
        for observer in consentChangeObservers.values {
            observer(status)
        }
    }
}

// MARK: - Event Listener

/// Event listener for Didomi SDK events
private class AdSDKEventListener: NSObject {
    var onConsentChanged: ((ConsentStatus) -> Void)?
    
    // Create an actual EventListener instance that we can configure
    lazy var didomiListener: EventListener = {
        let listener = EventListener()
        listener.onConsentChanged = { [weak self] event in
            self?.handleConsentChanged(event: event)
        }
        return listener
    }()
    
    private func handleConsentChanged(event: EventType) {
        let status: ConsentStatus = .unknown // For now, simplified
        onConsentChanged?(status)
    }
}

// MARK: - Configuration Builder

/// Builder for creating ad configurations
public class AdConfigurationBuilder {
    private var baseURL: String = ""
    private var didomiApiKey: String = ""
    private var yieldManagerId: String = ""
    private var debugMode: Bool = false
    private var customParameters: [String: String] = [:]
    private var consoleLoggingEnabled: Bool = true
    private var verboseLogging: Bool = false
    
    /// Set base URL
    /// - Parameter baseURL: Base URL
    /// - Returns: Self for method chaining
    @discardableResult
    public func setBaseURL(_ baseURL: String) -> AdConfigurationBuilder {
        self.baseURL = baseURL
        return self
    }
    
    /// Set Didomi API key
    /// - Parameter apiKey: Didomi API key
    /// - Returns: Self for method chaining
    @discardableResult
    public func setDidomiApiKey(_ apiKey: String) -> AdConfigurationBuilder {
        self.didomiApiKey = apiKey
        return self
    }
    
    /// Set Yield Manager ID
    /// - Parameter yieldManagerId: Yield Manager ID
    /// - Returns: Self for method chaining
    @discardableResult
    public func setYieldManagerId(_ yieldManagerId: String) -> AdConfigurationBuilder {
        self.yieldManagerId = yieldManagerId
        return self
    }
    
    /// Set debug mode
    /// - Parameter debugMode: Debug mode enabled
    /// - Returns: Self for method chaining
    @discardableResult
    public func setDebugMode(_ debugMode: Bool) -> AdConfigurationBuilder {
        self.debugMode = debugMode
        return self
    }
    
    /// Add custom parameter
    /// - Parameters:
    ///   - key: Parameter key
    ///   - value: Parameter value
    /// - Returns: Self for method chaining
    @discardableResult
    public func addCustomParameter(_ key: String, _ value: String) -> AdConfigurationBuilder {
        customParameters[key] = value
        return self
    }
    
    /// Set console logging
    /// - Parameter enabled: Console logging enabled
    /// - Returns: Self for method chaining
    @discardableResult
    public func setConsoleLogging(_ enabled: Bool) -> AdConfigurationBuilder {
        self.consoleLoggingEnabled = enabled
        return self
    }
    
    /// Set verbose logging
    /// - Parameter enabled: Verbose logging enabled
    /// - Returns: Self for method chaining
    @discardableResult
    public func setVerboseLogging(_ enabled: Bool) -> AdConfigurationBuilder {
        self.verboseLogging = enabled
        return self
    }
    
    /// Build configuration
    /// - Returns: Ad configuration
    public func build() -> AdConfiguration {
        return AdConfiguration(
            baseURL: baseURL,
            didomiApiKey: didomiApiKey,
            yieldManagerId: yieldManagerId,
            debugMode: debugMode,
            customParameters: customParameters,
            consoleLoggingEnabled: consoleLoggingEnabled,
            verboseLogging: verboseLogging
        )
    }
}

// MARK: - Public Extensions

public extension AdSDK {
    /// Create a configuration builder
    /// - Returns: Configuration builder
    static func configurationBuilder() -> AdConfigurationBuilder {
        return AdConfigurationBuilder()
    }
}
