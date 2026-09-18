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
                        Text(appState.hasAccess ? "Active & Rooted" : "Ready to Exploit")
                            .font(.footnote)
                            .foregroundStyle(appState.hasAccess ? .green : .orange)
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
                                Text("Box + Aim Stable")
                                    .fontWeight(.medium)
                                Text("Replaces Assembly-CSharp & localConfig")
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

                // Section 3: Master Action Controls
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
                if let receipt = try? PatchTransaction.readReceipt(for: project.id) {
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
}
