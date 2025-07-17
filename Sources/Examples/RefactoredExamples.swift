import SwiftUI

// MARK: - Article Model
struct Article: Identifiable {
    let id: Int
    let title: String
    let preview: String
    let content: [String] // Each string is a paragraph
}

let articles: [Article] = [
    Article(
        id: 1,
        title: "AdSDK Integration Guide",
        preview: "Learn how to integrate the new modular AdSDK into your iOS project",
        content: [
            "The AdSDK provides a clean, modular approach to integrating web-based ads with consent management.",
            "With built-in Didomi integration, you can ensure GDPR compliance while maintaining optimal ad performance.",
            "The SDK includes automatic size detection, debug modes, and comprehensive logging capabilities."
        ]
    ),
    Article(
        id: 2,
        title: "Consent Management Best Practices",
        preview: "Understanding GDPR compliance and user consent in mobile advertising",
        content: [
            "User consent is crucial for modern advertising. The AdSDK integrates seamlessly with Didomi CMP.",
            "Proper consent management ensures legal compliance while maximizing ad revenue potential.",
            "The SDK automatically handles consent state changes and updates ad serving accordingly."
        ]
    ),
    Article(
        id: 3,
        title: "Debug Mode and Development Tips",
        preview: "Debugging tools and development workflow for the AdSDK",
        content: [
            "The AdSDK includes comprehensive debugging tools for development and testing.",
            "Debug mode automatically adds the aym_debug=true parameter for enhanced logging.",
            "Use the debug control panel to toggle various debugging features during development."
        ]
    )
]

// MARK: - Example: Refactored ContentView using new AdSDK

struct RefactoredContentView: View {
    @State private var path: [Int] = [] // Navigation path (article IDs)
    @State private var adSizeFront = CGSize(width: 320, height: 250)
    @State private var frontPageAdKey = UUID() // Key to force webview recreation
    @State private var showRestartAlert = false
    @State private var currentDebugMode = UserDefaults.standard.object(forKey: "AdSDKDebugMode") as? Bool ?? true
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    // Consent management - now much simpler
                    ConsentBanner { status in
                        print("Consent status changed: \(status)")
                    }
                    
                    // Front page ad - simplified usage
                    if path.isEmpty {
                        AdWebView(
                            adUnitId: "div-gpt-ad-mobile_1",
                            adSize: $adSizeFront,
                            debugMode: true, // This automatically adds aym_debug=true
                            onSizeChanged: { size in
                                print("Front page ad size: \(size)")
                            }
                        )
                        .frame(width: adSizeFront.width, height: max(adSizeFront.height, 100))
                        .border(Color.gray, width: 1)
                        .padding(.top, 24)
                        .id(frontPageAdKey)
                    }
                    
                    Text("Welcome! Choose an article to read:")
                        .font(.title2)
                        .padding(.top, 8)
                    
                    // Article previews
                    ForEach(articles) { article in
                        NavigationLink(value: article.id) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(article.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(article.preview)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    .padding(.top, 16)
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Front Page")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        toggleDebugMode()
                    }) {
                        Image(systemName: currentDebugMode ? "ladybug.fill" : "ladybug")
                            .foregroundColor(currentDebugMode ? .orange : .gray)
                    }
                }
            }
            .navigationDestination(for: Int.self) { articleId in
                if let article = articles.first(where: { $0.id == articleId }) {
                    RefactoredArticleView(article: article)
                } else {
                    Text("Article not found.")
                }
            }
            .onAppear {
                // Regenerate key when returning to front page
                frontPageAdKey = UUID()
            }
            .alert("Debug Mode Changed", isPresented: $showRestartAlert) {
                Button("OK") { }
            } message: {
                Text("Debug mode has been \(currentDebugMode ? "enabled" : "disabled"). Please completely close and reopen the app for changes to take effect.")
            }
        }
    }
    
    private func toggleDebugMode() {
        currentDebugMode.toggle()
        UserDefaults.standard.set(currentDebugMode, forKey: "AdSDKDebugMode")
        showRestartAlert = true
    }
}

// MARK: - Example: Refactored ArticleView

struct RefactoredArticleView: View {
    let article: Article
    @State private var adSize1 = CGSize(width: 320, height: 250)
    @State private var adSize2 = CGSize(width: 320, height: 250)
    @State private var adKey1 = UUID()
    @State private var adKey2 = UUID()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title)
                    .font(.title)
                    .padding(.top, 16)
                
                // First half of article text
                ForEach(article.content.prefix(3), id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.body)
                }
                
                // First ad - much simpler usage
                AdWebView(
                    adUnitId: "div-gpt-ad-mobile_1",
                    adSize: $adSize1,
                    debugMode: true
                )
                .frame(width: adSize1.width, height: max(adSize1.height, 100))
                .border(Color.gray, width: 1)
                .id(adKey1)
                
                // Second half of article text
                ForEach(article.content.suffix(from: 3), id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.body)
                }
                
                // Second ad
                AdWebView(
                    adUnitId: "div-gpt-ad-mobile_2",
                    adSize: $adSize2,
                    debugMode: true
                )
                .frame(width: adSize2.width, height: max(adSize2.height, 100))
                .border(Color.blue, width: 1)
                .id(adKey2)
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal)
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Regenerate keys when article appears
            adKey1 = UUID()
            adKey2 = UUID()
        }
    }
}

// MARK: - Example: Advanced Usage with Custom Configuration

struct AdvancedAdExample: View {
    @State private var adSize = CGSize(width: 300, height: 250)
    @State private var loadingState: AdLoadingState = .idle
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Advanced Ad Configuration")
                .font(.title2)
            
