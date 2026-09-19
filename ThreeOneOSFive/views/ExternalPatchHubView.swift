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
    @AppStorage("mod.clean_cache") private var cleanCacheEnabled: Bool = false

    @State private var statusMessage: String = "Ready"
    @State private var isProcessing: Bool = false
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
                        Label("Target Bundle ID", systemImage: "app.badge.checkmark")
                        Spacer()
                        Text(targetBundle)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

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
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aim Drag")
                                    .fontWeight(.medium)
                                Text("Enhance your Aim Target")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "scope", tint: .red)
                        }
                    }
                    .onChange(of: aimStableEnabled) { isEnabled in
                        handleToggleChange(featureName: "avatar", isEnabled: isEnabled)
                    }

                    Toggle(isOn: $fps144Enabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("144 FPS Unlock")
                                    .fontWeight(.medium)
                                Text("Unlocks ultra-smooth 144Hz gameplay")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "speedometer", tint: .green)
                        }
                    }
                    .onChange(of: fps144Enabled) { isEnabled in
                        handleToggleChange(featureName: "144", isEnabled: isEnabled)
                    }

                    Toggle(isOn: $magicBulletEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Magic Bullet")
                                    .fontWeight(.medium)
                                Text("Connect Every Single Bullets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "flame.fill", tint: .purple)
                        }
                    }
                    .onChange(of: magicBulletEnabled) { isEnabled in
                        handleToggleChange(featureName: "magic", isEnabled: isEnabled)
                    }

                    Toggle(isOn: $bodyDragEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aim Body")
                                    .fontWeight(.medium)
                                Text("Only Red shots/high accuracy")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "bolt.fill", tint: .blue)
                        }
                    }
                    .onChange(of: bodyDragEnabled) { isEnabled in
                        handleToggleChange(featureName: "aimbody", isEnabled: isEnabled)
                    }

                    Toggle(isOn: $cleanCacheEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clean Cache Asset")
                                    .fontWeight(.medium)
                                Text("Cleans and refreshes game cache")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "arrow.triangle.2.circlepath", tint: AppTheme.accent)
                        }
                    }
                    .onChange(of: cleanCacheEnabled) { isEnabled in
                        handleToggleChange(featureName: "clean", isEnabled: isEnabled)
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
                            if isProcessing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isProcessing)

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
                        }
                    }
                    .disabled(isProcessing)
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
                            if isProcessing {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Restore Game to Original (Clean)")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isProcessing)
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
        Task {
            let matchingItems = patchStore.items.filter { item in
                guard let project = item.project else { return false }
                let name = project.name.lowercased()
                if featureName == "avatar" {
                    return name.contains("avatar") || name.contains("aim drag")
                } else if featureName == "144" {
                    return name.contains("144")
                } else if featureName == "magic" {
                    return name.contains("magic")
                } else if featureName == "aimbody" {
                    return name.contains("aimbody") || (name.contains("body") && !name.contains("avatar"))
                } else if featureName == "clean" {
                    return name.contains("cleann") || name.contains("cash")
                }
                return false
            }

            for item in matchingItems {
                guard let project = item.project else { continue }
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

                if isEnabled {
                    // Restore existing receipt if any before reapplying
                    if let existingReceipt = DevicePatchService.latestReceipt(projectID: adaptedProject.id) {
                        try? DevicePatchService.restore(receipt: existingReceipt, allowChangedTargets: true)
                    }
                    do {
                        _ = try DevicePatchService.apply(project: adaptedProject)
                        log("hub: auto-applied \(project.name) to \(targetBundle)")
                    } catch {
                        log("hub: auto-apply failed for \(project.name): \(error.localizedDescription)")
                    }
                } else {
                    // Revert single feature
                    if let receipt = DevicePatchService.latestReceipt(projectID: adaptedProject.id) {
                        do {
                            try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
                            log("hub: auto-reverted \(project.name) for \(targetBundle)")
                        } catch {
                            log("hub: auto-revert failed for \(project.name): \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    private func restoreAllDefaults() {
        isProcessing = true
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
                cleanCacheEnabled = false
                isProcessing = false
                alertTitle = "Restore Complete"
                alertMessage = "Restored original game files (\(restoredCount) files reverted)."
                showingAlert = true
            }
        }
    }

    private func resetGuestAccount() {
        guard !isProcessing else { return }
        isProcessing = true

        Task {
            guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle) else {
                await MainActor.run {
                    isProcessing = false
                    alertTitle = "Game Not Found"
                    alertMessage = "Could not resolve container path for \(targetBundle). Make sure the game is installed."
                    showingAlert = true
                }
                return
            }

            let fileManager = FileManager.default
            let containerURL = URL(fileURLWithPath: containerPath, isDirectory: true)
            let configJSON = "{\"testCodePatch\":true,\"resetGuest\":true}\n".data(using: .utf8)!

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
                isProcessing = false
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
        guard !isProcessing else { return }
        isProcessing = true

        Task {
            guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundle) else {
                await MainActor.run {
                    isProcessing = false
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
                isProcessing = false
                alertTitle = "Config Cleaned"
                alertMessage = "Removed \(removedCount) localConfig.json files from \(targetBundle). You can now play normally with your new guest session."
                showingAlert = true
            }
        }
    }
}
