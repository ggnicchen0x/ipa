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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    @State private var appeared = false

    private let supportedBundles = [
        ("Free Fire MAX", "com.dts.freefiremax"),
        ("Free Fire TH", "com.dts.freefireth")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section 1: Game Configuration Card
                    gameConfigSection
                        .staggeredAppearance(index: 0)

                    // Section 2: External Toggles
                    externalTogglesSection
                        .staggeredAppearance(index: 1)

                    // Section 3: Guest Account Manager
                    guestManagerSection
                        .staggeredAppearance(index: 2)
                }
                .padding(.horizontal, AppTheme.pageInset)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("Menu")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Game Configuration

    private var gameConfigSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            PremiumSectionHeader(title: "GAME CONFIGURATION", icon: "gamecontroller.fill")
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.top, AppTheme.cardPadding)
                .padding(.bottom, 14)

            // Game Picker
            HStack {
                Label {
                    Text("Select Game")
                        .font(.system(size: 15, weight: .medium))
                } icon: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
                Picker("", selection: $targetBundle) {
                    ForEach(supportedBundles, id: \.1) { item in
                        Text(item.0).tag(item.1)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.accent)
            }
            .padding(.horizontal, AppTheme.cardPadding)
            .padding(.vertical, 12)

            Divider().overlay(AppTheme.subtleBorder).padding(.horizontal, AppTheme.cardPadding)

            // Kernel Status
            HStack {
                Label {
                    Text("Kernel Status")
                        .font(.system(size: 15, weight: .medium))
                } icon: {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
                StatusBadge(
                    text: "Active & Rooted",
                    color: .green,
                    isActive: true
                )
            }
            .padding(.horizontal, AppTheme.cardPadding)
            .padding(.vertical, 12)

            // Footer
            Text("Select your installed game version before toggling features.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary)
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.bottom, AppTheme.cardPadding)
                .padding(.top, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 0.5)
                )
        )
    }

    // MARK: - External Toggles

    private var externalTogglesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            PremiumSectionHeader(title: "EXTERNAL TOGGLES", icon: "slider.horizontal.3")
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.top, AppTheme.cardPadding)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                // 1. Aim Drag
                PremiumToggleRow(
                    icon: "scope",
                    title: "Aim Drag",
                    subtitle: "Enhance your Aim Target",
                    isOn: $aimStableEnabled,
                    isProcessing: processingFeature == "avatar",
                    isDisabled: processingFeature != nil && processingFeature != "avatar"
                )
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.vertical, 10)
                .onChange(of: aimStableEnabled) { isEnabled in
                    handleToggleChange(featureName: "avatar", isEnabled: isEnabled)
                }

                Divider().overlay(AppTheme.subtleBorder).padding(.horizontal, AppTheme.cardPadding)

                // 2. Aim Body
                PremiumToggleRow(
                    icon: "bolt.fill",
                    title: "Aim Body",
                    subtitle: "Only Red shots/high accuracy",
                    isOn: $bodyDragEnabled,
                    isProcessing: processingFeature == "aimbody",
                    isDisabled: processingFeature != nil && processingFeature != "aimbody"
                )
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.vertical, 10)
                .onChange(of: bodyDragEnabled) { isEnabled in
                    handleToggleChange(featureName: "aimbody", isEnabled: isEnabled)
                }

                Divider().overlay(AppTheme.subtleBorder).padding(.horizontal, AppTheme.cardPadding)

                // 3. Magic Bullet
                PremiumToggleRow(
                    icon: "flame.fill",
                    title: "Magic Bullet",
                    subtitle: "Connect Every Single Bullets",
                    isOn: $magicBulletEnabled,
                    isProcessing: processingFeature == "magic",
                    isDisabled: processingFeature != nil && processingFeature != "magic"
                )
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.vertical, 10)
                .onChange(of: magicBulletEnabled) { isEnabled in
                    handleToggleChange(featureName: "magic", isEnabled: isEnabled)
                }

                Divider().overlay(AppTheme.subtleBorder).padding(.horizontal, AppTheme.cardPadding)

                // 4. 144 FPS Unlock
                PremiumToggleRow(
                    icon: "speedometer",
                    title: "144 FPS Unlock",
                    subtitle: "Unlocks ultra-smooth 144Hz gameplay",
                    isOn: $fps144Enabled,
                    isProcessing: processingFeature == "144",
                    isDisabled: processingFeature != nil && processingFeature != "144"
                )
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.vertical, 10)
                .onChange(of: fps144Enabled) { isEnabled in
                    handleToggleChange(featureName: "144", isEnabled: isEnabled)
                }

                Divider().overlay(AppTheme.subtleBorder).padding(.horizontal, AppTheme.cardPadding)

                // 5. Clean Cache Asset
                PremiumToggleRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Clean Cache Asset",
                    subtitle: "Cleans and refreshes game cache",
                    isOn: $cleanCacheAssetEnabled,
                    isProcessing: processingFeature == "cleancache",
                    isDisabled: processingFeature != nil && processingFeature != "cleancache"
                )
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.vertical, 10)
                .onChange(of: cleanCacheAssetEnabled) { isEnabled in
                    handleCleanCacheAsset(isEnabled: isEnabled)
                }
            }

            // Bottom padding
            Spacer().frame(height: 6)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Guest Account Manager

    private var guestManagerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            PremiumSectionHeader(title: "ACCOUNT TOOLS", icon: "person.badge.key.fill")
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.top, AppTheme.cardPadding)
                .padding(.bottom, 10)

            // Guest Reset / Revert
            Button {
                if isGuestResetInjected {
                    removeResetGuestConfig()
                } else {
                    resetGuestAccount()
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.iconCornerRadius, style: .continuous)
                            .fill(isGuestResetInjected ? Color.orange.opacity(0.12) : AppTheme.accent.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.iconCornerRadius, style: .continuous)
                                    .stroke(isGuestResetInjected ? Color.orange.opacity(0.2) : AppTheme.accent.opacity(0.15), lineWidth: 0.5)
                            )
                        Image(systemName: isGuestResetInjected ? "arrow.uturn.backward.circle.fill" : "person.crop.circle.badge.minus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isGuestResetInjected ? .orange : AppTheme.accent)
                    }
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isGuestResetInjected ? "Revert Reset" : "Guest Reset")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isGuestResetInjected ? Color.orange : Color.primary)
                        Text(isGuestResetInjected ? "Remove config to finish guest wipe & play" : "Wipes guest session on next game launch")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    if isResettingGuest || isRemovingResetConfig {
                        ProgressView()
                            .scaleEffect(0.85)
                            .tint(AppTheme.accent)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(isResettingGuest || isRemovingResetConfig || isRestoringGame)

            Divider().overlay(AppTheme.subtleBorder).padding(.horizontal, AppTheme.cardPadding)

            // Reset All Changes
            Button {
                restoreAllDefaults()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.iconCornerRadius, style: .continuous)
                            .fill(Color.red.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.iconCornerRadius, style: .continuous)
                                    .stroke(Color.red.opacity(0.15), lineWidth: 0.5)
                            )
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.red.opacity(0.85))
                    }
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Changes")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                        Text("Deactivates all mods & restores original game files")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    if isRestoringGame {
                        ProgressView()
                            .scaleEffect(0.85)
                            .tint(.red)
                    }
                }
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(isRestoringGame || isResettingGuest || isRemovingResetConfig)

            // Footer
            Text("Use Guest Reset to wipe guest data. Use Reset All Changes to restore all original game files and disable active mods.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary)
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.bottom, AppTheme.cardPadding)
                .padding(.top, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Business Logic (Preserved)

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

            for skin in SkinPatchService.shared.skins {
                if SkinPatchService.shared.isApplied(skinID: skin.id) {
                    SkinPatchService.shared.removeSkin(skin: skin, targetBundle: targetBundle) { _, _ in }
                }
            }

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
