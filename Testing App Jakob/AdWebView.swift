import SwiftUI
import WebKit
import Didomi

struct AdWebView: UIViewRepresentable {
    let url: URL // The URL for your remote ad page
    var navigationDelegate: WKNavigationDelegate? // Optional delegate for navigation control

    func makeUIView(context: Context) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webViewConfiguration.userContentController = context.coordinator.userContentController


        let webView = WKWebView(frame:.zero, configuration: webViewConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isInspectable = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request) // Load the URL [14, 21]
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: AdWebView
        let userContentController = WKUserContentController()
        private var didLoadInitialRequest = false

        init(_ parent: AdWebView) {
            self.parent = parent
            super.init()
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

    }
}
