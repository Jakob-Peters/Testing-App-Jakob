import SwiftUI
import WebKit
import Didomi

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
        title: "Page 1: SwiftUI Navigation",
        preview: "Learn about navigation in SwiftUI and how to structure your app.",
        content: [
            "SwiftUI makes navigation easy with NavigationStack.",
            "You can create multiple pages and navigate between them.",
            "Each page can have its own content and layout.",
            "Navigation is type-safe and works well with data models.",
            "You can use NavigationLink to push new views onto the stack.",
            "Let's see how ads can be integrated between article sections."
        ]
    ),
    Article(
        id: 2,
        title: "Page 2: Integrating Ads",
        preview: "How to place ad units within your article content.",
        content: [
            "Ad units can be placed anywhere in your SwiftUI view hierarchy.",
            "It's common to show ads between paragraphs or sections.",
            "You can use custom ad views or UIKit wrappers.",
            "Make sure to respect user consent and privacy.",
            "Test ad placement on different devices and screen sizes.",
            "Now, let's see two ad units in this article."
        ]
    ),
    Article(
        id: 3,
        title: "Page 3: Best Practices",
        preview: "Tips for a great user experience with ads and navigation.",
        content: [
            "Keep navigation simple and intuitive for users.",
            "Don't overload pages with too many ads.",
            "Use clear labels and previews for articles.",
            "Test navigation flows for edge cases.",
            "Monitor ad performance and user engagement.",
            "Balance content and monetization for best results."
        ]
    )
]

