import Foundation
import UIKit

public struct SkinItem: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let imageName: String
    public let description: String
    public let patchFileName: String
    public let characterName: String
    
    public init(
        id: String,
        name: String,
        imageName: String,
        description: String,
        patchFileName: String,
        characterName: String
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.description = description
        self.patchFileName = patchFileName
        self.characterName = characterName
    }
}

public final class SkinPatchService: ObservableObject {
    public static let shared = SkinPatchService()
    
    @Published public var isProcessing: Bool = false
    @Published public var appliedSkinIDs: Set<String> = []
    
    private var cachedProjects: [String: PatchProject] = [:]
    private let lock = NSLock()
    private let storageKey = "applied_skin_ids_set"
    
    // Complete skin catalog (Ignis, Bunny, Spider, Gojo)
    public let skins: [SkinItem] = [
        SkinItem(
            id: "mod_ignis",
            name: "Mod Ignis",
            imageName: "mod_ignis",
            description: "Works on FF Max Ignis Character , Make sure character is download before applying",
            patchFileName: "Mod_Ignis.3105",
            characterName: "Ignis"
        ),
        SkinItem(
            id: "mod_bunny",
            name: "Mod Bunny",
            imageName: "mod_bunny",
            description: "Works on FF Max Ignis Character , Make sure character is download before applying",
            patchFileName: "Mod_Bunny.3105",
            characterName: "Ignis"
        ),
        SkinItem(
            id: "mod_spider",
            name: "Mod Spider",
            imageName: "mod_spider",
            description: "Works on FF Max Awakened Alok Character , Make sure character is download before applying",
            patchFileName: "Mod_Spider.3105",
            characterName: "Awakened Alok"
        ),
        SkinItem(
            id: "mod_gojo",
            name: "Mod Gojo",
            imageName: "mod_gojo",
            description: "Works on FF Max Awakened Alok Character , Make sure character is download before applying",
            patchFileName: "Mod_Gojo.3105",
            characterName: "Awakened Alok"
        )
    ]
    
    private init() {
        loadAppliedState()
    }
    
    private func loadAppliedState() {
        if let saved = UserDefaults.standard.array(forKey: storageKey) as? [String] {
            appliedSkinIDs = Set(saved)
        }
    }
    
    private func saveAppliedState() {
        UserDefaults.standard.set(Array(appliedSkinIDs), forKey: storageKey)
    }
    
    public func isApplied(skinID: String) -> Bool {
        appliedSkinIDs.contains(skinID)
    }
    
    public func applySkin(
        skin: SkinItem,
        targetBundle: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        let auth = AuthService.shared
        guard auth.isAuthenticated else {
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(false, "Authentication required. Please log in first.")
            }
            return
        }
        
