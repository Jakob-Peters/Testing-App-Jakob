# Known Issues / Bugs

1. **First / Initial page view will not load ads, since the consent isn't set by the user on the first page view.**
   - The Didomi SDK must collect consent before the TCF string is available. The ad webview is loaded before consent is set, so the ad unit will not render on the first load. After the user provides consent, subsequent loads will work as expected.

2. **Clicking on an ad within the webview will open the link within the webview and not in the external browser of the device.**
   - Due to WKWebView and ad creative limitations, not all ad clicks can be forced to open externally. The app attempts to intercept and open all navigations externally, but some ad links may still open inside the webview.

---
If you see "Multiple commands produce" errors, check your Xcode target's Copy Bundle Resources for duplicate or unnecessary files and remove them.
The app is SwiftUI-based and does not use storyboards; you can remove Main.storyboard if not needed.

# File Overview

**AppDelegate.swift**  
Handles app lifecycle events and initializes the Didomi CMP SDK and Google Mobile Ads SDK. Ensures consent is collected before ad SDKs are started.

**Testing_App_JakobApp.swift**  
The SwiftUI app entry point. Sets up the main window and attaches the ContentView.

**ContentView.swift**  
The main SwiftUI view. Manages consent state, builds ad URLs, and displays two ad slots using AdWebView. Also provides a button to change consent via Didomi.

**AdWebView.swift**  
A SwiftUI wrapper for WKWebView. Loads the ad HTML from a URL, injects Didomi consent into the webview after the Didomi SDK is ready, and handles navigation events. Used by ContentView to display ads. Attempts to force all ad clicks to open externally, but due to WKWebView limitations, some links may still open inside the webview.

**DidomiWrapper.swift**  
SwiftUI wrapper to embed the Didomi consent UI in the app. Ensures the consent dialog is shown and can be triggered again.

**google-test-ad.html**  
The ad test HTML file. Dynamically creates an ad slot based on query parameters, exposes the TCF string to ad scripts. Loaded by AdWebView.


# Testing App Jakob

## Overview
This project is an ad tech testbed app for iOS, built with SwiftUI. It is designed to:

- Test and debug ad rendering using AssertiveYield (AY) and Google Publisher Tags (GPT.js) in a WKWebView.
- Integrate the Didomi Consent Management Platform (CMP) to handle user consent and pass the TCF string to ad scripts.
- Dynamically load ad units and pass consent data to the ad HTML via query parameters.
- Inject Didomi consent into the webview after the Didomi SDK is ready, using the Didomi-provided JavaScript. This ensures the web ad units have access to the user's consent string via the IAB TCF API (__tcfapi).



## Quick Start

1. Run the app in Xcode. The app will load the HTML for WKWebView from the external publisher web server.
2. Consent is managed by Didomi; ads will only load after consent is given.
3. Use the in-page console and Xcode logs for debugging ad and consent flows.

---
For more details, see code comments and the Didomi and AssertiveYield documentation.
