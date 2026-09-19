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
    
    @AppStorage("external_hub.target_bundle") private var targetBundle: String = "com.dts.freefireth"
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
        ("Free Fire Global / TH", "com.dts.freefireth"),
        ("Free Fire MAX", "com.dts.freefiremax")
    ]

    var body: some View {
        NavigationStack {
            List {
                // Section 1: Target Game Bundle
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

                // Section 2: Mod Features & Toggles
                Section {
                    Toggle(isOn: $aimStableEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aim Drag")
                                    .fontWeight(.medium)
                                Text("Patches cache_res in gamesassetbundles")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "scope", tint: .red)
                        }
                    }

                    Toggle(isOn: $fps144Enabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("144 FPS Unlock")
                                    .fontWeight(.medium)
                                Text("Applies 144Hz plist preferences")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "speedometer", tint: .green)
                        }
                    }

                    Toggle(isOn: $magicBulletEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Magic Bullet")
                                    .fontWeight(.medium)
                                Text("Applies Magic Bullet cache asset bundle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "flame.fill", tint: .purple)
                        }
                    }

                    Toggle(isOn: $bodyDragEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Body / Drag Boost")
                                    .fontWeight(.medium)
                                Text("Applies ATH Drag asset bundle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "bolt.fill", tint: .blue)
                        }
                    }

                    Toggle(isOn: $cleanCacheEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clean Cache Asset")
                                    .fontWeight(.medium)
                                Text("Flushes corrupted game assets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AppRowIcon(systemName: "arrow.triangle.2.circlepath", tint: .orange)
                        }
                    }
                } header: {
                    Text("External Toggles")
                }

                // Section 3: Guest Account Reset
                Section {
                    Button {
                        resetGuestAccount()
                    } label: {
                        HStack {
                            AppRowIcon(systemName: "person.crop.circle.badge.minus", tint: .orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset Guest Account")
                                    .fontWeight(.medium)
                                Text("Injects resetGuest config to \(targetBundle)")
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
                                Text("Deletes localConfig.json after guest reset")
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

                // Section 4: Master Action Controls
                Section {
                    Button {
                        applyActiveMods()
                    } label: {
                        HStack {
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Apply Active Mods")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isProcessing)
                    .tint(AppTheme.accent)

                    Button(role: .destructive) {
                        restoreAllDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Restore Game to Original (Clean)")
                            Spacer()
                        }
                    }
                    .disabled(isProcessing)
                } header: {
                    Text("Execution")
                } footer: {
                    Text("Make sure the target game is closed before tapping Apply or Restore.")
                }
            }
            .navigationTitle("External Menu")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func applyActiveMods() {
        isProcessing = true
        statusMessage = "Applying active mods..."

        Task {
            // Match corresponding bundled .3105 files in patchStore
            var appliedCount = 0
            for item in patchStore.items {
                guard let project = item.project else { continue }
                let name = project.name.lowercased()

                var shouldApply = false
                if aimStableEnabled && (name.contains("aim") || name.contains("box") || name.contains("ffth")) {
                    shouldApply = true
                }
                if fps144Enabled && name.contains("144") {
                    shouldApply = true
                }
                if magicBulletEnabled && (name.contains("magic") || name.contains("athmagic")) {
                    shouldApply = true
                }
                if bodyDragEnabled && (name.contains("drag") || name.contains("athdrag") || name.contains("athbody")) {
                    shouldApply = true
                }
                if cleanCacheEnabled && (name.contains("cleann") || name.contains("cash")) {
                    shouldApply = true
                }

                if shouldApply {
                    do {
                        _ = try DevicePatchService.apply(project: project)
                        appliedCount += 1
                    } catch {
                        log("hub: apply failed for \(project.name): \(error.localizedDescription)")
                    }
                }
            }

            await MainActor.run {
                isProcessing = false
                alertTitle = "Mod Application"
                alertMessage = "Successfully processed active mods (\(appliedCount) applied) to \(targetBundle)."
                showingAlert = true
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