// UIKit-based AdWebView for proper consent injection timing
class UIKitAdWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var initialURL: URL? // Store the initial URL loaded in the webView
    var adUrl: URL?
    var webView: WKWebView!
    var onSizeChanged: ((CGSize) -> Void)?
    private var hasUserInteracted: Bool = false

    init(adUrl: URL?, onSizeChanged: @escaping (CGSize) -> Void) {
        self.adUrl = adUrl
        self.onSizeChanged = onSizeChanged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("UIKitAdWebViewController deinit - webview being deallocated")
        webView?.stopLoading()
        webView?.removeFromSuperview()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        
        // Wait for Didomi to be ready before loading the ad URL and injecting consent
        if Didomi.shared.isReady() {
            loadAdAndInjectConsent()
        } else {
            Didomi.shared.onReady { [weak self] in
                self?.loadAdAndInjectConsent()
            }
        }
    }
    
    private func setupWebView() {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webViewConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true // Allow JS window.open

        // Add user content controller for size communication and console logging
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "sizeHandler")
        userContentController.add(self, name: "consoleLog")
        webViewConfiguration.userContentController = userContentController

        // Inject JavaScript to capture console logs
        
        let consoleLogScript = WKUserScript(source: """
            // Override console methods to send logs to native app
            (function() {
                const originalLog = console.log;
                const originalError = console.error;
                const originalWarn = console.warn;
                const originalInfo = console.info;
                const originalDebug = console.debug;
                function sendToNative(level, args) {
                    const message = Array.from(args).map(arg => {
                        if (typeof arg === 'object') {
                            try {
                                return JSON.stringify(arg);
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
                            timestamp: new Date().toISOString()
                        });
                    }
                }
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
                // Also capture uncaught errors
                window.addEventListener('error', function(e) {
                    sendToNative('error', ['Uncaught Error:', e.message, 'at', e.filename + ':' + e.lineno + ':' + e.colno]);
                });
                // Capture unhandled promise rejections
                window.addEventListener('unhandledrejection', function(e) {
                    sendToNative('error', ['Unhandled Promise Rejection:', e.reason]);
                });
            })();
        """, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(consoleLogScript)

        webView = WKWebView(frame: view.bounds, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self // Set the UI delegate
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
    }

    private func loadAdAndInjectConsent() {
        guard let adUrl = adUrl else { return }
        self.initialURL = adUrl // Store the initial URL when it's first loaded
        let request = URLRequest(url: adUrl)
        webView.load(request)
        print("Loading ad: \(adUrl.absoluteString)")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let didomiJavaScriptCode = Didomi.shared.getJavaScriptForWebView()
        webView.evaluateJavaScript(didomiJavaScriptCode) { (result, error) in
            if let error = error {
                print("Error injecting Didomi JavaScript: \(error.localizedDescription)")
            } else {
                print("Didomi JavaScript injected successfully into WKWebView.")
            }
        }
        // The size monitoring is now handled directly in the HTML file
        print("WebView finished loading. Size monitoring is active in HTML.")
    }

    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print("[WKUIDelegate] createWebViewWith: navigationType=\(navigationAction.navigationType.rawValue), url=\(navigationAction.request.url?.absoluteString ?? "nil"), targetFrameIsNil=\(navigationAction.targetFrame == nil)")
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            if handleExternalURL(navigationAction: navigationAction) {
                print("[WKUIDelegate] Opened externally and returning nil for new webview.")
                return nil // Opened externally, don't create a new webview
            }
        }
        print("[WKUIDelegate] Returning nil, not handled externally.")
        return nil
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("[WKNavigationDelegate] decidePolicyFor: navigationType=\(navigationAction.navigationType.rawValue), url=\(navigationAction.request.url?.absoluteString ?? "nil"), targetFrameIsNil=\(navigationAction.targetFrame == nil)")
        if handleExternalURL(navigationAction: navigationAction) {
            print("[WKNavigationDelegate] Opened externally and cancelling navigation.")
            decisionHandler(.cancel)
        } else {
            print("[WKNavigationDelegate] Allowing navigation internally.")
            decisionHandler(.allow)
        }
    }

    // MARK: - External URL Handling
    /// Determines if a URL should be opened externally and handles the opening.
    /// Returns true if the URL was handled externally, false otherwise.
    private func handleExternalURL(navigationAction: WKNavigationAction) -> Bool {
        guard let targetURL = navigationAction.request.url else {
            print("[handleExternalURL] No target URL, allowing internally.")
            return false
        }

        print("[handleExternalURL] navigationType=\(navigationAction.navigationType.rawValue), url=\(targetURL.absoluteString), targetFrameIsNil=\(navigationAction.targetFrame == nil)")

        // 1. Always allow non-HTTP/HTTPS schemes to open externally (e.g., tel, mailto, app-specific deep links)
        if let scheme = targetURL.scheme, !["http", "https"].contains(scheme.lowercased()) {
            print("[handleExternalURL] Non-http(s) scheme detected, opening externally: \(scheme)")
            UIApplication.shared.open(targetURL, options: [:], completionHandler: nil)
            return true
        }

        // Use the initial loaded URL for domain comparison
        guard let initialLoadedURL = self.initialURL, let initialDomain = initialLoadedURL.host else {
            if navigationAction.targetFrame == nil {
                print("[handleExternalURL] No initialURL, but new window request. Opening externally.")
                UIApplication.shared.open(targetURL, options: [:], completionHandler: nil)
                return true
            }
            print("[handleExternalURL] No initialURL, allowing internally.")
            return false
        }
        guard let targetDomain = targetURL.host else {
            print("[handleExternalURL] No target domain, allowing internally.")
            return false
        }

        let isMainFrameNavigation = navigationAction.targetFrame?.isMainFrame == true
        let isDifferentFromInitialDomain = initialDomain != targetDomain

        print("[handleExternalURL] initialDomain=\(initialDomain), targetDomain=\(targetDomain), isMainFrameNavigation=\(isMainFrameNavigation), isDifferentFromInitialDomain=\(isDifferentFromInitialDomain)")

        if isMainFrameNavigation && isDifferentFromInitialDomain {
            print("[handleExternalURL] Main frame navigation to different domain. Opening externally: \(targetURL.absoluteString)")
            UIApplication.shared.open(targetURL, options: [:], completionHandler: nil)
            return true
        }

        print("[handleExternalURL] Allowing navigation internally.")
        return false
    }
}

// Extension to handle JavaScript messages
extension UIKitAdWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "sizeHandler" {
            if let sizeData = message.body as? [String: Any],
               let width = sizeData["width"] as? Double,
               let height = sizeData["height"] as? Double {
                let size = CGSize(width: width, height: height)
                //print("Received ad size update: \(size)")
                DispatchQueue.main.async {
                    self.onSizeChanged?(size)
                }
            } else {
                print("Invalid size data received: \(message.body)")
            } 
        } else if message.name == "consoleLog" {
            if let logData = message.body as? [String: Any],
               let level = logData["level"] as? String,
               let logMessage = logData["message"] as? String,
               let timestamp = logData["timestamp"] as? String {
                let prefix = level.uppercased()
                print("[\(prefix)] WebView Console: \(logMessage)")
            } else {
                print("WebView Console: \(message.body)")
            }
        }
    }
}

