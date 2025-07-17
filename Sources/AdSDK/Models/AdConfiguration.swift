import Foundation
import CoreGraphics

/// Configuration model for ad units and SDK settings
public struct AdConfiguration {
    // MARK: - Properties
    
    /// Base URL for the ad HTML template
    public let baseURL: String
    
    /// Didomi API key for consent management
    public let didomiApiKey: String
    
    /// Yield Manager ID for ad serving
    public let yieldManagerId: String
    
    /// Global debug mode setting
    public let debugMode: Bool
    
    /// Custom parameters to append to ad URLs
    public let customParameters: [String: String]
    
    /// Console logging enabled
    public let consoleLoggingEnabled: Bool
    
    /// Verbose logging for development
    public let verboseLogging: Bool
    
    // MARK: - Initialization
    
    /// Initialize ad configuration
    /// - Parameters:
    ///   - baseURL: Base URL for the ad HTML template
    ///   - didomiApiKey: Didomi API key for consent management
    ///   - yieldManagerId: Yield Manager ID for ad serving
    ///   - debugMode: Enable debug mode (default: false)
    ///   - customParameters: Custom parameters for ad URLs (default: empty)
    ///   - consoleLoggingEnabled: Enable console logging (default: true)
    ///   - verboseLogging: Enable verbose logging (default: false)
    public init(
        baseURL: String,
        didomiApiKey: String,
        yieldManagerId: String,
        debugMode: Bool = false,
        customParameters: [String: String] = [:],
        consoleLoggingEnabled: Bool = true,
        verboseLogging: Bool = false
    ) {
        self.baseURL = baseURL
        self.didomiApiKey = didomiApiKey
        self.yieldManagerId = yieldManagerId
        self.debugMode = debugMode
        self.customParameters = customParameters
        self.consoleLoggingEnabled = consoleLoggingEnabled
        self.verboseLogging = verboseLogging
    }
    
    // MARK: - Factory Methods
    
    /// Create a development configuration with debug mode enabled
    /// - Parameters:
    ///   - baseURL: Base URL for the ad HTML template
    ///   - didomiApiKey: Didomi API key
    ///   - yieldManagerId: Yield Manager ID
    /// - Returns: Development configuration
    public static func development(
        baseURL: String,
        didomiApiKey: String,
        yieldManagerId: String
    ) -> AdConfiguration {
        return AdConfiguration(
            baseURL: baseURL,
            didomiApiKey: didomiApiKey,
            yieldManagerId: yieldManagerId,
            debugMode: true,
            consoleLoggingEnabled: true,
            verboseLogging: true
        )
    }
    
    /// Create a production configuration with debug mode disabled
    /// - Parameters:
    ///   - baseURL: Base URL for the ad HTML template
    ///   - didomiApiKey: Didomi API key
    ///   - yieldManagerId: Yield Manager ID
    /// - Returns: Production configuration
    public static func production(
        baseURL: String,
        didomiApiKey: String,
        yieldManagerId: String
    ) -> AdConfiguration {
        return AdConfiguration(
            baseURL: baseURL,
            didomiApiKey: didomiApiKey,
            yieldManagerId: yieldManagerId,
            debugMode: false,
            consoleLoggingEnabled: false,
            verboseLogging: false
        )
    }
}

/// Ad unit configuration for individual ad instances
public struct AdUnitConfiguration {
    // MARK: - Properties
    
    /// Unique identifier for the ad unit
    public let adUnitId: String
    
    /// Override debug mode for this specific ad unit
    public let debugMode: Bool?
    
    /// Custom parameters specific to this ad unit
    public let customParameters: [String: String]
    
    /// Expected initial size for the ad
    public let initialSize: CGSize
    
    /// Minimum size constraint for the ad
    public let minimumSize: CGSize
    
    /// Maximum size constraint for the ad
    public let maximumSize: CGSize
    
    // MARK: - Initialization
    
    /// Initialize ad unit configuration
    /// - Parameters:
    ///   - adUnitId: Unique identifier for the ad unit
    ///   - debugMode: Override debug mode (default: nil, uses global setting)
    ///   - customParameters: Custom parameters for this ad unit (default: empty)
    ///   - initialSize: Expected initial size (default: 320x250)
    ///   - minimumSize: Minimum size constraint (default: 1x1)
    ///   - maximumSize: Maximum size constraint (default: screen size)
    public init(
        adUnitId: String,
        debugMode: Bool? = nil,
        customParameters: [String: String] = [:],
        initialSize: CGSize = CGSize(width: 320, height: 250),
        minimumSize: CGSize = CGSize(width: 1, height: 1),
        maximumSize: CGSize = CGSize(width: 1000, height: 1000)
    ) {
        self.adUnitId = adUnitId
        self.debugMode = debugMode
        self.customParameters = customParameters
        self.initialSize = initialSize
        self.minimumSize = minimumSize
        self.maximumSize = maximumSize
    }
}

/// Consent status from Didomi
public enum ConsentStatus {
    case unknown
    case granted
    case denied
    case notRequired
    
    /// Initialize from Didomi consent status
    /// - Parameter didomiStatus: Didomi consent status
    public init(from didomiStatus: Any) {
        // This would be implemented based on actual Didomi SDK types
        self = .unknown
    }
}

/// Ad loading state
public enum AdLoadingState {
    case idle
    case loading
    case loaded
    case failed(Error)
    case sizeUpdated(CGSize)
}

/// Console log level for JavaScript messages
public enum ConsoleLogLevel: String, CaseIterable {
    case log = "log"
    case info = "info"
    case warn = "warn"
    case error = "error"
    case debug = "debug"
    
    /// Emoji representation for console output
    public var emoji: String {
        switch self {
        case .log: return "📝"
        case .info: return "ℹ️"
        case .warn: return "⚠️"
        case .error: return "❌"
        case .debug: return "🔍"
        }
    }
}
