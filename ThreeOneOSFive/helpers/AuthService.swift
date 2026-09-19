import Foundation
import UIKit
import CommonCrypto
import Security

public final class AuthService: ObservableObject {
    public static let shared = AuthService()
    
    // Server Configuration - Live Bot Hosting Python egg URL
    public var serverBaseURL: String = "http://fi9.bot-hosting.cloud:25808"
    
    // Shared HMAC Secret (Matches backend config.py HMAC_SECRET)
    private let hmacSecret = "3105_HMAC_SIG_k9823hjd8923hjksdf78234"
    
    // Storage Keys
    private let tokenKey = "com.threeoneosfive.auth.session_token"
    private let savedLicenseKey = "com.threeoneosfive.auth.license_key"
    
    @Published public var isAuthenticated: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var activeLicense: String = ""
    @Published public var expirationText: String = ""
    
    private var heartbeatTimer: Timer?
    
    private init() {
        // Check for saved session on launch
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            self.activeLicense = UserDefaults.standard.string(forKey: savedLicenseKey) ?? ""
            self.validateSessionSilently(token: token)
        }
    }
    
    // MARK: - Hardware ID Fingerprinting (Non-Spoofable Multi-Layer Hash)
    public var hardwareID: String {
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? "00000000-0000-0000-0000-000000000000"
        let model = deviceModelName()
        let osVersion = UIDevice.current.systemVersion
        let systemName = UIDevice.current.systemName
        
        // Salted multi-identifier string
        let rawPayload = "\(idfv)::\(model)::\(systemName)_\(osVersion)::3105_SEC_KEY_e4b0546a57c844ddb94cdbd2e2393df1_PROD"
        return sha256(rawPayload)
    }
    
    public var deviceName: String {
        return UIDevice.current.name
    }
    
    public var deviceModel: String {
        return deviceModelName()
    }
    
    // MARK: - Login Action
    public func login(licenseKey: String, completion: @escaping (Bool, String?) -> Void) {
        let cleanKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            completion(false, "Please enter a valid license key.")
            return
        }
        
        guard let url = URL(string: "\(serverBaseURL)/api/v1/auth/login") else {
            completion(false, "Invalid server endpoint configuration.")
            return
        }
        
        let hwid = self.hardwareID
        let timestamp = Int(Date().timeIntervalSince1970)
        let signaturePayload = "\(cleanKey):\(hwid):\(timestamp)"
        let signature = hmacSHA256(payload: signaturePayload, key: hmacSecret)
        
        let requestBody: [String: Any] = [
            "license_key": cleanKey,
            "device_hash": hwid,
            "device_name": UIDevice.current.name,
            "device_model": deviceModelName(),
            "os_version": "iOS \(UIDevice.current.systemVersion)",
            "timestamp": timestamp,
            "signature": signature
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(false, "Failed to encode request payload.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 10.0
        
        DispatchQueue.main.async { self.isLoading = true }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Connection error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                DispatchQueue.main.async {
                    completion(false, "Invalid server response.")
                }
                return
            }
            
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                DispatchQueue.main.async {
                    completion(false, "Failed to parse server response.")
                }
                return
            }
            
            if httpResponse.statusCode == 200, let success = json["success"] as? Bool, success {
                let token = json["token"] as? String ?? ""
                let expiresAt = json["expires_at"] as? String ?? "LIFETIME"
                
                DispatchQueue.main.async {
                    UserDefaults.standard.set(token, forKey: self.tokenKey)
                    UserDefaults.standard.set(cleanKey, forKey: self.savedLicenseKey)
                    self.activeLicense = cleanKey
                    self.expirationText = expiresAt
                    self.isAuthenticated = true
                    self.startHeartbeatTimer()
                    completion(true, nil)
                }
            } else {
                let detail = json["detail"] as? String ?? "Authentication failed."
                DispatchQueue.main.async {
                    completion(false, detail)
                }
            }
        }.resume()
    }
    
    // MARK: - Silent Session Validation (App Launch)
    private func validateSessionSilently(token: String) {
        guard let url = URL(string: "\(serverBaseURL)/api/v1/auth/validate") else { return }
        
        let hwid = self.hardwareID
        let timestamp = Int(Date().timeIntervalSince1970)
        let signaturePayload = "\(hwid):\(timestamp)"
        let signature = hmacSHA256(payload: signaturePayload, key: hmacSecret)
        
        let requestBody: [String: Any] = [
            "token": token,
            "device_hash": hwid,
            "timestamp": timestamp,
            "signature": signature
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 8.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.logout()
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.startHeartbeatTimer()
            }
        }.resume()
    }
    
    // MARK: - Periodic Heartbeat
    private func startHeartbeatTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self, let token = UserDefaults.standard.string(forKey: self.tokenKey) else { return }
            self.validateSessionSilently(token: token)
        }
    }
    
    // MARK: - Logout
    public func logout() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: savedLicenseKey)
        self.isAuthenticated = false
        self.activeLicense = ""
        self.expirationText = ""
    }
    
    // MARK: - Cryptographic Utilities
    private func sha256(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func hmacSHA256(payload: String, key: String) -> String {
        guard let payloadData = payload.data(using: .utf8),
              let keyData = key.data(using: .utf8) else { return "" }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            payloadData.withUnsafeBytes { payloadBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                       keyBytes.baseAddress,
                       keyData.count,
                       payloadBytes.baseAddress,
                       payloadData.count,
                       &digest)
            }
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func deviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? "iPhone" : identifier
    }
}
