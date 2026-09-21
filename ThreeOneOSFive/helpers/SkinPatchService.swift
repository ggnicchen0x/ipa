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
    
    // Initial skin catalog - starting with Mod Ignis layout
    public let skins: [SkinItem] = [
        SkinItem(
            id: "mod_ignis",
            name: "Mod Ignis",
            imageName: "mod_ignis",
            description: "Works on FF Max Ignis Character , Make sure character is download before applying",
            patchFileName: "Mod_Ignis.3105",
            characterName: "Ignis"
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
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 1. Locate the .3105 file in app bundle or skins folder
            guard let patchData = self.loadPatchData(filename: skin.patchFileName) else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion(false, "Skin patch package '\(skin.patchFileName)' could not be found.")
                }
                return
            }
            
            // 2. Decode the .3105 package
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
                    completion(false, "Failed to apply skin: \(error.localizedDescription)")
                }
            }
        }
    }
    
    public func removeSkin(
        skin: SkinItem,
        targetBundle: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        isProcessing = true
        
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
                        completion(false, "Restore failed: \(error.localizedDescription)")
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
                                completion(false, "Restore failed: \(error.localizedDescription)")
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
