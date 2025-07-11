import SwiftUI

struct ContentView: View {
    func ayAdURL(adUnitId: String) -> URL? {
        if let fileURL = Bundle.main.url(forResource: "ay-test-ad", withExtension: "html") {
            var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "adUnitId", value: adUnitId)
            ]
            return components?.url
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("AssertiveYield Test App")
                    .font(.title)
                    .padding(.top, 32)

                Text("This is some text before the ad.")
                    .font(.body)

                if let url = ayAdURL(adUnitId: "div-gpt-ad-mobile_1") {
                    AYAdWebView(url: url)
                        .frame(minHeight: 50)
                        .border(Color.green, width: 1)
                        .padding(.horizontal)
                } else {
                    Text("Ad failed to load.")
                }

                Text("This is some text after the ad.")
                    .font(.body)
                    .padding(.bottom, 32)
            }
        }
    }
}
