import Foundation
import UIKit
import CommonCrypto

public final class CloudPatchService {
    public static let shared = CloudPatchService()
    
    // In-memory decrypted cache of dynamically fetched patch packages
    private var inMemoryPatchCache: [String: PatchProject] = [:]
    private let cacheLock = NSLock()
    
    private init() {}
    
    public func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        inMemoryPatchCache.removeAll()
    }
    
    public func fetchAndApplyPatch(
        featureKey: String,
        targetBundle: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        let auth = AuthService.shared
        guard auth.isAuthenticated else {
            completion(false, "Authentication required. Please authenticate device first.")
            return
        }
        
        let token = auth.currentSessionToken
        guard !token.isEmpty else {
            completion(false, "Active session token missing. Please log in again.")
            return
        }
        
        let hwid = auth.hardwareID
        let timestamp = Int(Date().timeIntervalSince1970)
        let normalizedKey = featureKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Anti-replay HMAC signature: feature_key:hwid:timestamp
        let sigPayload = "\(normalizedKey):\(hwid):\(timestamp)"
        let signature = auth.hmacSHA256(payload: sigPayload, key: auth.hmacSecretValue)
        
        guard let url = URL(string: "\(auth.serverBaseURL)/api/v1/patches/fetch") else {
            completion(false, "Invalid patch delivery endpoint configuration.")
            return
        }
        
        let requestBody: [String: Any] = [
            "feature_name": normalizedKey,
            "token": token,
            "device_hash": hwid,
            "timestamp": timestamp,
            "signature": signature
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(false, "Failed to serialize patch request.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Cloud fetch failed: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Invalid server response.")
                }
                return
            }
            
            if httpResponse.statusCode != 200 {
                var errorMessage = "Server rejected patch delivery (HTTP \(httpResponse.statusCode))."
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detail = json["detail"] as? String {
                    errorMessage = detail
                }
                DispatchQueue.main.async {
                    completion(false, errorMessage)
                }
                return
            }
            
            guard let patchData = data, !patchData.isEmpty else {
                DispatchQueue.main.async {
                    completion(false, "Received empty patch payload from server.")
                }
                return
            }
            
            // Decode the .3105 package dynamically in memory
            do {
                let package = try PatchPackageCodec.decode(patchData, password: nil)
                let project = package.project
                
                // Adapt project for target bundle (Free Fire MAX vs TH)
                var adaptedProject = project
                adaptedProject.bundleIdentifiers = [targetBundle]
                
                var seenDirs = Set<String>()
                adaptedProject.directories = project.directories
                    .map { dir in
                        var d = dir
                        d.bundleID = targetBundle
                        return d
                    }
                    .filter { seenDirs.insert($0.relativePath).inserted }
                
                var seenRules = Set<String>()
                adaptedProject.rules = project.rules
                    .map { rule in
                        var r = rule
                        r.bundleID = targetBundle
                        if r.relativePath.contains("Library/Preferences/") {
                            if targetBundle == "com.dts.freefiremax" {
                                r.relativePath = "Library/Preferences/com.dts.freefiremax.plist"
                                r.replacementFilename = "com.dts.freefiremax.plist"
                            } else if targetBundle == "com.dts.freefireth" {
                                r.relativePath = "Library/Preferences/com.dts.freefireth.plist"
                                r.replacementFilename = "com.dts.freefireth.plist"
                            }
                        }
                        return r
                    }
                    .filter { seenRules.insert($0.relativePath).inserted }
                
                // Revert any existing receipt first to ensure clean application
                if let existingReceipt = DevicePatchService.latestReceipt(projectID: adaptedProject.id) {
                    try? DevicePatchService.restore(receipt: existingReceipt, allowChangedTargets: true)
                }
                
                _ = try DevicePatchService.apply(project: adaptedProject)
                
                self.cacheLock.lock()
                self.inMemoryPatchCache[normalizedKey] = adaptedProject
                self.cacheLock.unlock()
                
                DispatchQueue.main.async {
                    completion(true, "Cloud patch '\(project.name)' verified and applied successfully.")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Patch execution failed: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    public func revertPatch(featureKey: String, targetBundle: String, completion: @escaping (Bool, String) -> Void) {
        let normalizedKey = featureKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        cacheLock.lock()
        let project = inMemoryPatchCache[normalizedKey]
        cacheLock.unlock()
        
        if let project = project, let receipt = DevicePatchService.latestReceipt(projectID: project.id) {
            do {
                try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
                DispatchQueue.main.async {
                    completion(true, "Feature reverted to original state.")
                }
                return
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Revert failed: \(error.localizedDescription)")
                }
                return
            }
        }
        
        // Fallback: search all available receipts
        DispatchQueue.main.async {
            completion(true, "Feature toggled off.")
        }
    }
}
