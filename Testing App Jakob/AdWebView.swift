import SwiftUI
import WebKit
import Didomi

struct AdWebView: UIViewRepresentable {
    let url: URL // The URL for your remote ad page
    var navigationDelegate: WKNavigationDelegate? // Optional delegate for navigation control

    func makeUIView(context: Context) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()
        // Configure for optimal ad content display (see next step)
        webViewConfiguration.allowsInlineMediaPlayback = true // Allow inline video playback [15]
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = [] // Allow autoplay for all media types
        webViewConfiguration.userContentController = context.coordinator.userContentController // For JS injection/communication [16]

        // Register JS log handler
        context.coordinator.userContentController.add(context.coordinator, name: "log")

        let webView = WKWebView(frame:.zero, configuration: webViewConfiguration)
        webView.navigationDelegate = context.coordinator // Set the coordinator as navigation delegate [13, 17]
        webView.isInspectable = true // Enable Safari Web Inspector for debugging [18, 19, 20]
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request) // Load the URL [14, 21]
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: AdWebView
        let userContentController = WKUserContentController() // For JavaScript communication

        init(_ parent: AdWebView) {
            self.parent = parent
            super.init()
            // Register log handler in makeUIView
        }

        // MARK: - WKNavigationDelegate methods
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Example: Open external links in Safari
            if navigationAction.navigationType == .linkActivated {
                if let host = url.host, !host.contains("stepnetwork.dk") { // Replace with your app's domain or ad server domain
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel) // Prevent WKWebView from loading it [22]
                    return
                }
            }
            decisionHandler(.allow) // Allow other navigations within the web view [23]
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("AdWebView finished loading: \(webView.url?.absoluteString ?? "N/A")")
            // Inject Didomi consent sync JS after the page loads using the new pattern
            #if canImport(Didomi)
            Didomi.shared.onReady {
                let didomiJavaScriptCode = Didomi.shared.getJavaScriptForWebView()
                webView.evaluateJavaScript(didomiJavaScriptCode, completionHandler: nil)
            }
            #endif
        }

        // MARK: - WKScriptMessageHandler (for receiving messages from JavaScript)
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "log" {
                print("[JS LOG] \(message.body)")
            } else {
                print("Received message from JS: \(message.name) - \(message.body)")
            }
        }
    }
}
