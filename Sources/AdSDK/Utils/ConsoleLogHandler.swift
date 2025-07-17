import Foundation
import WebKit

/// Handler for JavaScript console messages and logging
public class ConsoleLogHandler {
    // MARK: - Properties
    
    /// Shared instance
    public static let shared = ConsoleLogHandler()
    
    /// Message handlers by level
    private var messageHandlers: [ConsoleLogLevel: [(String, String) -> Void]] = [:]
    
    /// Default message handler
    private var defaultHandler: ((ConsoleLogLevel, String, String) -> Void)?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Set default message handler
    /// - Parameter handler: Handler closure
    public func setDefaultHandler(_ handler: @escaping (ConsoleLogLevel, String, String) -> Void) {
        defaultHandler = handler
    }
    
    /// Add message handler for specific level
    /// - Parameters:
    ///   - level: Log level
    ///   - handler: Handler closure
    public func addHandler(for level: ConsoleLogLevel, handler: @escaping (String, String) -> Void) {
        if messageHandlers[level] == nil {
            messageHandlers[level] = []
        }
        messageHandlers[level]?.append(handler)
    }
    
    /// Remove all handlers for specific level
    /// - Parameter level: Log level
    public func removeHandlers(for level: ConsoleLogLevel) {
        messageHandlers[level] = nil
    }
    
    /// Remove all handlers
    public func removeAllHandlers() {
        messageHandlers.removeAll()
        defaultHandler = nil
    }
    
    /// Handle console message from JavaScript
    /// - Parameter message: WKScriptMessage from JavaScript
    public func handleConsoleMessage(_ message: WKScriptMessage) {
        guard message.name == "consoleLog" else { return }
        
        let level: ConsoleLogLevel
        let logMessage: String
        let timestamp: String
        
        if let logData = message.body as? [String: Any] {
            level = ConsoleLogLevel(rawValue: logData["level"] as? String ?? "log") ?? .log
            logMessage = logData["message"] as? String ?? "Unknown message"
            timestamp = logData["timestamp"] as? String ?? ISO8601DateFormatter().string(from: Date())
        } else {
            level = .log
            logMessage = String(describing: message.body)
            timestamp = ISO8601DateFormatter().string(from: Date())
        }
        
        // Call specific handlers
        if let handlers = messageHandlers[level] {
            for handler in handlers {
                handler(logMessage, timestamp)
            }
        }
        
        // Call default handler
        if let defaultHandler = defaultHandler {
            defaultHandler(level, logMessage, timestamp)
        } else {
            // Built-in default handling
            handleDefaultConsoleMessage(level: level, message: logMessage, timestamp: timestamp)
        }
    }
    
    /// Generate JavaScript code for console logging
    /// - Parameter debugMode: Whether debug mode is enabled
    /// - Returns: JavaScript code string
    public func generateConsoleLoggingJavaScript(debugMode: Bool) -> String {
        let debugCondition = debugMode ? "true" : "false"
        
        return """
        // AdSDK Console Logging Bridge
        (function() {
            const isDebugMode = \(debugCondition);
            const originalLog = console.log;
            const originalError = console.error;
            const originalWarn = console.warn;
            const originalInfo = console.info;
            const originalDebug = console.debug;
            
            function sendToNative(level, args) {
                if (!isDebugMode && level === 'debug') {
                    return; // Skip debug logs in production
                }
                
                const message = Array.from(args).map(arg => {
                    if (typeof arg === 'object') {
                        try {
                            return JSON.stringify(arg, null, 2);
                        } catch (e) {
                            return String(arg);
                        }
                    }
                    return String(arg);
                }).join(' ');
                
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.consoleLog) {
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        level: level,
                        message: message,
                        timestamp: new Date().toISOString(),
                        url: window.location.href,
                        userAgent: navigator.userAgent
                    });
                }
            }
            
            // Override console methods
            console.log = function(...args) {
                originalLog.apply(console, args);
                sendToNative('log', args);
            };
            
            console.error = function(...args) {
                originalError.apply(console, args);
                sendToNative('error', args);
            };
            
            console.warn = function(...args) {
                originalWarn.apply(console, args);
                sendToNative('warn', args);
            };
            
            console.info = function(...args) {
                originalInfo.apply(console, args);
                sendToNative('info', args);
            };
            
            console.debug = function(...args) {
                originalDebug.apply(console, args);
                sendToNative('debug', args);
            };
            
            // Capture uncaught errors
            window.addEventListener('error', function(e) {
                sendToNative('error', [
                    'Uncaught Error:',
                    e.message,
                    'at',
                    e.filename + ':' + e.lineno + ':' + e.colno,
                    'Stack:', e.error ? e.error.stack : 'No stack trace available'
                ]);
            });
            
            // Capture unhandled promise rejections
            window.addEventListener('unhandledrejection', function(e) {
                sendToNative('error', [
                    'Unhandled Promise Rejection:',
                    e.reason,
                    'Stack:', e.reason && e.reason.stack ? e.reason.stack : 'No stack trace available'
                ]);
            });
            
            // Send initial debug message
            if (isDebugMode) {
                console.info('AdSDK Console Logging Bridge initialized');
            }
        })();
        """
    }
    
    // MARK: - Private Methods
    
    /// Default console message handling
    /// - Parameters:
    ///   - level: Log level
    ///   - message: Log message
    ///   - timestamp: Timestamp
    private func handleDefaultConsoleMessage(level: ConsoleLogLevel, message: String, timestamp: String) {
        let prefix = "[WebView Console]"
        let formattedMessage = "\(level.emoji) \(prefix) \(message)"
        
        switch level {
        case .error:
            AdDebugger.shared.error(formattedMessage)
        case .warn:
            AdDebugger.shared.warn(formattedMessage)
        case .info:
            AdDebugger.shared.info(formattedMessage)
        case .debug:
            AdDebugger.shared.debug(formattedMessage)
        case .log:
            AdDebugger.shared.debug(formattedMessage)
        }
    }
}

/// Extension for WKUserContentController integration
extension ConsoleLogHandler {
    /// Configure WKUserContentController with console logging
    /// - Parameters:
    ///   - userContentController: WKUserContentController to configure
    ///   - debugMode: Whether debug mode is enabled
    public func configureUserContentController(
        _ userContentController: WKUserContentController,
        debugMode: Bool
    ) {
        // Add console log script message handler
        userContentController.add(ConsoleLogMessageHandler(), name: "consoleLog")
        
        // Add console logging script
        let consoleScript = WKUserScript(
            source: generateConsoleLoggingJavaScript(debugMode: debugMode),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(consoleScript)
        
        AdDebugger.shared.debug("Console logging configured for WebView")
    }
}

/// Message handler wrapper for WKScriptMessageHandler
private class ConsoleLogMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        ConsoleLogHandler.shared.handleConsoleMessage(message)
    }
}
