//
//  WebViewContainer.swift
//  DevNotch
//
//  Created on 1/6/2026.
//

import SwiftUI
import WebKit

struct WebViewContainer: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        // Setup message handler for JS -> Swift communication
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "devnotch")
        configuration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        
        // Load URL based on environment
        #if DEBUG
        if let url = URL(string: "http://localhost:5173") {
            webView.load(URLRequest(url: url))
        }
        #else
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "dist") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        #endif
        
        // Listen for hover state changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NotchHoverStateChanged"),
            object: nil,
            queue: .main
        ) { notification in
            if let isHovering = notification.userInfo?["isHovering"] as? Bool {
                context.coordinator.sendEventToJS(webView: webView, event: "hover", data: ["isHovering": isHovering])
            }
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Updates handled via coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "devnotch",
                  let body = message.body as? [String: Any],
                  let command = body["command"] as? String else {
                return
            }
            
            handleCommand(command: command, params: body["params"] as? [String: Any])
        }
        
        private func handleCommand(command: String, params: [String: Any]?) {
            switch command {
            case "play":
                MediaRemoteController.shared.play()
            case "pause":
                MediaRemoteController.shared.pause()
            case "next":
                MediaRemoteController.shared.nextTrack()
            case "previous":
                MediaRemoteController.shared.previousTrack()
            case "getToken":
                if let token = KeychainHelper.shared.getToken() {
                    // Send token back to JS
                    print("Token retrieved: \(token.prefix(10))...")
                }
            case "saveToken":
                if let token = params?["token"] as? String {
                    KeychainHelper.shared.saveToken(token)
                }
            case "deleteToken":
                KeychainHelper.shared.deleteToken()
            default:
                print("Unknown command: \(command)")
            }
        }
        
        func sendEventToJS(webView: WKWebView, event: String, data: [String: Any]) {
            let jsonData = try? JSONSerialization.data(withJSONObject: data)
            let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            
            let script = """
            window.dispatchEvent(new CustomEvent('native-\(event)', {
                detail: \(jsonString)
            }));
            """
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error sending event to JS: \(error)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView failed to load: \(error.localizedDescription)")
        }
    }
}
