import SwiftUI

struct ContentView: View {
    @State private var inlineAdURL: URL?

    var body: some View {
        VStack {
            Text("Ad Tech Testbed")
               .font(.largeTitle)
               .padding()

            Spacer()

            // Display the inline ad WebView
            if let url = inlineAdURL {
                AdWebView(url: url)
                   .frame(height: 300) // Adjust height as needed for your inline ad
                   .border(Color.gray, width: 1) // Visual border for the ad container
                   .padding()
            } else {
                Text("Loading inline ad...")
                   .padding()
            }

            Button("Load Inline Ad") {
                // Example: Get TCF string from Didomi (after Didomi.shared.onReady is called)
                let tcfString = Didomi.shared.getQueryStringForWebView() // [11]
                let adSlotID = "/1234/native1" // Your ad slot ID

                var components = URLComponents(string: "https://your-ad-server.com/adpage.html")
                components?.queryItems =
                inlineAdURL = components?.url
            }
           .padding()

            Spacer()
        }
    }
}
