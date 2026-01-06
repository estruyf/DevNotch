//
//  CopilotClient.swift
//  DevNotch
//
//  Created on 2026-01-06.
//

import Foundation
import Combine

/// Copilot device flow + usage client (basic, configurable)
/// NOTE: Replace `clientId` with your GitHub OAuth app client id that supports device flow,
/// or provide it via configuration. The Copilot usage endpoint may be internal — adapt
/// `fetchUsage()` to the correct endpoint you need (this is a placeholder pattern).
final class CopilotClient: ObservableObject {
    static let shared = CopilotClient()

    // Device flow state
    @Published var isAuthenticated: Bool = false
    @Published var userCode: String? = nil
    @Published var verificationUri: String? = nil
    @Published var deviceCode: String? = nil
    @Published var expiresAt: Date? = nil
    @Published var polling: Bool = false

    // Usage
    @Published var usagePercentage: Double? = nil
    @Published var lastError: String? = nil
    @Published var copilotRemaining: Int? = nil
    @Published var copilotTotal: Int? = nil
    @Published var username: String? = nil

    var token: String? {
        get { KeychainHelper.shared.getToken() }
        set {
            if let v = newValue { KeychainHelper.shared.saveToken(v) }
            else { KeychainHelper.shared.deleteToken() }
            DispatchQueue.main.async { [weak self] in
                self?.isAuthenticated = (KeychainHelper.shared.getToken() != nil)
            }
        }
    }

    private var pollingCancellable: AnyCancellable?

    private var clientId: String {
        return "Iv1.b507a08c87ecfe98"
    }

    private init() {
        self.isAuthenticated = (KeychainHelper.shared.getToken() != nil)
        
        // If already authenticated, fetch usage immediately on app startup
        if self.isAuthenticated {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchUsage()
            }
        }
    }

    func resetAuthFlow() {
        self.polling = false
        self.pollingCancellable?.cancel()
        self.pollingCancellable = nil
        self.deviceCode = nil
        self.userCode = nil
        self.verificationUri = nil
        self.expiresAt = nil
        self.lastError = nil
    }
    
    func manualTokenAuth(_ manualToken: String) {
        // Basic validation or sanitization
        let cleaned = manualToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleaned.isEmpty {
            self.token = cleaned
            self.fetchUsage()
        }
    }
    
    // Starts device flow
    func startDeviceFlow() {
        guard !clientId.isEmpty else {
            lastError = "Client ID not configured"
            return
        }

        let url = URL(string: "https://github.com/login/device/code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body = "client_id=\(clientId)&scope=read:email"
        request.httpBody = body.data(using: .utf8)

        polling = false
        lastError = nil

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { self.lastError = error.localizedDescription }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { self.lastError = "Invalid response" }
                return
            }

            DispatchQueue.main.async {
                self.userCode = json["user_code"] as? String
                self.deviceCode = json["device_code"] as? String
                self.verificationUri = json["verification_uri"] as? String ?? json["verification_uri_complete"] as? String
                if let expiresIn = json["expires_in"] as? Double {
                    self.expiresAt = Date().addingTimeInterval(expiresIn)
                }
                
                let interval = json["interval"] as? Double ?? 5.0
                // Begin polling
                self.pollForToken(interval: interval)
            }
        }.resume()
    }

    private func pollForToken(interval: Double) {
        guard let deviceCode = deviceCode, !clientId.isEmpty else { return }
        polling = true
        lastError = nil

        // Poll using the intervals
        pollingCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.pollOnce(deviceCode: deviceCode, currentInterval: interval)
            }
    }

    private func pollOnce(deviceCode: String, currentInterval: Double) {
        let url = URL(string: "https://github.com/login/oauth/access_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "client_id=\(clientId)&device_code=\(deviceCode)&grant_type=urn:ietf:params:oauth:grant-type:device_code"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { self.lastError = error.localizedDescription }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { self.lastError = "Invalid token response" }
                return
            }

            if let accessToken = json["access_token"] as? String {
                DispatchQueue.main.async {
                    self.token = accessToken
                    self.polling = false
                    self.pollingCancellable?.cancel()
                    self.pollingCancellable = nil
                    self.deviceCode = nil
                    self.userCode = nil
                    self.verificationUri = nil
                    self.fetchUsage()
                }
            } else if let errorDesc = json["error"] as? String {
                // Keep polling until user completes auth or error indicates otherwise
                if errorDesc == "authorization_pending" {
                    // continue
                } else if errorDesc == "slow_down" {
                    // Increase polling interval by 5 seconds
                    DispatchQueue.main.async {
                        self.pollingCancellable?.cancel()
                        self.pollForToken(interval: currentInterval + 5.0)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.lastError = errorDesc
                        self.polling = false
                        self.pollingCancellable?.cancel()
                        self.pollingCancellable = nil
                    }
                }
            }
        }.resume()
    }

    func signOut() {
        token = nil
        usagePercentage = nil
        username = nil
        copilotRemaining = nil
        copilotTotal = nil
        resetAuthFlow()
    }

    // Fetch Copilot usage - placeholder implementation
    func fetchUsage() {
        guard let token = token else { return }
        // Use the Copilot internal endpoint for usage data
        guard let url = URL(string: "https://api.github.com/copilot_internal/user") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("GitHub-Copilot-Usage-Tray", forHTTPHeaderField: "User-Agent")
        request.setValue("2025-05-01", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { self.lastError = error.localizedDescription }
                return
            }
            // Logic to parse usage would go here. For now we just confirm the fetch succeeded
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                     
                     // Extract username if available
                     if let login = json["login"] as? String {
                         self.username = login
                     }
                 DispatchQueue.main.async {
                     // Check quota_snapshots -> premium_interactions
                     if let snapshots = json["quota_snapshots"] as? [String: Any],
                    let premium = snapshots["premium_interactions"] as? [String: Any] {
                    
                        var total: Int? = nil
                        var remaining: Int? = nil

                        if let e = premium["entitlement"] as? Int {
                            total = e
                        } else if let e = premium["entitlement"] as? Double {
                            total = Int(e)
                        } else if let e = premium["entitlement"] as? String {
                            total = Int(e)
                        }

                        if let r = premium["remaining"] as? Int {
                            remaining = r
                        } else if let r = premium["quota_remaining"] as? Int {
                            remaining = r
                        } else if let r = premium["remaining"] as? Double {
                            remaining = Int(r)
                        } else if let r = premium["quota_remaining"] as? Double {
                            remaining = Int(r)
                        } else if let r = premium["remaining"] as? String {
                            remaining = Int(r)
                        } else if let r = premium["quota_remaining"] as? String {
                            remaining = Int(r)
                        }

                        DispatchQueue.main.async {
                            self.copilotTotal = total
                            self.copilotRemaining = remaining
                            if let t = total, let rem = remaining, t > 0 {
                                // progress should count down: remaining/total
                                self.usagePercentage = Double(rem) / Double(t)
                            }
                        }
                     }
                 }
            }
        }.resume()
    }
}
