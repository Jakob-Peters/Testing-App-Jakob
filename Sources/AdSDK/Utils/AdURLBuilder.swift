import Foundation

/// Builder class for constructing ad URLs with various parameters
public class AdURLBuilder {
    // MARK: - Properties
    
    private var baseURL: String
    private var adUnitId: String?
    private var debugMode: Bool?
    private var customParameters: [String: String] = [:]
    private var configuration: AdConfiguration?
    
    // MARK: - Initialization
    
    /// Initialize with base URL
    /// - Parameter baseURL: Base URL for ad template
    public init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    /// Initialize with configuration
    /// - Parameter configuration: Ad configuration
    public init(configuration: AdConfiguration) {
        self.baseURL = configuration.baseURL
        self.configuration = configuration
        self.customParameters = configuration.customParameters
    }
    
    // MARK: - Builder Methods
    
    /// Set ad unit ID
    /// - Parameter adUnitId: Ad unit identifier
    /// - Returns: Self for method chaining
    @discardableResult
    public func setAdUnitId(_ adUnitId: String) -> AdURLBuilder {
        self.adUnitId = adUnitId
        return self
    }
    
    /// Set debug mode
    /// - Parameter debugMode: Whether debug mode should be enabled
    /// - Returns: Self for method chaining
    @discardableResult
    public func setDebugMode(_ debugMode: Bool) -> AdURLBuilder {
        self.debugMode = debugMode
        return self
    }
    
    /// Add custom parameter
    /// - Parameters:
    ///   - key: Parameter key
    ///   - value: Parameter value
    /// - Returns: Self for method chaining
    @discardableResult
    public func addCustomParameter(_ key: String, _ value: String) -> AdURLBuilder {
        customParameters[key] = value
        return self
    }
    
    /// Add multiple custom parameters
    /// - Parameter parameters: Dictionary of parameters
    /// - Returns: Self for method chaining
    @discardableResult
    public func addCustomParameters(_ parameters: [String: String]) -> AdURLBuilder {
        customParameters.merge(parameters) { _, new in new }
        return self
    }
    
    /// Set placement parameter
    /// - Parameter placement: Placement identifier
    /// - Returns: Self for method chaining
    @discardableResult
    public func setPlacement(_ placement: String) -> AdURLBuilder {
        return addCustomParameter("placement", placement)
    }
    
    /// Set targeting parameters
    /// - Parameter targeting: Targeting parameters
    /// - Returns: Self for method chaining
    @discardableResult
    public func setTargeting(_ targeting: [String: String]) -> AdURLBuilder {
        for (key, value) in targeting {
            addCustomParameter("targeting_\(key)", value)
        }
        return self
    }
    
    /// Set ad size parameters
    /// - Parameters:
    ///   - width: Ad width
    ///   - height: Ad height
    /// - Returns: Self for method chaining
    @discardableResult
    public func setAdSize(width: Int, height: Int) -> AdURLBuilder {
        addCustomParameter("width", String(width))
        addCustomParameter("height", String(height))
        return self
    }
    
    /// Set ad size from CGSize
    /// - Parameter size: Ad size
    /// - Returns: Self for method chaining
    @discardableResult
    public func setAdSize(_ size: CGSize) -> AdURLBuilder {
        return setAdSize(width: Int(size.width), height: Int(size.height))
    }
    
    // MARK: - Build Method
    
    /// Build the final URL
    /// - Returns: Constructed URL, or nil if invalid
    public func build() -> URL? {
        guard var components = URLComponents(string: baseURL) else {
            AdDebugger.shared.error("Invalid base URL: \(baseURL)")
            return nil
        }
        
        var queryItems: [URLQueryItem] = []
        
        // Add ad unit ID if provided
        if let adUnitId = adUnitId {
            queryItems.append(URLQueryItem(name: "adUnitId", value: adUnitId))
        }
        
        // Add debug parameters
        let shouldEnableDebug = debugMode ?? configuration?.debugMode ?? AdDebugger.shared.isDebugMode()
        if shouldEnableDebug {
            let debugParams = AdDebugger.shared.getDebugQueryParameters()
            for (key, value) in debugParams {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        
        // Add custom parameters
        for (key, value) in customParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        // Add configuration parameters if available
        if let config = configuration {
            queryItems.append(URLQueryItem(name: "yield_manager", value: config.yieldManagerId))
        }
        
        // Set query items
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            AdDebugger.shared.error("Failed to construct URL from components")
            return nil
        }
        
        AdDebugger.shared.debug("Built ad URL: \(url.absoluteString)")
        return url
    }
    
    // MARK: - Convenience Methods
    
    /// Build URL with ad unit configuration
    /// - Parameters:
    ///   - adUnitConfig: Ad unit configuration
    ///   - globalConfig: Global configuration
    /// - Returns: Constructed URL
    public static func buildURL(
        adUnitConfig: AdUnitConfiguration,
        globalConfig: AdConfiguration
    ) -> URL? {
        return AdURLBuilder(configuration: globalConfig)
            .setAdUnitId(adUnitConfig.adUnitId)
            .setDebugMode(adUnitConfig.debugMode ?? globalConfig.debugMode)
            .addCustomParameters(adUnitConfig.customParameters)
            .setAdSize(adUnitConfig.initialSize)
            .build()
    }
    
    /// Build URL for testing purposes
    /// - Parameters:
    ///   - baseURL: Base URL
    ///   - adUnitId: Ad unit ID
    /// - Returns: Test URL with debug enabled
    public static func buildTestURL(baseURL: String, adUnitId: String) -> URL? {
        return AdURLBuilder(baseURL: baseURL)
            .setAdUnitId(adUnitId)
            .setDebugMode(true)
            .addCustomParameter("test", "true")
            .build()
    }
}

/// Extension for URL validation and manipulation
extension AdURLBuilder {
    /// Validate base URL
    /// - Parameter url: URL to validate
    /// - Returns: Whether URL is valid
    public static func isValidBaseURL(_ url: String) -> Bool {
        guard let url = URL(string: url),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return false
        }
        return true
    }
    
    /// Extract query parameters from URL
    /// - Parameter url: URL to extract parameters from
    /// - Returns: Dictionary of query parameters
    public static func extractQueryParameters(from url: URL) -> [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        
        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value
        }
        
        return parameters
    }
}
