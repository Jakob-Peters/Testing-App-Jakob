import SwiftUI
import WebKit
import Didomi

// UIKit-based AdWebView for proper consent injection timing
class UIKitAdWebViewController: UIViewController, WKNavigationDelegate {
    var adUrl: URL?
    var webView: WKWebView!

    init(adUrl: URL?) {
        self.adUrl = adUrl
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: view.bounds, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)

        // Wait for Didomi to be ready before loading the ad URL and injecting consent
        if Didomi.shared.isReady() {
            loadAdAndInjectConsent()
        } else {
            Didomi.shared.onReady { [weak self] in
                self?.loadAdAndInjectConsent()
            }
        }
    }

    private func loadAdAndInjectConsent() {
        guard let adUrl = adUrl else { return }
        let request = URLRequest(url: adUrl)
        webView.load(request)
        // Inject Didomi consent JS after page load
        webView.navigationDelegate = self
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
    }
}

struct UIKitAdWebView: UIViewControllerRepresentable {
    let adUrl: URL?
    func makeUIViewController(context: Context) -> UIKitAdWebViewController {
        return UIKitAdWebViewController(adUrl: adUrl)
    }
    func updateUIViewController(_ uiViewController: UIKitAdWebViewController, context: Context) {}
}

struct ContentView: View {
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
            VStack(spacing: 32) {
                DidomiWrapper()
                    .frame(width: 0, height: 0)

                Text("Welcome to the Ad Tech Testbed!")
                    .font(.title)
                    .padding(.top, 32)

                Text("This is some text before the first ad.")
                    .font(.body)

                UIKitAdWebView(adUrl: adURL(adUnitId: "div-gpt-ad-mobile_1"))
                    .frame(height: 500)
                    .border(Color.gray, width: 1)
                    .padding(.horizontal)

                Text("This is some text between the ads.")
                    .font(.body)
                    .padding(.bottom, 32)

                UIKitAdWebView(adUrl: adURL(adUnitId: "div-gpt-ad-mobile_dai"))
                    .frame(height: 400)
                    .border(Color.blue, width: 1)
                    .padding(.horizontal)

                Text("This is some text after the second ad.")
                    .font(.body)
                    .padding(.bottom, 32)

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
                .padding(.bottom, 32)
            }
        }
    }
}
