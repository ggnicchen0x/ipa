import Foundation
import UIKit
import CommonCrypto
import Security

public final class AuthService: ObservableObject {
    public static let shared = AuthService()
    
    // Server Configuration - Live Bot Hosting Python egg URL
    // App Version - Official Release v1.1.4
    public let appVersion: String = "1.1.4"
    
    // Server Configuration - Live Bot Hosting Python egg URL
    public var serverBaseURL: String = "http://fi9.bot-hosting.cloud:25808"
    
    // Shared HMAC Secret (Matches backend config.py HMAC_SECRET)
    private let hmacSecret = "3105_HMAC_SIG_k9823hjd8923hjksdf78234"
    
    // Storage Keys (Keychain Accounts)
    private let tokenKey = "com.threeoneosfive.auth.session_token"
    private let savedLicenseKey = "com.threeoneosfive.auth.license_key"
    private let savedExpirationKey = "com.threeoneosfive.auth.expiration_date"
    private let lockoutUntilKey = "com.threeoneosfive.auth.lockout_until"
    private let keychainService = "com.apple.mobile.MobileHouseArrest.auth"
    
    @Published public var isAuthenticated: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var activeLicense: String = ""
    @Published public var expirationText: String = ""
    
    public var formattedExpirationText: String {
        guard !expirationText.isEmpty else { return "LIFETIME" }
        let trimmed = expirationText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.uppercased() == "LIFETIME" || trimmed.uppercased() == "NEVER" {
            return "LIFETIME"
        }
        
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        let inFormatter = DateFormatter()
        inFormatter.locale = Locale(identifier: "en_US_POSIX")
        inFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var parsedDate: Date? = nil
        for format in formats {
            inFormatter.dateFormat = format
            if let d = inFormatter.date(from: trimmed) {
                parsedDate = d
                break
            }
        }
        
        if parsedDate == nil {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            parsedDate = isoFormatter.date(from: trimmed) ?? ISO8601DateFormatter().date(from: trimmed)
        }
        
        guard let expDate = parsedDate else {
            if trimmed.count >= 10 && trimmed.contains("-") {
                return String(trimmed.prefix(10))
            }
            return trimmed
        }
        
        let outFormatter = DateFormatter()
        outFormatter.dateFormat = "yyyy-MM-dd"
        outFormatter.timeZone = TimeZone.current
        let dateString = outFormatter.string(from: expDate)
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: expDate))
        let daysLeft = components.day ?? 0
        
        if daysLeft < 0 {
            return "\(dateString) (Expired)"
        } else if daysLeft == 0 {
            return "\(dateString) (Expires Today)"
        } else if daysLeft == 1 {
            return "\(dateString) (1 Day)"
        } else {
            return "\(dateString) (\(daysLeft) Days)"
        }
    }
    
    // Spam Prevention & Lockout State (5 taps in 1 min -> 10 min timeout)
    @Published public var isLockedOut: Bool = false
    @Published public var lockoutSecondsRemaining: Int = 0
    
    // Online Update State (Driven dynamically from Web Admin)
    @Published public var updateDetected: Bool = false
    @Published public var updateTitle: String = "New Update Available"
    @Published public var updateMessage: String = ""
    @Published public var updateDownloadURL: String = "https://github.com/nicchen0xf/Swift-ios/releases"
    
    // Global Maintenance / Paused State
    @Published public var maintenanceDetected: Bool = false
    @Published public var maintenanceMessage: String = "Panel is Under Maintainance."
    
    private var heartbeatTimer: Timer?
    private var lockoutTimer: Timer?
    private var localAttemptTimestamps: [Date] = []
    
    private init() {
        checkSavedLockout()
        checkForUpdates()
        
        // Check for saved session in secure Keychain on launch
        if let token = loadKeychain(key: tokenKey), !token.isEmpty {
            self.activeLicense = loadKeychain(key: savedLicenseKey) ?? ""
            self.expirationText = loadKeychain(key: savedExpirationKey) ?? ""
            self.validateSessionSilently(token: token)
        }
    }
    
    // MARK: - Lockout Management
    private func checkSavedLockout() {
        let lockoutUntil = UserDefaults.standard.double(forKey: lockoutUntilKey)
        let now = Date().timeIntervalSince1970
        if lockoutUntil > now {
            startLockout(duration: Int(lockoutUntil - now))
        }
    }
    
    public func startLockout(duration: Int = 600) {
        let unlockTime = Date().timeIntervalSince1970 + Double(duration)
        UserDefaults.standard.set(unlockTime, forKey: lockoutUntilKey)
        
        DispatchQueue.main.async {
            self.isLockedOut = true
            self.lockoutSecondsRemaining = duration
            
            self.lockoutTimer?.invalidate()
            self.lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                if self.lockoutSecondsRemaining > 1 {
                    self.lockoutSecondsRemaining -= 1
                } else {
                    self.isLockedOut = false
                    self.lockoutSecondsRemaining = 0
                    UserDefaults.standard.removeObject(forKey: self.lockoutUntilKey)
                    timer.invalidate()
                    self.lockoutTimer = nil
                }
            }
        }
    }
    
    public var formattedLockoutTime: String {
        let minutes = lockoutSecondsRemaining / 60
        let seconds = lockoutSecondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Hardware ID Fingerprinting (Salted Multi-Layer Device Hash)
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
    
    public var savedLicenseKeyText: String {
        if let key = loadKeychain(key: savedLicenseKey), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return key.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let userDefKey = UserDefaults.standard.string(forKey: "saved_license_key"), !userDefKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return userDefKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return activeLicense.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Login Action
    public func login(licenseKey: String, completion: @escaping (Bool, String?) -> Void) {
        if isLockedOut {
            completion(false, "Spam detected: Do not repeatedly tap login. You are timed out. Please wait \(formattedLockoutTime).")
            return
        }
        
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        localAttemptTimestamps = localAttemptTimestamps.filter { $0 > oneMinuteAgo }
        localAttemptTimestamps.append(now)
        
        // If user tapped 5 times locally under 1 minute, enforce 10-minute timeout
        if localAttemptTimestamps.count >= 5 {
            startLockout(duration: 600)
            completion(false, "Spam detected: Do not repeatedly tap login. You have been timed out for 10 minutes. Please wait before retrying.")
            return
        }
        
        let cleanKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanKey.isEmpty else {
            completion(false, "Please enter a valid license key.")
            return
        }
        
        let hwid = self.hardwareID
        
        // Ensure hardware ECDSA key exists
        guard let privateKey = getOrCreateV2DeviceKey(),
              let pubKeyHex = getV2PublicKeyHex(privateKey: privateKey) else {
            completion(false, "Failed to initialize hardware cryptographic key.")
            return
        }
        
        guard let challengeURL = URL(string: "\(serverBaseURL)/api/v2/auth/challenge") else {
            completion(false, "Invalid server endpoint configuration.")
            return
        }
        
        DispatchQueue.main.async { self.isLoading = true }
        
        // Step 1: Fetch Challenge Nonce from Server
        let challengePayload: [String: Any] = [
            "device_hash": hwid,
            "client_version": self.appVersion
        ]
        
        guard let challengeData = try? JSONSerialization.data(withJSONObject: challengePayload) else {
            DispatchQueue.main.async { self.isLoading = false }
            completion(false, "Failed to encode challenge request.")
            return
        }
        
        var chalReq = URLRequest(url: challengeURL)
        chalReq.httpMethod = "POST"
        chalReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        chalReq.httpBody = challengeData
        chalReq.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: chalReq) { [weak self] cData, cResp, cErr in
            guard let self = self else { return }
            
            if let cErr = cErr {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false, "Challenge connection error: \(cErr.localizedDescription)")
                }
                return
            }
            
            guard let cHTTP = cResp as? HTTPURLResponse,
                  let cData = cData,
                  let chalJSON = (try? JSONSerialization.jsonObject(with: cData)) as? [String: Any],
                  let nonce = chalJSON["nonce"] as? String else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false, "Security gateway challenge failed. Please check server connection.")
                }
                return
            }
            
            // Step 2: Sign Canonical Context: V2-AUTH:{nonce}:{cleanKey}:{hwid}:{appVersion}
            let canonicalContext = "V2-AUTH:\(nonce):\(cleanKey):\(hwid):\(self.appVersion)"
            guard let signatureHex = self.signV2CanonicalMessage(privateKey: privateKey, canonicalMessage: canonicalContext) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false, "Hardware signature generation failed.")
                }
                return
            }
            
            guard let loginURL = URL(string: "\(self.serverBaseURL)/api/v2/auth/login") else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false, "Invalid login endpoint configuration.")
                }
                return
            }
            
            let requestBody: [String: Any] = [
                "license_key": cleanKey,
                "device_hash": hwid,
                "nonce": nonce,
                "device_public_key": pubKeyHex,
                "device_signature": signatureHex,
                "device_name": UIDevice.current.name,
                "device_model": self.deviceModelName(),
                "os_version": "iOS \(UIDevice.current.systemVersion)",
                "app_version": self.appVersion
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false, "Failed to encode login payload.")
                }
                return
            }
            
            var request = URLRequest(url: loginURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 12.0
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async { self.isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Connection error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Invalid response from security gateway.")
                }
                return
            }
            
            let responseData = data ?? Data()
            var parsedJSON: [String: Any]? = nil
            if let obj = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any] {
                parsedJSON = obj
            }
            
            // Success 200 OK
            if httpResponse.statusCode == 200, let json = parsedJSON, let success = json["success"] as? Bool, success {
                let token = json["token"] as? String ?? ""
                let expiresAt = json["expires_at"] as? String ?? "LIFETIME"
                
                DispatchQueue.main.async {
                    self.localAttemptTimestamps.removeAll()
                    self.saveKeychain(key: self.tokenKey, value: token)
                    self.saveKeychain(key: self.savedLicenseKey, value: cleanKey)
                    self.saveKeychain(key: self.savedExpirationKey, value: expiresAt)
                    UserDefaults.standard.set(cleanKey, forKey: "saved_license_key")
                    self.activeLicense = cleanKey
                    self.expirationText = expiresAt
                    self.isAuthenticated = true
                    self.startHeartbeatTimer()
                    completion(true, nil)
                }
                return
            }
            
            // Handle HTTP 426 Update Required
            if httpResponse.statusCode == 426 {
                var notes = ""
                var latestVer = ""
                var dUrl = "https://github.com/nicchen0xf/Swift-ios/releases"
                if let json = parsedJSON {
                    latestVer = json["latest_version"] as? String ?? ""
                    notes = json["release_notes"] as? String ?? (json["detail"] as? String ?? "")
                    dUrl = json["download_url"] as? String ?? "https://github.com/nicchen0xf/Swift-ios/releases"
                }
                if notes.isEmpty {
                    notes = "A new update is available. Please download the latest version."
                }
                let cleanNotes = notes
                let cleanVer = latestVer
                let cleanDUrl = dUrl
                DispatchQueue.main.async {
                    self.updateTitle = "New Update Available \(cleanVer.isEmpty ? "" : cleanVer)"
                    self.updateMessage = cleanNotes
                    self.updateDownloadURL = cleanDUrl
                    self.updateDetected = true
                    completion(false, "UPDATE_REQUIRED")
                }
                return
            }
            
            // Handle HTTP 503 Service Maintenance
            if httpResponse.statusCode == 503 {
                var maintMsg = "Panel is Under Maintainance."
                if let json = parsedJSON {
                    maintMsg = json["message"] as? String ?? (json["detail"] as? String ?? maintMsg)
                }
                let cleanMaint = maintMsg
                DispatchQueue.main.async {
                    self.maintenanceMessage = cleanMaint
                    self.maintenanceDetected = true
                    completion(false, cleanMaint)
                }
                return
            }
            
            // Extract detailed error message from JSON or Raw Response
            var errorMessage: String = ""
            if let json = parsedJSON {
                if let detail = json["detail"] as? String {
                    errorMessage = detail
                } else if let msg = json["message"] as? String {
                    errorMessage = msg
                } else if let err = json["error"] as? String {
                    errorMessage = err
                }
            }
            
            if errorMessage.isEmpty {
                if let rawString = String(data: responseData, encoding: .utf8), !rawString.isEmpty && rawString.count < 250 {
                    errorMessage = rawString
                } else if httpResponse.statusCode == 401 {
                    errorMessage = "Invalid license key provided."
                } else if httpResponse.statusCode == 409 {
                    errorMessage = "License key is locked to another device. Key sharing is prohibited."
                } else if httpResponse.statusCode == 403 {
                    errorMessage = "License key has been banned or revoked."
                } else if httpResponse.statusCode == 503 {
                    errorMessage = "Server maintenance is currently in progress. Please check Discord announcements."
                } else {
                    errorMessage = "Authentication failed (Server HTTP \(httpResponse.statusCode))."
                }
            }
            
            DispatchQueue.main.async {
                if httpResponse.statusCode == 429 {
                    self.startLockout(duration: 600)
                }
                completion(false, errorMessage)
            }
        }.resume()
        }.resume()
    }
    
    // MARK: - Online Version & Update Check
    public func checkForUpdates(completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "\(serverBaseURL)/api/v2/auth/version-check") else {
            completion?(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data else {
                completion?(false)
                return
            }
            if let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                // 1. Check Global Server Maintenance
                if let appStatus = json["app_status"] as? String, appStatus == "PAUSED" {
                    let msg = json["maintenance_message"] as? String ?? "Panel is Under Maintainance."
                    DispatchQueue.main.async {
                        self.maintenanceMessage = msg
                        self.maintenanceDetected = true
                        completion?(true)
                    }
                    return
                } else {
                    DispatchQueue.main.async {
                        self.maintenanceDetected = false
                    }
                }
                
                // 2. Check Version Update
                let latestVer = json["latest_version"] as? String ?? ""
                let forceUpdate = json["force_update"] as? Bool ?? false
                let releaseNotes = json["release_notes"] as? String ?? ""
                let downloadUrl = json["download_url"] as? String ?? "https://github.com/nicchen0xf/Swift-ios/releases"
                
                let isOlder = self.isClientVersionOlder(clientVer: self.appVersion, targetVer: latestVer)
                let isMismatch = (self.appVersion != latestVer)
                
                if (forceUpdate && isMismatch) || isOlder {
                    DispatchQueue.main.async {
                        self.updateTitle = "New Update Available \(latestVer.isEmpty ? "" : latestVer)"
                        self.updateMessage = releaseNotes.isEmpty ? "A new update is available. Please download the latest version." : releaseNotes
                        self.updateDownloadURL = downloadUrl.isEmpty ? "https://github.com/nicchen0xf/Swift-ios/releases" : downloadUrl
                        self.updateDetected = true
                        completion?(true)
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                completion?(false)
            }
        }.resume()
    }
    
    private func isClientVersionOlder(clientVer: String, targetVer: String) -> Bool {
        func parseVersion(_ v: String) -> [Int] {
            return v.replacingOccurrences(of: "v", with: "").split(separator: ".").compactMap { Int($0) }
        }
        let cParts = parseVersion(clientVer)
        let tParts = parseVersion(targetVer)
        let maxLen = max(cParts.count, tParts.count)
        for i in 0..<maxLen {
            let c = i < cParts.count ? cParts[i] : 0
            let t = i < tParts.count ? tParts[i] : 0
            if c < t { return true }
            if c > t { return false }
        }
        return false
    }
    
    // MARK: - Silent Session Validation (App Launch)
    private func validateSessionSilently(token: String) {
        guard let url = URL(string: "\(serverBaseURL)/api/v2/auth/validate") else { return }
        
        let hwid = self.hardwareID
        let timestamp = Int(Date().timeIntervalSince1970)
        let signaturePayload = "\(hwid):\(timestamp)"
        let signature = hmacSHA256(payload: signaturePayload, key: hmacSecret)
        
        let requestBody: [String: Any] = [
            "token": token,
            "device_hash": hwid,
            "app_version": self.appVersion,
            "timestamp": timestamp,
            "signature": signature
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 8.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 426 {
                var notes = ""
                var latestVer = ""
                var dUrl = "https://github.com/nicchen0xf/Swift-ios/releases"
                if let data = data, let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                    latestVer = json["latest_version"] as? String ?? ""
                    notes = json["release_notes"] as? String ?? (json["detail"] as? String ?? "")
                    dUrl = json["download_url"] as? String ?? "https://github.com/nicchen0xf/Swift-ios/releases"
                }
                let cleanNotes = notes.isEmpty ? "A new update is available. Please download the latest version." : notes
                let cleanVer = latestVer
                let cleanDUrl = dUrl
                DispatchQueue.main.async {
                    self.updateTitle = "New Update Available \(cleanVer.isEmpty ? "" : cleanVer)"
                    self.updateMessage = cleanNotes
                    self.updateDownloadURL = cleanDUrl
                    self.updateDetected = true
                    self.logout()
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 503 {
                var maintMsg = "Panel is Under Maintainance."
                if let data = data, let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                    maintMsg = json["message"] as? String ?? (json["detail"] as? String ?? maintMsg)
                }
                let cleanMaint = maintMsg
                DispatchQueue.main.async {
                    self.maintenanceMessage = cleanMaint
                    self.maintenanceDetected = true
                    self.logout()
                }
                return
            }
            
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
            guard let self = self, let token = self.loadKeychain(key: self.tokenKey), !token.isEmpty else { return }
            self.validateSessionSilently(token: token)
        }
    }
    
    // MARK: - Logout
    public func logout() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        deleteKeychain(key: tokenKey)
        deleteKeychain(key: savedLicenseKey)
        deleteKeychain(key: savedExpirationKey)
        UserDefaults.standard.removeObject(forKey: "saved_license_key")
        UserDefaults.standard.synchronize()
        self.isAuthenticated = false
        self.activeLicense = ""
        self.expirationText = ""
        CloudPatchService.shared.clearCache()
    }
    
    public var currentSessionToken: String {
        return loadKeychain(key: tokenKey) ?? ""
    }
    
    public var hmacSecretValue: String {
        return hmacSecret
    }
    
    // MARK: - Keychain Security Layer (kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
    private func saveKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            attributes.forEach { newItem[$0.key] = $0.value }
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }
    
    private func loadKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data, let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }
    
    private func deleteKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Protocol v2 Asymmetric Hardware Cryptography (ECDSA P-256)
    private let v2KeyTag = "com.threeoneosfive.auth.v2_device_key".data(using: .utf8)!
    
    public func getOrCreateV2DeviceKey() -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: v2KeyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let existingKey = item {
            return (existingKey as! SecKey)
        }
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: v2KeyTag,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
        ]
        var error: Unmanaged<CFError>?
        guard let newKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            return nil
        }
        return newKey
    }
    
    public func getV2PublicKeyHex(privateKey: SecKey) -> String? {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else { return nil }
        var error: Unmanaged<CFError>?
        guard let pubData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else { return nil }
        return pubData.map { String(format: "%02x", $0) }.joined()
    }
    
    public func signV2CanonicalMessage(privateKey: SecKey, canonicalMessage: String) -> String? {
        guard let messageData = canonicalMessage.data(using: .utf8) else { return nil }
        var error: Unmanaged<CFError>?
        guard let signatureData = SecKeyCreateSignature(privateKey, .ecdsaSignatureMessageX962SHA256, messageData as CFData, &error) as Data? else {
            return nil
        }
        return signatureData.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Cryptographic Utilities
    public func sha256(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public func hmacSHA256(payload: String, key: String) -> String {
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
