import SwiftUI
import Didomi

struct ContentView: View {
    @State private var didomiReady = false

    func adURL(adUnitId: String) -> URL? {
        var components = URLComponents(string: "https://adops.stepdev.dk/wp-content/google-test-ad.html")
        var items = [
            URLQueryItem(name: "adUnitId", value: adUnitId),
            URLQueryItem(name: "aym_debug", value: "true"),
            //URLQueryItem(name: "didomiConfig.notice.enable", value: "false")
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

                if didomiReady, let url1 = adURL(adUnitId: "div-gpt-ad-mobile_1") {
                    AdWebView(url: url1)
                        .frame(height: 500)
                        .border(Color.gray, width: 1)
                        .padding(.horizontal)
                } else if !didomiReady {
                    Text("Waiting for consent...")
                } else {
                    Text("Ad 1 failed to load.")
                }
                
                
                Text("This is some text between the ads.")
                    .font(.body)
                .padding(.bottom, 32)
                
                if didomiReady, let url2 = adURL(adUnitId: "div-gpt-ad-mobile_2") {
                    AdWebView(url: url2)
                        .frame(height: 250)
                        .border(Color.blue, width: 1)
                        .padding(.horizontal)
                } else if !didomiReady {
                    Text("")
                } else {
                    Text("Ad 2 failed to load.")
                }

                Text("This is some text after the second ad.")
                    .font(.body)
                    .padding(.bottom, 32)
                

                
                // Add Didomi consent change button at the bottom
                Button(action: {
                    // Show the Didomi Preferences screen (always available after consent)
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
        .onAppear {
            // Wait for Didomi to be ready, then mark as ready (consent is injected via JS, not query string)
            if Didomi.shared.isReady() {
                didomiReady = true
            } else {
                Didomi.shared.onReady {
                    didomiReady = true
                }
            }
        }
    }
}
