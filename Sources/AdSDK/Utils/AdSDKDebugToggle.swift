import Foundation

/// Simple debug toggle utility for easy switching between debug and production modes
public class AdSDKDebugToggle {
    
    /// Debug configuration presets
    public enum DebugPreset {
        case production
        case development
        case testing
        case verbose
        
        var config: (debugMode: Bool, verboseLogging: Bool, consoleLogging: Bool) {
            switch self {
            case .production:
                return (false, false, false)
            case .development:
                return (true, false, true)
            case .testing:
                return (true, true, true)
            case .verbose:
                return (true, true, true)
            }
        }
    }
    
    /// Current debug preset
    private static var currentPreset: DebugPreset = .production
    
    /// Apply debug preset
    /// - Parameter preset: Debug preset to apply
    public static func applyPreset(_ preset: DebugPreset) {
        currentPreset = preset
        let config = preset.config
        
        AdSDK.shared.setDebugMode(config.debugMode)
        AdSDK.shared.setVerboseLogging(config.verboseLogging)
        AdSDK.shared.setConsoleLogging(config.consoleLogging)
        
        print("📱 AdSDK Debug Preset Applied: \(preset)")
        print("   Debug Mode: \(config.debugMode)")
        print("   Verbose Logging: \(config.verboseLogging)")
        print("   Console Logging: \(config.consoleLogging)")
    }
    
    /// Quick toggle for debug mode
    /// - Parameter enabled: Whether to enable debug mode
    public static func setDebugMode(_ enabled: Bool) {
        if enabled {
            applyPreset(.development)
        } else {
            applyPreset(.production)
        }
    }
    
    /// Get current preset
    /// - Returns: Current debug preset
    public static func getCurrentPreset() -> DebugPreset {
        return currentPreset
    }
    
    /// Check if debug mode is enabled
    /// - Returns: Whether debug mode is enabled
    public static func isDebugEnabled() -> Bool {
        return AdSDK.shared.isSDKInitialized() && currentPreset.config.debugMode
    }
}

// MARK: - Build Configuration Detection

extension AdSDKDebugToggle {
    /// Automatically apply appropriate preset based on build configuration
    public static func applyAutomaticPreset() {
        #if DEBUG
        applyPreset(.development)
        #else
        applyPreset(.production)
        #endif
    }
    
    /// Check if running in debug build
    /// - Returns: Whether running in debug build
    public static func isDebugBuild() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

/// SwiftUI view for debug controls
public struct DebugControlPanel: View {
    @State private var currentPreset: AdSDKDebugToggle.DebugPreset = .production
    @State private var showDebugInfo = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("AdSDK Debug Controls")
                .font(.title2)
                .fontWeight(.bold)
            
            // Preset selector
            Picker("Debug Preset", selection: $currentPreset) {
                Text("Production").tag(AdSDKDebugToggle.DebugPreset.production)
                Text("Development").tag(AdSDKDebugToggle.DebugPreset.development)
                Text("Testing").tag(AdSDKDebugToggle.DebugPreset.testing)
                Text("Verbose").tag(AdSDKDebugToggle.DebugPreset.verbose)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: currentPreset) { preset in
                AdSDKDebugToggle.applyPreset(preset)
            }
            
            // Quick actions
            HStack(spacing: 12) {
                Button("Auto Config") {
                    AdSDKDebugToggle.applyAutomaticPreset()
                    currentPreset = AdSDKDebugToggle.getCurrentPreset()
                }
                .buttonStyle(.bordered)
                
                Button("Clear Cache") {
                    AdSDK.shared.clearCache()
                }
                .buttonStyle(.bordered)
                
                Button("Reset Consent") {
                    AdSDK.shared.resetConsent()
                }
                .buttonStyle(.bordered)
            }
            
            // Debug info toggle
            Toggle("Show Debug Info", isOn: $showDebugInfo)
            
            if showDebugInfo {
                debugInfoView
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            currentPreset = AdSDKDebugToggle.getCurrentPreset()
        }
    }
    
    @ViewBuilder
    private var debugInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug Information")
                .font(.headline)
            
            let debugInfo = AdSDK.shared.getDebugInfo()
            
            ForEach(debugInfo.keys.sorted(), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(debugInfo[key] ?? "N/A")")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

// MARK: - Example Usage

#if DEBUG
struct DebugControlPanel_Previews: PreviewProvider {
    static var previews: some View {
        DebugControlPanel()
            .padding()
    }
}
#endif

// MARK: - Convenience Methods

extension AdSDK {
    /// Quick debug mode toggle
    /// - Parameter enabled: Whether to enable debug mode
    public func quickDebugToggle(_ enabled: Bool) {
        AdSDKDebugToggle.setDebugMode(enabled)
    }
    
    /// Apply automatic debug preset based on build configuration
    public func applyAutomaticDebugPreset() {
        AdSDKDebugToggle.applyAutomaticPreset()
    }
}
