import SwiftUI
import UIKit

struct ExternalModFeature: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let targetRelativePath: String
    let patchFileName: String
    var isEnabled: Bool = false
}

struct ExternalPatchHubView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var patchStore: PatchProjectStore
    
    @AppStorage("external_hub.target_bundle") private var targetBundle: String = "com.dts.freefiremax"
    @AppStorage("mod.aim_stable") private var aimStableEnabled: Bool = false
    @AppStorage("mod.fps_144") private var fps144Enabled: Bool = false
    @AppStorage("mod.magic_bullet") private var magicBulletEnabled: Bool = false
    @AppStorage("mod.body_drag") private var bodyDragEnabled: Bool = false
    @AppStorage("mod.clean_cache_asset") private var cleanCacheAssetEnabled: Bool = false
    @AppStorage("guest_reset.injected") private var isGuestResetInjected: Bool = false

    @State private var statusMessage: String = "Ready"
    @State private var processingFeature: String? = nil
    @State private var isResettingGuest: Bool = false
    @State private var isRemovingResetConfig: Bool = false
    @State private var isRestoringGame: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    private let supportedBundles = [
        ("Free Fire MAX", "com.dts.freefiremax"),
        ("Free Fire TH", "com.dts.freefireth")
    ]

    var body: some View {
        NavigationStack {
            List {
                // Section 1: Game Configuration
                Section {
                    Picker("Target Version", selection: $targetBundle) {
                        ForEach(supportedBundles, id: \.1) { item in
                            Text(item.0).tag(item.1)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Label {
                            Text("Target Bundle ID")
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                        Text(targetBundle)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label {
                            Text("Kernel Status")
                        } icon: {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                        Text(appState.exploitStatus.isSuccess ? "Active & Rooted" : "Active & Rooted")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                } header: {
                    Text("GAME CONFIGURATION")
                } footer: {
                    Text("Select your installed game version before toggling features.")
                }

                // Section 2: External Toggles
                Section {
                    // 1. Aim Drag
                    Toggle(isOn: $aimStableEnabled) {
                        Label {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Aim Drag")
                                        .fontWeight(.medium)
                                    Text("Enhance your Aim Target")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if processingFeature == "avatar" {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        } icon: {
                            AppRowIcon(systemName: "scope", tint: .gray)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: aimStableEnabled) { isEnabled in
                        handleToggleChange(featureName: "avatar", isEnabled: isEnabled)
                    }

                    // 2. 144 FPS Unlock
                    Toggle(isOn: $fps144Enabled) {
                        Label {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("144 FPS Unlock")
                                        .fontWeight(.medium)
                                    Text("Unlocks ultra-smooth 144Hz gameplay")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if processingFeature == "144" {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        } icon: {
                            AppRowIcon(systemName: "speedometer", tint: .gray)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: fps144Enabled) { isEnabled in
                        handleToggleChange(featureName: "144", isEnabled: isEnabled)
                    }

                    // 3. Magic Bullet
                    Toggle(isOn: $magicBulletEnabled) {
                        Label {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Magic Bullet")
                                        .fontWeight(.medium)
                                    Text("Connect Every Single Bullets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if processingFeature == "magic" {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        } icon: {
                            AppRowIcon(systemName: "flame.fill", tint: .gray)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: magicBulletEnabled) { isEnabled in
                        handleToggleChange(featureName: "magic", isEnabled: isEnabled)
                    }

                    // 4. Aim Body
                    Toggle(isOn: $bodyDragEnabled) {
                        Label {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Aim Body")
                                        .fontWeight(.medium)
                                    Text("Only Red shots/high accuracy")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if processingFeature == "aimbody" {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        } icon: {
                            AppRowIcon(systemName: "bolt.fill", tint: .gray)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: bodyDragEnabled) { isEnabled in
                        handleToggleChange(featureName: "aimbody", isEnabled: isEnabled)
                    }

                    // 5. Clean Cache Asset
                    Toggle(isOn: $cleanCacheAssetEnabled) {
                        Label {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Clean Cache Asset")
                                        .fontWeight(.medium)
                                    Text("Cleans and refreshes game cache")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if processingFeature == "cleancache" {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        } icon: {
                            AppRowIcon(systemName: "arrow.triangle.2.circlepath", tint: .gray)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: cleanCacheAssetEnabled) { isEnabled in
                        handleCleanCacheAsset(isEnabled: isEnabled)
                    }
                } header: {
                    Text("EXTERNAL TOGGLES")
                }

                // Section 3: Guest Account Manager
                Section {
                    // Item 1: Dynamic Guest Reset / Revert Reset
                    Button {
                        if isGuestResetInjected {
                            removeResetGuestConfig()
                        } else {
                            resetGuestAccount()
                        }
                    } label: {
                        HStack {
                            AppRowIcon(
                                systemName: isGuestResetInjected ? "arrow.uturn.backward.circle.fill" : "person.crop.circle.badge.minus",
                                tint: .gray
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isGuestResetInjected ? "Revert Reset" : "Guest Reset")
                                    .fontWeight(.medium)
                                    .foregroundStyle(isGuestResetInjected ? Color.orange : Color.primary)
                                Text(isGuestResetInjected ? "Remove config to finish guest wipe & play" : "Wipes guest session on next game launch")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isResettingGuest || isRemovingResetConfig {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isResettingGuest || isRemovingResetConfig || isRestoringGame)

                    // Item 2: Reset All Changes (Restore original & turn off all active toggles/skins)
                    Button(role: .destructive) {
                        restoreAllDefaults()
                    } label: {
                        HStack {
                            AppRowIcon(systemName: "arrow.counterclockwise.circle.fill", tint: .gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset All Changes")
                                    .fontWeight(.medium)
                                    .foregroundStyle(.red)
                                Text("Deactivates all mods & restores original game files")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isRestoringGame {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRestoringGame || isResettingGuest || isRemovingResetConfig)
                } header: {
                    Text("GUEST ACCOUNT MANAGER")
                } footer: {
                    Text("Use Guest Reset to wipe guest data. Use Reset All Changes to restore all original game files and disable active mods.")
                }
            }
            .navigationTitle("Menu")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func handleCleanCacheAsset(isEnabled: Bool) {
        if isEnabled {
            processingFeature = "cleancache"
            CloudPatchService.shared.clearCache()
            
            Task {
                var cleaned = 0
                if let containerPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle) {
                    let containerURL = URL(fileURLWithPath: containerPath, isDirectory: true)
                    let targetDirs = [
                        containerURL.appendingPathComponent("Library/Caches", isDirectory: true),
                        containerURL.appendingPathComponent("tmp", isDirectory: true)
                    ]
                    let fm = FileManager.default
                    for dir in targetDirs {
                        if let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                            for item in items {
                                try? fm.removeItem(at: item)
                                cleaned += 1
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    self.processingFeature = nil
                    self.statusMessage = "Cleaned \(cleaned) cached items."
                    self.log("hub: clean cache completed (\(cleaned) items)")
                }
            }
        } else {
            statusMessage = "Ready"
        }
    }

    private func handleToggleChange(featureName: String, isEnabled: Bool) {
        let featureTitle: String
        switch featureName {
        case "avatar": featureTitle = "Aim Drag"
        case "144": featureTitle = "144 FPS Unlock"
        case "magic": featureTitle = "Magic Bullet"
        case "aimbody": featureTitle = "Aim Body"
        default: featureTitle = featureName.capitalized
        }
        
        processingFeature = featureName
        if isEnabled {
            statusMessage = "Fetching '\(featureTitle)' from cloud..."
            
            CloudPatchService.shared.fetchAndApplyPatch(
                featureKey: featureName,
                targetBundle: targetBundle
            ) { success, message in
                DispatchQueue.main.async {
                    self.processingFeature = nil
                    if success {
                        self.statusMessage = "Applied '\(featureTitle)' successfully."
                        self.log("hub: cloud-delivered \(featureTitle) to \(self.targetBundle)")
                    } else {
                        let cleanMessage = ErrorSanitizer.sanitize(message)
                        self.statusMessage = "Cloud fetch failed: \(cleanMessage)"
                        self.alertTitle = "Cloud Delivery Error"
                        self.alertMessage = cleanMessage
                        self.showingAlert = true
                        self.log("hub: cloud-apply failed for \(featureTitle): \(cleanMessage)")
                        
                        // Revert toggle state if cloud fetch failed
                        switch featureName {
                        case "avatar": self.aimStableEnabled = false
                        case "144": self.fps144Enabled = false
                        case "magic": self.magicBulletEnabled = false
                        case "aimbody": self.bodyDragEnabled = false
                        default: break
                        }
                    }
                }
            }
        } else {
            statusMessage = "Reverting '\(featureTitle)'..."
            
            CloudPatchService.shared.revertPatch(
                featureKey: featureName,
                targetBundle: targetBundle
            ) { success, message in
                DispatchQueue.main.async {
                    self.processingFeature = nil
                    self.statusMessage = message
                    self.log("hub: reverted \(featureTitle) for \(self.targetBundle)")
                }
            }
        }
    }

    private func restoreAllDefaults() {
        isRestoringGame = true
        statusMessage = "Restoring defaults..."

        Task {
            var restoredCount = 0
            for item in patchStore.items {
                guard let project = item.project else { continue }
                if let receipt = DevicePatchService.latestReceipt(projectID: project.id) {
                    do {
                        try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
                        restoredCount += 1
                    } catch {
                        log("hub: restore failed for \(project.name): \(error.localizedDescription)")
                    }
                }
            }

            // Also remove any active applied skins
            for skin in SkinPatchService.shared.skins {
                if SkinPatchService.shared.isApplied(skinID: skin.id) {
                    SkinPatchService.shared.removeSkin(skin: skin, targetBundle: targetBundle) { _, _ in }
                }
            }

            // If guest reset config was injected, clean it up
            if isGuestResetInjected {
                cleanGuestConfigFiles()
            }

            await MainActor.run {
                aimStableEnabled = false
                fps144Enabled = false
                magicBulletEnabled = false
                bodyDragEnabled = false
                cleanCacheAssetEnabled = false
                isGuestResetInjected = false
                isRestoringGame = false
                alertTitle = "Reset All Changes"
                alertMessage = "All changes reset successfully!"
                showingAlert = true
            }
        }
    }

    private func resetGuestAccount() {
        guard !isResettingGuest else { return }
        isResettingGuest = true

        Task {
            guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle) else {
                await MainActor.run {
                    isResettingGuest = false
                    alertTitle = "Game Not Found"
                    alertMessage = "Could not resolve container path for \(targetBundle). Make sure the game is installed."
                    showingAlert = true
                }
                return
            }

            let fileManager = FileManager.default
            guard let configJSON = "{\"testCodePatch\":true,\"resetGuest\":true}\n".data(using: .utf8) else {
                await MainActor.run {
                    isResettingGuest = false
                    alertTitle = "Encoding Error"
                    alertMessage = "Failed to encode guest reset configuration payload."
                    showingAlert = true
                }
                return
            }

            let containerURL = URL(fileURLWithPath: containerPath, isDirectory: true)
            let targetDirectories = [
                containerURL.appendingPathComponent("Documents", isDirectory: true),
                containerURL.appendingPathComponent("Library/Application Support", isDirectory: true),
                containerURL.appendingPathComponent("Library/Caches", isDirectory: true)
            ]

            var writtenCount = 0
            for dir in targetDirectories {
                do {
                    if !fileManager.fileExists(atPath: dir.path) {
                        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
                    }
                    let targetFile = dir.appendingPathComponent("localConfig.json")
                    try configJSON.write(to: targetFile, options: [.atomic, .completeFileProtection])
                    writtenCount += 1
                } catch {
                    log("hub: failed writing reset config to \(dir.path): \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                isResettingGuest = false
                if writtenCount > 0 {
                    isGuestResetInjected = true
                    alertTitle = "Guest Reset"
                    alertMessage = "Guest reset successfully!"
                } else {
                    alertTitle = "Injection Failed"
                    alertMessage = "Could not write reset config. Check exploit sandbox permissions."
                }
                showingAlert = true
            }
        }
    }

    private func removeResetGuestConfig() {
        guard !isRemovingResetConfig else { return }
        isRemovingResetConfig = true

        Task {
            _ = cleanGuestConfigFiles()

            await MainActor.run {
                isRemovingResetConfig = false
                isGuestResetInjected = false
                alertTitle = "Revert Reset"
                alertMessage = "Reverted reset successfully!"
                showingAlert = true
            }
        }
    }

    @discardableResult
    private func cleanGuestConfigFiles() -> Int {
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle) else {
            return 0
        }

        let fileManager = FileManager.default
        let containerURL = URL(fileURLWithPath: containerPath, isDirectory: true)

        let targetFiles = [
            containerURL.appendingPathComponent("Documents/localConfig.json"),
            containerURL.appendingPathComponent("Library/Application Support/localConfig.json"),
            containerURL.appendingPathComponent("Library/Caches/localConfig.json")
        ]

        var removedCount = 0
        for file in targetFiles {
            if fileManager.fileExists(atPath: file.path) {
                do {
                    try fileManager.removeItem(at: file)
                    removedCount += 1
                } catch {
                    log("hub: failed deleting \(file.path): \(error.localizedDescription)")
                }
            }
        }
        return removedCount
    }
    
    private func log(_ message: String) {
        #if DEBUG
        print("[ExternalPatchHub] \(message)")
        #endif
    }
}
