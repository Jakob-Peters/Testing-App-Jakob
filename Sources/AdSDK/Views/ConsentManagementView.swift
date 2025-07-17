import SwiftUI
import Didomi

/// SwiftUI view for Didomi consent management
public struct ConsentManagementView: UIViewControllerRepresentable {
    // MARK: - Properties
    
    /// Callback for consent changes
    private let onConsentChanged: ((ConsentStatus) -> Void)?
    
    /// Whether to show preferences immediately
    private let showPreferences: Bool
    
    // MARK: - Initialization
    
    /// Initialize consent management view
    /// - Parameters:
    ///   - showPreferences: Whether to show preferences immediately
    ///   - onConsentChanged: Callback for consent changes
    public init(
        showPreferences: Bool = false,
        onConsentChanged: ((ConsentStatus) -> Void)? = nil
    ) {
        self.showPreferences = showPreferences
        self.onConsentChanged = onConsentChanged
    }
    
    // MARK: - UIViewControllerRepresentable
    
    public func makeUIViewController(context: Context) -> ConsentViewController {
        let controller = ConsentViewController()
        controller.onConsentChanged = onConsentChanged
        
        if showPreferences {
            controller.showPreferences()
        }
        
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: ConsentViewController, context: Context) {
        uiViewController.onConsentChanged = onConsentChanged
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator: NSObject {
        // Coordinator can be used for more complex state management if needed
    }
}

/// UIKit view controller for Didomi consent management
public class ConsentViewController: UIViewController {
    // MARK: - Properties
    
    /// Callback for consent changes
    public var onConsentChanged: ((ConsentStatus) -> Void)?
    
    /// Didomi event listener
    private let eventListener = ConsentEventListener()
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupConsentManagement()
    }
    
    deinit {
        // Remove event listener
        Didomi.shared.removeEventListener(listener: eventListener.didomiListener)
    }
    
    // MARK: - Setup
    
    private func setupConsentManagement() {
        // Setup Didomi UI
        if Didomi.shared.isReady() {
            configureDidomiUI()
        } else {
            Didomi.shared.onReady { [weak self] in
                Task { @MainActor in
                    self?.configureDidomiUI()
                }
            }
        }
        
        // Setup event listener
        eventListener.onConsentChanged = { [weak self] status in
            self?.onConsentChanged?(status)
        }
        
        Didomi.shared.addEventListener(listener: eventListener.didomiListener)
    }
    
    private func configureDidomiUI() {
        Didomi.shared.setupUI(containerController: self)
        AdDebugger.shared.debug("Didomi UI configured")
    }
    
    // MARK: - Public Methods
    
    /// Show consent preferences
    public func showPreferences() {
        if Didomi.shared.isReady() {
            Didomi.shared.showPreferences(controller: self)
        } else {
            Didomi.shared.onReady { [weak self] in
                guard let self = self else { return }
                Didomi.shared.showPreferences(controller: self)
            }
        }
    }
    
    /// Show consent notice
    public func showNotice() {
        if Didomi.shared.isReady() {
            Didomi.shared.showNotice()
        } else {
            Didomi.shared.onReady { [weak self] in
                guard let self = self else { return }
                Didomi.shared.showNotice()
            }
        }
    }
    
    /// Get current consent status
    public func getConsentStatus() -> ConsentStatus {
        guard Didomi.shared.isReady() else {
            return .unknown
        }
        
        // This would need to be implemented based on actual Didomi SDK
        // For now, returning unknown
        return .unknown
    }
    
    /// Reset consent
    public func resetConsent() {
        if Didomi.shared.isReady() {
            Didomi.shared.reset()
            AdDebugger.shared.info("Consent reset")
        }
    }
}

/// Event listener for Didomi consent changes
private class ConsentEventListener: NSObject {
    var onConsentChanged: ((ConsentStatus) -> Void)?
    
    // Create an actual EventListener instance that we can configure
    lazy var didomiListener: EventListener = {
        let listener = EventListener()
        listener.onConsentChanged = { [weak self] event in
            self?.handleConsentChanged(event: event)
        }
        return listener
    }()
    
    private func handleConsentChanged(event: EventType) {
        AdDebugger.shared.debug("Consent changed event received")
        let status: ConsentStatus = .unknown // For now, simplified
        onConsentChanged?(status)
    }
}

// MARK: - Convenience Views

/// A simple consent button
public struct ConsentButton: View {
    @State private var showingConsent = false
    private let title: String
    private let onConsentChanged: ((ConsentStatus) -> Void)?
    
    public init(
        title: String = "Manage Consent",
        onConsentChanged: ((ConsentStatus) -> Void)? = nil
    ) {
        self.title = title
        self.onConsentChanged = onConsentChanged
    }
    
    public var body: some View {
        Button(action: {
            showingConsent = true
        }) {
            Text(title)
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .sheet(isPresented: $showingConsent) {
            ConsentManagementView(
                showPreferences: true,
                onConsentChanged: onConsentChanged
            )
        }
    }
}

/// A consent banner that shows when consent is needed
public struct ConsentBanner: View {
    @State private var showBanner = false
    private let onConsentChanged: ((ConsentStatus) -> Void)?
    
    public init(onConsentChanged: ((ConsentStatus) -> Void)? = nil) {
        self.onConsentChanged = onConsentChanged
    }
    
    public var body: some View {
        VStack {
            if showBanner {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Privacy Settings")
                            .font(.headline)
                        Text("We use cookies to improve your experience.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Manage") {
                        // Show Didomi preferences
                        showDidomiPreferences()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
        }
        .onAppear {
            checkConsentStatus()
        }
    }
    
    private func checkConsentStatus() {
        // This would check if consent banner should be shown
        // For now, showing it as an example
        showBanner = true
    }
    
    private func showDidomiPreferences() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            if Didomi.shared.isReady() {
                Didomi.shared.showPreferences(controller: rootVC)
            }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct ConsentManagementView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ConsentButton { status in
                print("Consent status changed: \(status)")
            }
            
            ConsentBanner { status in
                print("Consent status changed: \(status)")
            }
        }
        .padding()
    }
}
#endif