            // Create custom ad unit configuration
            let adUnitConfig = AdUnitConfiguration(
                adUnitId: "div-gpt-ad-mobile_1",
                debugMode: true,
                customParameters: [
                    "placement": "main-content",
                    "targeting_age": "25-34",
                    "targeting_gender": "male",
                    "custom_param": "value"
                ],
                initialSize: CGSize(width: 300, height: 250),
                minimumSize: CGSize(width: 100, height: 100),
                maximumSize: CGSize(width: 400, height: 400)
            )
            
            AdWebView(
                adUnitConfig: adUnitConfig,
                globalConfig: AdSDK.shared.configuration,
                adSize: $adSize,
                onSizeChanged: { size in
                    print("Ad size changed to: \(size)")
                },
                onStateChanged: { state in
                    loadingState = state
                    handleStateChange(state)
                }
            )
            .frame(width: adSize.width, height: adSize.height)
            .border(Color.gray)
            .overlay(
                loadingOverlay,
                alignment: .center
            )
            
            // State information
            Text("State: \(stateDescription)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        switch loadingState {
        case .loading:
            ProgressView("Loading ad...")
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
        case .failed(let error):
            Text("Error: \(error.localizedDescription)")
                .foregroundColor(.red)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
        default:
            EmptyView()
        }
    }
    
    private var stateDescription: String {
        switch loadingState {
        case .idle: return "Idle"
        case .loading: return "Loading"
        case .loaded: return "Loaded"
        case .failed: return "Failed"
        case .sizeUpdated(let size): return "Size: \(Int(size.width))x\(Int(size.height))"
        }
    }
    
    private func handleStateChange(_ state: AdLoadingState) {
        switch state {
        case .loaded:
            print("Ad loaded successfully")
        case .failed(let error):
            print("Ad failed to load: \(error)")
        case .sizeUpdated(let size):
            print("Ad size updated: \(size)")
        default:
            break
        }
    }
}

// MARK: - Example: Convenience Views

struct ConvenienceViewsExample: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Convenience Ad Views")
                    .font(.title)
                
                // Banner ad
                AdBannerView(
                    adUnitId: "div-gpt-ad-mobile_1",
                    debugMode: true
                )
                
                Text("Article content here...")
                    .font(.body)
                    .padding()
                
                // Medium rectangle ad
                AdMediumRectangleView(
                    adUnitId: "div-gpt-ad-mobile_1",
                    debugMode: true
                )
                
                Text("More article content...")
                    .font(.body)
                    .padding()
                
                // Responsive ad
                AdResponsiveView(
                    adUnitId: "div-gpt-ad-mobile_1",
                    maxWidth: 350,
                    debugMode: true
                )
            }
        }
    }
}

// MARK: - Example: Debug Controls

struct DebugControlsExample: View {
    @State private var debugMode = true
    @State private var verboseLogging = false
    @State private var consoleLogging = true
    @State private var showRestartAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Debug Controls")
                .font(.title2)
            
            // Debug toggles
            Toggle("Debug Mode", isOn: $debugMode)
                .onChange(of: debugMode) { value in
                    AdSDK.shared.setDebugMode(value)
                }
            
            Toggle("Verbose Logging", isOn: $verboseLogging)
                .onChange(of: verboseLogging) { value in
                    AdSDK.shared.setVerboseLogging(value)
                }
            
            Toggle("Console Logging", isOn: $consoleLogging)
                .onChange(of: consoleLogging) { value in
                    AdSDK.shared.setConsoleLogging(value)
                }
            
            // Debug actions
            Button("Clear Cache") {
                AdSDK.shared.clearCache()
            }
            
            Button("Reset Consent") {
                AdSDK.shared.resetConsent()
            }
            
            Button("Show Debug Info") {
                let debugInfo = AdSDK.shared.getDebugInfo()
                print("Debug Info: \(debugInfo)")
            }
            
            // Status display
            Text("SDK Status: \(AdSDK.shared.isSDKInitialized() ? "Initialized" : "Not Initialized")")
                .foregroundColor(AdSDK.shared.isSDKInitialized() ? .green : .red)
            
            Spacer()
            
            // App-level debug toggle button
            Button(action: {
                showRestartAlert = true
            }) {
                HStack {
                    Image(systemName: "ladybug.fill")
                    Text("Toggle App Debug Mode")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(10)
            }
            .alert("Debug Mode Changed", isPresented: $showRestartAlert) {
                Button("OK") { }
            } message: {
                Text("Debug mode has been toggled. Please completely close and reopen the app for changes to take effect.")
            }
        }
        .padding()
    }
}

// MARK: - Example: App with AdSDK Integration

// Example usage of the refactored AdSDK
struct RefactoredApp: App {
    init() {
        // Initialize AdSDK with debug mode
        AdSDK.shared.initialize(
            baseURL: "https://adops.stepdev.dk/wp-content/ad-template.html",
            didomiApiKey: "d0661bea-d696-4069-b308-11057215c4c4",
            yieldManagerId: "AFtbN2xnQGXShTYuo",
            debugMode: true // Easy toggle for debug mode
        )
        
        // Optional: Set up custom logging
        AdSDK.shared.setConsoleLogHandler { level, message, timestamp in
            print("[\(level.rawValue.uppercased())] \(timestamp): \(message)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                RefactoredContentView()
                    .tabItem {
                        Label("Articles", systemImage: "newspaper")
                    }
                
                ConvenienceViewsExample()
                    .tabItem {
                        Label("Ad Types", systemImage: "rectangle.grid.2x2")
                    }
                
                AdvancedAdExample()
                    .tabItem {
                        Label("Advanced", systemImage: "gear")
                    }
                
                DebugControlsExample()
                    .tabItem {
                        Label("Debug", systemImage: "ladybug")
                    }
            }
        }
    }
}
