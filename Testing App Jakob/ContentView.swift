import SwiftUI
import Didomi

struct ContentView: View {
    func adURL(adUnitPath: String, width: Int, height: Int, slotId: String) -> URL? {
        if let fileURL = Bundle.main.url(forResource: "google-test-ad", withExtension: "html") {
            var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "adUnitPath", value: adUnitPath),
                URLQueryItem(name: "width", value: String(width)),
                URLQueryItem(name: "height", value: String(height)),
                URLQueryItem(name: "slotId", value: slotId)
            ]
            return components?.url
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Welcome to the Ad Tech Testbed!")
                    .font(.title)
                    .padding(.top, 32)

                Text("This is some text before the first ad.")
                    .font(.body)

                if let url1 = adURL(adUnitPath: "/6355419/Travel/Europe/France/Paris", width: 300, height: 250, slotId: "ad-slot-1") {
                    AdWebView(url: url1)
                        .frame(height: 250)
                        .border(Color.gray, width: 1)
                        .padding(.horizontal)
                } else {
                    Text("Ad 1 failed to load.")
                }

                Text("This is some text between the ads.")
                    .font(.body)

                if let url2 = adURL(adUnitPath: "/6355419/Travel/Europe/France/Paris", width: 300, height: 250, slotId: "ad-slot-2") {
                    AdWebView(url: url2)
                        .frame(height: 250)
                        .border(Color.blue, width: 1)
                        .padding(.horizontal)
                } else {
                    Text("Ad 2 failed to load.")
                }

                Text("This is some text after the second ad.")
                    .font(.body)
                    .padding(.bottom, 32)
            }
        }
    }
}
