import Foundation

/// Debug manager for controlling debug features across the SDK
public class AdDebugger {
    // MARK: - Singleton
    
    public static let shared = AdDebugger()
    
    // MARK: - Properties
    
    /// Global debug mode state
    private var isDebugEnabled: Bool = false
    
    /// Verbose logging state
    private var isVerboseLoggingEnabled: Bool = false
    
    /// Console logging state
    private var isConsoleLoggingEnabled: Bool = false
    
    /// Custom log handler
    private var customLogHandler: ((ConsoleLogLevel, String, String) -> Void)?
    
    /// Debug session identifier
    private let sessionId: String = UUID().uuidString
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Enable or disable debug mode globally
    /// - Parameter enabled: Whether debug mode should be enabled
    public func setDebugMode(_ enabled: Bool) {
        isDebugEnabled = enabled
        log(.info, "Debug mode \(enabled ? "enabled" : "disabled")")
    }
    
    /// Get current debug mode state
    /// - Returns: Current debug mode state
    public func isDebugMode() -> Bool {
        return isDebugEnabled
    }
    
    /// Enable or disable verbose logging
    /// - Parameter enabled: Whether verbose logging should be enabled
    public func setVerboseLogging(_ enabled: Bool) {
        isVerboseLoggingEnabled = enabled
        log(.info, "Verbose logging \(enabled ? "enabled" : "disabled")")
    }
    
    /// Get current verbose logging state
    /// - Returns: Current verbose logging state
    public func isVerboseLogging() -> Bool {
        return isVerboseLoggingEnabled
    }
    
    /// Enable or disable console logging
    /// - Parameter enabled: Whether console logging should be enabled
    public func setConsoleLogging(_ enabled: Bool) {
        isConsoleLoggingEnabled = enabled
        log(.info, "Console logging \(enabled ? "enabled" : "disabled")")
    }
    
    /// Get current console logging state
    /// - Returns: Current console logging state
    public func isConsoleLogging() -> Bool {
        return isConsoleLoggingEnabled
    }
    
    /// Set custom log handler
    /// - Parameter handler: Custom log handler closure
    public func setCustomLogHandler(_ handler: @escaping (ConsoleLogLevel, String, String) -> Void) {
        customLogHandler = handler
        log(.info, "Custom log handler set")
    }
    
    /// Remove custom log handler
    public func removeCustomLogHandler() {
        customLogHandler = nil
        log(.info, "Custom log handler removed")
    }
    
    /// Log a message with level
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Message to log
    ///   - file: Source file (default: current file)
    ///   - function: Source function (default: current function)
    ///   - line: Source line (default: current line)
    public func log(
        _ level: ConsoleLogLevel,
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let formattedMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        // Always log errors and warnings
        let shouldLog = level == .error || level == .warn || 
                       isDebugEnabled || 
                       (isVerboseLoggingEnabled && level == .debug)
        
        if shouldLog {
            if let customHandler = customLogHandler {
                customHandler(level, formattedMessage, timestamp)
            } else {
                print("\(level.emoji) [AdSDK] \(formattedMessage)")
            }
        }
    }
    
    /// Get debug query parameters for URL
    /// - Returns: Dictionary of debug query parameters
    public func getDebugQueryParameters() -> [String: String] {
        var params: [String: String] = [:]
        
        if isDebugEnabled {
            params["aym_debug"] = "true"
            params["debug_session"] = sessionId
        }
        
        if isVerboseLoggingEnabled {
            params["verbose"] = "true"
        }
        
        return params
    }
    
    /// Get debug JavaScript code to inject
    /// - Returns: JavaScript code string
    public func getDebugJavaScriptCode() -> String {
        guard isDebugEnabled else { return "" }
        
        return """
        // AdSDK Debug Mode Enabled
        window.adSDKDebug = {
            sessionId: '\(sessionId)',
            verboseLogging: \(isVerboseLoggingEnabled),
            consoleLogging: \(isConsoleLoggingEnabled),
            timestamp: '\(ISO8601DateFormatter().string(from: Date()))'
        };
        
        // Enhanced console logging for debug mode
        if (window.adSDKDebug.verboseLogging) {
            console.log('🔍 AdSDK Debug Mode Active - Session:', window.adSDKDebug.sessionId);
        }
        """
    }
    
    /// Clear debug state
    public func clearDebugState() {
        log(.info, "Clearing debug state")
        // Reset to default states but keep user preferences
    }
    
    /// Get debug information summary
    /// - Returns: Debug information dictionary
    public func getDebugInfo() -> [String: Any] {
        return [
            "debugMode": isDebugEnabled,
            "verboseLogging": isVerboseLoggingEnabled,
            "consoleLogging": isConsoleLoggingEnabled,
            "sessionId": sessionId,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "hasCustomLogHandler": customLogHandler != nil
        ]
    }
}

/// Extension for convenience logging methods
extension AdDebugger {
    /// Log debug message
    /// - Parameters:
    ///   - message: Message to log
    ///   - file: Source file
    ///   - function: Source function
    ///   - line: Source line
    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    /// Log info message
    /// - Parameters:
    ///   - message: Message to log
    ///   - file: Source file
    ///   - function: Source function
    ///   - line: Source line
    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    /// Log warning message
    /// - Parameters:
    ///   - message: Message to log
    ///   - file: Source file
    ///   - function: Source function
    ///   - line: Source line
    public func warn(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warn, message, file: file, function: function, line: line)
    }
    
    /// Log error message
    /// - Parameters:
    ///   - message: Message to log
    ///   - file: Source file
    ///   - function: Source function
    ///   - line: Source line
    public func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message, file: file, function: function, line: line)
    }
}