        let token = auth.currentSessionToken
        guard !token.isEmpty else {
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(false, "Active session token missing. Please log in again.")
            }
            return
        }
        
        let hwid = auth.hardwareID
        let timestamp = Int(Date().timeIntervalSince1970)
        let normalizedKey = skin.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Anti-replay HMAC signature: feature_key:hwid:timestamp
        let sigPayload = "\(normalizedKey):\(hwid):\(timestamp)"
        let signature = auth.hmacSHA256(payload: sigPayload, key: auth.hmacSecretValue)
        
        guard let url = URL(string: "\(auth.serverBaseURL)/api/v2/patches/fetch") else {
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(false, "Invalid patch delivery endpoint configuration.")
            }
            return
        }
        
        let requestBody: [String: Any] = [
            "feature_name": normalizedKey,
            "token": token,
            "device_hash": hwid,
            "timestamp": timestamp,
            "signature": signature,
            "app_version": auth.appVersion
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(false, "Failed to serialize patch request.")
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse {
                // 1. Handle HTTP 426 Force Update
                if httpResponse.statusCode == 426 {
                    var notes = "A new update is available. Please download the latest version."
                    var latestVer = ""
                    var dUrl = "https://github.com/nicchen0xf/Swift-ios/releases"
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        latestVer = json["latest_version"] as? String ?? ""
                        notes = json["release_notes"] as? String ?? (json["detail"] as? String ?? notes)
                        dUrl = json["download_url"] as? String ?? dUrl
                    }
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        auth.updateTitle = "New Update Available \(latestVer.isEmpty ? "" : latestVer)"
                        auth.updateMessage = notes
                        auth.updateDownloadURL = dUrl
                        auth.updateDetected = true
                        completion(false, "UPDATE_REQUIRED: \(notes)")
                    }
                    return
                }
                
                // 2. Handle HTTP 503 Maintenance
                if httpResponse.statusCode == 503 {
                    var maintMsg = "Panel is Under Maintainance."
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        maintMsg = json["message"] as? String ?? (json["detail"] as? String ?? maintMsg)
                    }
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        auth.maintenanceMessage = maintMsg
                        auth.maintenanceDetected = true
                        completion(false, maintMsg)
                    }
                    return
                }
                
                // 3. Handle Key or Session Invalidation (401 / 403)
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    var errMsg = "Unauthorized: Invalid session or license key."
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let detail = json["detail"] as? String {
                        errMsg = detail
                    }
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        auth.logout()
                        completion(false, errMsg)
                    }
                    return
                }
            }
            
            // If backend request succeeds with 200 and binary data, use backend payload.
            // Otherwise, fallback to local bundle if available.
            var patchDataToApply: Data? = nil
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data, !data.isEmpty {
                patchDataToApply = data
            } else {
                // Fallback to local bundle
                patchDataToApply = self.loadPatchData(filename: skin.patchFileName)
            }
            
            guard let patchData = patchDataToApply else {
                let errorMsg: String
                if let error = error {
                    errorMsg = "Backend delivery failed: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    errorMsg = "Server rejected patch delivery (HTTP \(httpResponse.statusCode))."
                } else {
                    errorMsg = "Skin patch package '\(skin.patchFileName)' could not be retrieved."
                }
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion(false, errorMsg)
                }
                return
            }
            
            // Decode the .3105 package
            do {
                let package: DecodedPatchPackage
                if let decoded = try? PatchPackageCodec.decode(patchData, password: nil) {
                    package = decoded
                } else if let decodedOG = try? PatchPackageCodec.decode(patchData, password: "OG") {
                    package = decodedOG
                } else {
                    package = try PatchPackageCodec.decode(patchData, password: nil)
                }
                
                var adaptedProject = package.project
                adaptedProject.bundleIdentifiers = [targetBundle]
                
                var seenDirs = Set<String>()
                adaptedProject.directories = package.project.directories
                    .map { dir in
                        var d = dir
                        d.bundleID = targetBundle
                        return d
                    }
                    .filter { seenDirs.insert($0.relativePath).inserted }
                
                var seenRules = Set<String>()
                adaptedProject.rules = package.project.rules
                    .map { rule in
                        var r = rule
                        r.bundleID = targetBundle
                        return r
                    }
                    .filter { seenRules.insert($0.relativePath).inserted }
                
                // Revert any previous receipt for this project
                if let existingReceipt = DevicePatchService.latestReceipt(projectID: adaptedProject.id) {
                    try? DevicePatchService.restore(receipt: existingReceipt, allowChangedTargets: true)
                }
                
                // Apply patch to game container
                _ = try DevicePatchService.apply(project: adaptedProject)
                
                self.lock.lock()
                self.cachedProjects[skin.id] = adaptedProject
                self.lock.unlock()
                
                DispatchQueue.main.async {
                    self.appliedSkinIDs.insert(skin.id)
                    self.saveAppliedState()
                    self.isProcessing = false
                    completion(true, "Applied \(skin.name) successfully!")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    let errMsg = ErrorSanitizer.sanitize(error.localizedDescription)
                    completion(false, "Failed to apply skin: \(errMsg)")
                }
            }
        }.resume()
    }
    
    public func removeSkin(
        skin: SkinItem,
        targetBundle: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.lock.lock()
            let project = self.cachedProjects[skin.id]
            self.lock.unlock()
            
            // Try to find receipt by project ID
            if let project = project, let receipt = DevicePatchService.latestReceipt(projectID: project.id) {
                do {
                    try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
                    DispatchQueue.main.async {
                        self.appliedSkinIDs.remove(skin.id)
                        self.saveAppliedState()
                        self.isProcessing = false
                        completion(true, "\(skin.name) removed successfully.")
                    }
                    return
                } catch {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        let errMsg = ErrorSanitizer.sanitize(error.localizedDescription)
                        completion(false, "Restore failed: \(errMsg)")
                    }
                    return
                }
            }
            
            // If project not cached, attempt to decode and find receipt
            if let patchData = self.loadPatchData(filename: skin.patchFileName) {
                if let package = (try? PatchPackageCodec.decode(patchData, password: nil)) ?? (try? PatchPackageCodec.decode(patchData, password: "OG")) {
                    if let receipt = DevicePatchService.latestReceipt(projectID: package.project.id) {
                        do {
                            try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
                            DispatchQueue.main.async {
                                self.appliedSkinIDs.remove(skin.id)
                                self.saveAppliedState()
                                self.isProcessing = false
                                completion(true, "\(skin.name) removed successfully.")
                            }
                            return
                        } catch {
                            DispatchQueue.main.async {
                                self.isProcessing = false
                                let errMsg = ErrorSanitizer.sanitize(error.localizedDescription)
                                completion(false, "Restore failed: \(errMsg)")
                            }
                            return
                        }
                    }
                }
            }
            
            // Fallback: update state
            DispatchQueue.main.async {
                self.appliedSkinIDs.remove(skin.id)
                self.saveAppliedState()
                self.isProcessing = false
                completion(true, "\(skin.name) set to removed.")
            }
        }
    }
    
    private func loadPatchData(filename: String) -> Data? {
        let nameWithoutExt = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        
        // 1. Check main bundle for resource
        if let url = Bundle.main.url(forResource: nameWithoutExt, withExtension: ext) {
            if let data = try? Data(contentsOf: url) {
                return data
            }
        }
        
        // 2. Check subdirectory skins in main bundle
        if let url = Bundle.main.url(forResource: nameWithoutExt, withExtension: ext, subdirectory: "skins") {
            if let data = try? Data(contentsOf: url) {
                return data
            }
        }
        
        // 3. Direct bundle path
        let bundlePath = Bundle.main.bundlePath
        let directUrl = URL(fileURLWithPath: bundlePath).appendingPathComponent("skins").appendingPathComponent(filename)
        if let data = try? Data(contentsOf: directUrl) {
            return data
        }
        
        // 4. Check root bundle path
        let rootBundleUrl = URL(fileURLWithPath: bundlePath).appendingPathComponent(filename)
        if let data = try? Data(contentsOf: rootBundleUrl) {
            return data
        }
        
        return nil
    }
}
