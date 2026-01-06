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

    private var token: String? {
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

    // Configure this with your OAuth client id (GitHub app). The client id is read from Info.plist key `CopilotClientID`.
    private var clientId: String {
        if let id = Bundle.main.object(forInfoDictionaryKey: "CopilotClientID") as? String {
            return id
        }
        return ""
    }

    private init() {
        self.isAuthenticated = (KeychainHelper.shared.getToken() != nil)
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
        let body = "client_id=\(clientId)"
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
                // Begin polling
                self.pollForToken()
            }
        }.resume()
    }

    private func pollForToken() {
        guard let deviceCode = deviceCode, !clientId.isEmpty else { return }
        polling = true
        lastError = nil

        // Poll every 5 seconds (or use interval from response if present)
        pollingCancellable = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.pollOnce(deviceCode: deviceCode)
            }
    }

    private func pollOnce(deviceCode: String) {
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
                    // could increase polling interval
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
    }

    // Fetch Copilot usage - placeholder implementation
    func fetchUsage() {
        guard let token = token else { return }
        // Replace the URL below with the correct Copilot usage endpoint you want to query.
        guard let url = URL(string: "https://api.github.com/user") else { return }
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { self.lastError = error.localizedDescription }
                return
            }
            // Demo fetch: just set a dummy percentage for now
            DispatchQueue.main.async {
                self.usagePercentage = 0.35
            }
        }.resume()
    }
}
