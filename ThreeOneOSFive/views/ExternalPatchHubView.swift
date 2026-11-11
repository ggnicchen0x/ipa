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
    @AppStorage("mod.aim_drag_mode") private var aimDragMode: String = "cs_rank" // "cs_rank" or "rooms"
    @AppStorage("mod.fps_144") private var fps144Enabled: Bool = false
    @AppStorage("mod.magic_bullet") private var magicBulletEnabled: Bool = false
    @AppStorage("mod.body_drag") private var bodyDragEnabled: Bool = false
    @AppStorage("mod.visuals") private var visualsEnabled: Bool = false
    @AppStorage("guest_reset.injected") private var isGuestResetInjected: Bool = false

    @State private var statusMessage: String = "Ready"
    @State private var processingFeature: String? = nil
    @State private var showingDragModePopup: Bool = false
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

    private var selectorOptions: [PremiumGameOption] {
        [
            PremiumGameOption(
                id: "com.dts.freefiremax",
                title: "Free Fire MAX",
                subtitle: "FF MAX client",
                icon: "flame.fill",
                tint: AppTheme.accent
            ),
            PremiumGameOption(
                id: "com.dts.freefireth",
                title: "Free Fire",
                subtitle: "FF regular client",
                icon: "flame.fill",
                tint: AppTheme.accent
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
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

                // Centered Drag MODE Modal Dialog (in-between screen)
                if showingDragModePopup {
                    Color.black.opacity(0.65)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                showingDragModePopup = false
                            }
                        }

                    dragModeModal
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showingDragModePopup)
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

            // Game Picker (Premium Dropdown)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.accent.opacity(0.85))
                    Text("SELECT GAME")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)
                        .tracking(0.6)
                }
                PremiumGameSelector(
                    selection: $targetBundle,
                    options: selectorOptions
                ) { previous, next in
                    handleGameSwitch(from: previous, to: next)
                }
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
            PremiumSectionHeader(title: "EXTERNAL FEATURES", icon: "slider.horizontal.3")
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.top, AppTheme.cardPadding)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                // 1. Aim Drag (Multi-mode: CS Rank / Rooms)
                PremiumToggleRow(
                    icon: "scope",
                    title: "Aim Drag",
                    subtitle: aimStableEnabled
                        ? (aimDragMode == "rooms" ? "Active: Rooms" : "Active: CS Rank")
                        : "Enhance your Aim Target",
                    isOn: Binding(
                        get: { aimStableEnabled },
                        set: { newValue in
                            if newValue {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    showingDragModePopup = true
                                }
                            } else {
                                aimStableEnabled = false
                                handleToggleChange(featureName: currentAimDragFeatureKey, isEnabled: false)
                            }
                        }
                    ),
                    isProcessing: processingFeature == "avatar" || processingFeature == "avatar_cs" || processingFeature == "avatar_rooms",
                    isDisabled: processingFeature != nil && !["avatar", "avatar_cs", "avatar_rooms"].contains(processingFeature)
                )
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.vertical, 10)

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

                // 4. Visuals (Hologram Location Exposed)
                PremiumToggleRow(
                    icon: "eye.fill",
                    title: "Visuals",
                    subtitle: "Hologram for Location Exposed",
                    isOn: $visualsEnabled,
                    isProcessing: processingFeature == "hologram",
                    isDisabled: processingFeature != nil && processingFeature != "hologram"
                )
                .padding(.horizontal, AppTheme.cardPadding)
                .padding(.vertical, 10)
                .onChange(of: visualsEnabled) { isEnabled in
                    handleToggleChange(featureName: "hologram", isEnabled: isEnabled)
                }

                Divider().overlay(AppTheme.subtleBorder).padding(.horizontal, AppTheme.cardPadding)

                // 5. 144 FPS Unlock
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
            PremiumSectionHeader(title: "SETTINGS", icon: "person.badge.key.fill")
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

    private func handleGameSwitch(from previousBundle: String, to newBundle: String) {
        guard previousBundle != newBundle else { return }
        // Capture then clear each active feature against the OLD target so
        // the new game starts from a clean state.
        if aimStableEnabled {
            CloudPatchService.shared.revertPatch(featureKey: currentAimDragFeatureKey, targetBundle: previousBundle) { _, _ in }
            aimStableEnabled = false
        }
        if bodyDragEnabled {
            CloudPatchService.shared.revertPatch(featureKey: "aimbody", targetBundle: previousBundle) { _, _ in }
            bodyDragEnabled = false
        }
        if magicBulletEnabled {
            CloudPatchService.shared.revertPatch(featureKey: "magic", targetBundle: previousBundle) { _, _ in }
            magicBulletEnabled = false
        }
        if visualsEnabled {
            CloudPatchService.shared.revertPatch(featureKey: "hologram", targetBundle: previousBundle) { _, _ in }
            visualsEnabled = false
        }
        if fps144Enabled {
            CloudPatchService.shared.revertPatch(featureKey: "144", targetBundle: previousBundle) { _, _ in }
            fps144Enabled = false
        }
        processingFeature = nil
        statusMessage = "Switched to \(selectorOptions.first(where: { $0.id == newBundle })?.title ?? newBundle)"
        log("hub: game switched \(previousBundle) -> \(newBundle); active features reverted")
    }

    private var currentAimDragFeatureKey: String {
        aimDragMode == "rooms" ? "avatar_rooms" : "avatar"
    }

    private func handleToggleChange(featureName: String, isEnabled: Bool) {
        let featureTitle: String
        switch featureName {
        case "avatar", "avatar_cs": featureTitle = "Aim Drag (CS Rank)"
        case "avatar_rooms", "avatar_p": featureTitle = "Aim Drag (Rooms)"
        case "144": featureTitle = "144 FPS Unlock"
        case "magic": featureTitle = "Magic Bullet"
        case "aimbody": featureTitle = "Aim Body"
        case "hologram", "visuals": featureTitle = "Visuals"
        default: featureTitle = featureName.capitalized
        }
        
        processingFeature = featureName
        if isEnabled {
            statusMessage = "Fetching '\(featureTitle)'..."
            
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
                        self.statusMessage = "Delivery failed: \(cleanMessage)"
                        self.alertTitle = "Mod Delivery Error"
                        self.alertMessage = cleanMessage
                        self.showingAlert = true
                        self.log("hub: apply failed for \(featureTitle): \(cleanMessage)")
                        
                        switch featureName {
                        case "avatar", "avatar_cs", "avatar_rooms", "avatar_p": self.aimStableEnabled = false
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
                visualsEnabled = false
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
    
    // MARK: - Drag Mode Selection Pop-up
    private func selectDragMode(_ mode: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            showingDragModePopup = false
        }
        let previousKey = currentAimDragFeatureKey
        let isAlreadyEnabled = aimStableEnabled
        aimDragMode = mode
        aimStableEnabled = true
        let newKey = currentAimDragFeatureKey
        
        if isAlreadyEnabled && previousKey != newKey {
            CloudPatchService.shared.revertPatch(featureKey: previousKey, targetBundle: targetBundle) { _, _ in
                handleToggleChange(featureName: newKey, isEnabled: true)
            }
        } else {
            handleToggleChange(featureName: newKey, isEnabled: true)
        }
    }

    private var dragModeModal: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("DRAG MODE")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.2)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        showingDragModePopup = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
            .padding(.horizontal, 22)

            // Two buttons side by side: CS Rank & Rooms
            HStack(spacing: 12) {
                // CS Rank Button
                Button {
                    selectDragMode("cs_rank")
                } label: {
                    Text("CS Rank")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(aimStableEnabled && aimDragMode == "cs_rank" ? AppTheme.accent : Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(aimStableEnabled && aimDragMode == "cs_rank" ? AppTheme.accent : Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                // Rooms Button
                Button {
                    selectDragMode("rooms")
                } label: {
                    Text("Rooms")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(aimStableEnabled && aimDragMode == "rooms" ? AppTheme.accent : Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(aimStableEnabled && aimDragMode == "rooms" ? AppTheme.accent : Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .frame(width: 310)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: 0x14141c))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.65), radius: 30, x: 0, y: 15)
        )
    }
    
    private func log(_ message: String) {
        #if DEBUG
        print("[ExternalPatchHub] \(message)")
        #endif
    }
}
