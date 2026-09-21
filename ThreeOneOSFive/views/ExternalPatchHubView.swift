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
    @AppStorage("mod.visuals") private var visualsEnabled: Bool = false

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
                    Picker("Select Game", selection: $targetBundle) {
                        ForEach(supportedBundles, id: \.1) { item in
                            Text(item.0).tag(item.1)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Label("Kernel Status", systemImage: "bolt.shield")
                        Spacer()
                        Text(appState.exploitStatus.isSuccess ? "Active & Rooted" : "Ready to Exploit")
                            .font(.footnote)
                            .foregroundStyle(appState.exploitStatus.isSuccess ? .green : .orange)
                    }
                } header: {
                    Text("Game Configuration")
                } footer: {
                    Text("Select your installed game version before toggling features.")
                }

                // Section 2: External Toggles (Self-Applying & Self-Reverting)
                Section {
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
                            AppRowIcon(systemName: "scope", tint: .red)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: aimStableEnabled) { isEnabled in
                        handleToggleChange(featureName: "avatar", isEnabled: isEnabled)
                    }

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
                            AppRowIcon(systemName: "speedometer", tint: .green)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: fps144Enabled) { isEnabled in
                        handleToggleChange(featureName: "144", isEnabled: isEnabled)
                    }

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
                            AppRowIcon(systemName: "flame.fill", tint: .purple)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: magicBulletEnabled) { isEnabled in
                        handleToggleChange(featureName: "magic", isEnabled: isEnabled)
                    }

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
                            AppRowIcon(systemName: "bolt.fill", tint: .blue)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: bodyDragEnabled) { isEnabled in
                        handleToggleChange(featureName: "aimbody", isEnabled: isEnabled)
                    }

                    Toggle(isOn: $visualsEnabled) {
                        Label {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Visuals")
                                        .fontWeight(.medium)
                                    Text("Hologram for Location Exposed")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if processingFeature == "hologram" {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        } icon: {
                            AppRowIcon(systemName: "eye.fill", tint: .cyan)
                        }
                    }
                    .disabled(processingFeature != nil)
                    .onChange(of: visualsEnabled) { isEnabled in
                        handleToggleChange(featureName: "hologram", isEnabled: isEnabled)
                    }
                } header: {
                    Text("External Toggles")
                }

                // Section 3: Guest Account Manager
                Section {
                    Button {
                        resetGuestAccount()
                    } label: {
                        HStack {
                            AppRowIcon(systemName: "person.crop.circle.badge.minus", tint: AppTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset Guest Account")
                                    .fontWeight(.medium)
                                Text("Reset your Guest Account : \(targetBundle)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isResettingGuest {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isResettingGuest || isRemovingResetConfig || isRestoringGame)

                    Button(role: .destructive) {
                        removeResetGuestConfig()
                    } label: {
                        HStack {
                            AppRowIcon(systemName: "trash", tint: .red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Remove Reset Config")
                                    .fontWeight(.medium)
                                Text("Deletes config after guest reset")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isRemovingResetConfig {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isResettingGuest || isRemovingResetConfig || isRestoringGame)
                } header: {
                    Text("Guest Account Manager")
                } footer: {
                    Text("Tap 'Reset Guest Account', open Free Fire once to initialize the wipe, then close the game and tap 'Remove Reset Config'.")
                }

                // Section 4: Execution / Safety
                Section {
                    Button(role: .destructive) {
                        restoreAllDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            if isRestoringGame {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Restore Game to Original (Clean)")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isRestoringGame || isResettingGuest || isRemovingResetConfig)
                } header: {
                    Text("Execution & Safety")
                } footer: {
                    Text("Make sure the target game is closed before restoring.")
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

    private func handleToggleChange(featureName: String, isEnabled: Bool) {
        let featureTitle: String
        switch featureName {
        case "avatar": featureTitle = "Aim Drag"
        case "144": featureTitle = "144 FPS Unlock"
        case "magic": featureTitle = "Magic Bullet"
        case "aimbody": featureTitle = "Aim Body"
        case "hologram", "visuals": featureTitle = "Visuals"
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
                        self.statusMessage = "Cloud fetch failed: \(message)"
                        self.alertTitle = "Cloud Delivery Error"
                        self.alertMessage = message
                        self.showingAlert = true
                        self.log("hub: cloud-apply failed for \(featureTitle): \(message)")
                        
                        // Revert toggle state if cloud fetch failed
                        switch featureName {
                        case "avatar": self.aimStableEnabled = false
                        case "144": self.fps144Enabled = false
                        case "magic": self.magicBulletEnabled = false
                        case "aimbody": self.bodyDragEnabled = false
                        case "hologram", "visuals": self.visualsEnabled = false
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

            await MainActor.run {
                aimStableEnabled = false
                fps144Enabled = false
                magicBulletEnabled = false
                bodyDragEnabled = false
                visualsEnabled = false
                isRestoringGame = false
                alertTitle = "Restore Complete"
                alertMessage = "Restored original game files (\(restoredCount) files reverted)."
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
                    alertTitle = "Reset Config Injected"
                    alertMessage = "Successfully wrote localConfig.json to \(writtenCount) locations in \(targetBundle).\n\n1. Open Free Fire once to trigger the guest wipe.\n2. Close the game completely.\n3. Return here and tap 'Remove Reset Config'."
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
            guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle) else {
                await MainActor.run {
                    isRemovingResetConfig = false
                    alertTitle = "Game Not Found"
                    alertMessage = "Could not resolve container path for \(targetBundle)."
                    showingAlert = true
                }
                return
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

            await MainActor.run {
                isRemovingResetConfig = false
                alertTitle = "Config Cleaned"
                alertMessage = "Removed \(removedCount) localConfig.json files from \(targetBundle). You can now play normally with your new guest session."
                showingAlert = true
            }
        }
    }
    
    private func log(_ message: String) {
        #if DEBUG
        print("[ExternalPatchHub] \(message)")
        #endif
    }
}