struct UIKitAdWebView: UIViewControllerRepresentable {
    let adUrl: URL?
    @Binding var adSize: CGSize
    
    func makeUIViewController(context: Context) -> UIKitAdWebViewController {
        return UIKitAdWebViewController(adUrl: adUrl) { size in
            self.adSize = size
        }
    }
    
    func updateUIViewController(_ uiViewController: UIKitAdWebViewController, context: Context) {}
    
    static func dismantleUIViewController(_ uiViewController: UIKitAdWebViewController, coordinator: ()) {
        print("UIKitAdWebView being dismantled")
        uiViewController.webView?.stopLoading()
        uiViewController.webView?.removeFromSuperview()
    }
}

struct ContentView: View {
    @State private var path: [Int] = [] // Navigation path (article IDs)
    @State private var adSizeFront = CGSize(width: 320, height: 250)
    @State private var frontPageAdKey = UUID() // Key to force webview recreation
    private let didomiEventListener = EventListener()

    func adURL(adUnitId: String) -> URL? {
        var components = URLComponents(string: "https://adops.stepdev.dk/wp-content/google-test-ad.html")
        var items = [
            URLQueryItem(name: "adUnitId", value: adUnitId),
            URLQueryItem(name: "aym_debug", value: "true")
        ]
        components?.queryItems = items
        return components?.url
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    DidomiWrapper()
                        .frame(width: 0, height: 0)

                    // Front page ad - only show when on front page
                    if path.isEmpty {
                        UIKitAdWebView(adUrl: adURL(adUnitId: "div-gpt-ad-mobile_1"), adSize: $adSizeFront)
                            .frame(width: adSizeFront.width, height: max(adSizeFront.height, 100))
                            .border(Color.gray, width: 1)
                            .padding(.top, 24)
                            .id(frontPageAdKey) // Force recreation with new key
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
                    
                    // Add consent button
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
                    .padding(.top, 16)
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Front Page")
            .navigationDestination(for: Int.self) { articleId in
                if let article = articles.first(where: { $0.id == articleId }) {
                    ArticleView(article: article)
                } else {
                    Text("Article not found.")
                }
            }
            .onAppear {
                // Regenerate key when returning to front page to force webview recreation
                frontPageAdKey = UUID()
            }
        }
        .onAppear {
            // Set up Didomi event listener for consent changes
            setupDidomiEventListener()
        }
    }
    
    private func setupDidomiEventListener() {
        // Set up the consent changed event listener
        didomiEventListener.onConsentChanged = { event in
            print("Didomi consent status changed")
            NotificationCenter.default.post(name: NSNotification.Name("ConsentUpdated"), object: nil)
        }
        
        // Add the event listener to Didomi
        Didomi.shared.addEventListener(listener: didomiEventListener)
    }
}

struct ArticleView: View {
    let article: Article
    @State private var adSize1 = CGSize(width: 320, height: 250)
    @State private var adSize2 = CGSize(width: 320, height: 250)
    @State private var adKey1 = UUID() // Key to force webview recreation
    @State private var adKey2 = UUID() // Key to force webview recreation

    func adURL(adUnitId: String) -> URL? {
        var components = URLComponents(string: "https://adops.stepdev.dk/wp-content/google-test-ad.html")
        var items = [
            URLQueryItem(name: "adUnitId", value: adUnitId),
            URLQueryItem(name: "aym_debug", value: "true")
        ]
        components?.queryItems = items
        return components?.url
    }

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

                // First ad
                UIKitAdWebView(adUrl: adURL(adUnitId: "div-gpt-ad-mobile_1"), adSize: $adSize1)
                    .frame(width: adSize1.width, height: max(adSize1.height, 100))
                    .border(Color.gray, width: 1)
                    .id(adKey1) // Force recreation with new key

                // Second half of article text
                ForEach(article.content.suffix(from: 3), id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.body)
                }

                // Second ad
                UIKitAdWebView(adUrl: adURL(adUnitId: "div-gpt-ad-mobile_2"), adSize: $adSize2)
                    .frame(width: adSize2.width, height: max(adSize2.height, 100))
                    .border(Color.blue, width: 1)
                    .id(adKey2) // Force recreation with new key

                Spacer(minLength: 32)
            }
            .padding(.horizontal)
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Regenerate keys when article appears to force webview recreation
            adKey1 = UUID()
            adKey2 = UUID()
        }
    }
}
