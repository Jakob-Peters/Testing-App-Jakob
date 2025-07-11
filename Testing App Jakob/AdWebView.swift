import SwiftUI
import WebKit

struct AdWebView: UIViewRepresentable {
    let url: URL // The URL for your remote ad page
    var navigationDelegate: WKNavigationDelegate? // Optional delegate for navigation control

    func makeUIView(context: Context) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()
        // Configure for optimal ad content display (see next step)
        webViewConfiguration.allowsInlineMediaPlayback = true // Allow inline video playback [15]
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = // Allow autoplay for media [15]
        webViewConfiguration.userContentController = context.coordinator.userContentController // For JS injection/communication [16]

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
            // Add message handlers if you plan to send messages from JS to Swift
            // userContentController.add(self, name: "yourMessageHandlerName")
        }

        // MARK: - WKNavigationDelegate methods
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Example: Open external links in Safari
            if navigationAction.navigationType ==.linkActivated {
                if!url.host!.contains("stepnetwork.dk") { // Replace with your app's domain or ad server domain
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel) // Prevent WKWebView from loading it [22]
                    return
                }
            }
            decisionHandler(.allow) // Allow other navigations within the web view [23]
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("AdWebView finished loading: \(webView.url?.absoluteString?? "N/A")")
            // You can inject JavaScript here after the page loads, e.g., to pass TCF string
            // let tcfString = "..." // Get from Didomi
            // webView.evaluateJavaScript("window.setTcfString('\(tcfString)');") {... } [24, 25]
        }

        // MARK: - WKScriptMessageHandler (for receiving messages from JavaScript)
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Handle messages sent from JavaScript using window.webkit.messageHandlers.yourMessageHandlerName.postMessage()
            print("Received message from JS: \(message.name) - \(message.body)")
        }
    }
}
