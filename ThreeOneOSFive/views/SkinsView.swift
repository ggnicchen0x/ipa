import SwiftUI
import UIKit

struct SkinsView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var skinService = SkinPatchService.shared
    
    @AppStorage("external_hub.target_bundle") private var targetBundle: String = "com.dts.freefiremax"
    
    @State private var expandedSkinID: String? = nil
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var processingSkinID: String? = nil

    private var animationCurve: Animation? {
        reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Header Status Card
                    headerSection
                        .staggeredAppearance(index: 0)

                    // Skins Cards List (Compact & Expandable)
                    if skinService.skins.isEmpty {
                        emptyStateSection
                            .staggeredAppearance(index: 1)
                    } else {
                        ForEach(Array(skinService.skins.enumerated()), id: \.element.id) { index, skin in
                            CompactSkinCard(
                                skin: skin,
                                isApplied: skinService.isApplied(skinID: skin.id),
                                isExpanded: expandedSkinID == skin.id,
                                isProcessing: processingSkinID == skin.id,
                                isAnyProcessing: processingSkinID != nil || skinService.isProcessing,
                                onToggleExpand: {
                                    withAnimation(animationCurve) {
                                        if expandedSkinID == skin.id {
                                            expandedSkinID = nil
                                        } else {
                                            expandedSkinID = skin.id
                                        }
                                    }
                                },
                                onAction: {
                                    handleSkinAction(skin: skin)
                                }
                            )
                            .staggeredAppearance(index: index + 1)
                        }
                    }

                    // Notice / Instructions Footer
                    footerNotice
                        .staggeredAppearance(index: skinService.skins.count + 2)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 36) // Extra clearance for persistent bottom tab bar
            }
            .background(AppTheme.bgBase.ignoresSafeArea())
            .navigationTitle("Skins")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                        Text("MOD SKINS")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.accentMuted)
                    .frame(width: 42, height: 42)
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Asset Modifier")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Tap any card to view details & apply")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            let activeCount = skinService.skins.filter { skinService.isApplied(skinID: $0.id) }.count
            StatusBadge(
                text: "\(activeCount) ACTIVE",
                style: activeCount > 0 ? .active : .neutral
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var emptyStateSection: some View {
        EmptyStateView(
            icon: "shippingbox",
            title: "No Skins Loaded",
            message: "Bundle manifests will appear here once loaded by the catalog service."
        )
        .padding(.vertical, 32)
    }

    private var footerNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.accent)
                .padding(.top, 1)

            Text("Verify that the target character or outfit bundle is fully downloaded inside Free Fire before applying.")
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
                .lineSpacing(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.bgElevated.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private func handleSkinAction(skin: SkinItem) {
        let isCurrentlyApplied = skinService.isApplied(skinID: skin.id)
        withAnimation(animationCurve) {
            processingSkinID = skin.id
        }
        
        if isCurrentlyApplied {
            skinService.removeSkin(skin: skin, targetBundle: targetBundle) { success, message in
                withAnimation(animationCurve) {
                    processingSkinID = nil
                }
                alertTitle = success ? "Skin Removed" : "Error Removing Skin"
                alertMessage = ErrorSanitizer.sanitize(message)
                showingAlert = true
            }
        } else {
            skinService.applySkin(skin: skin, targetBundle: targetBundle) { success, message in
                withAnimation(animationCurve) {
                    processingSkinID = nil
                }
                alertTitle = success ? "Skin Applied" : "Error Applying Skin"
                alertMessage = ErrorSanitizer.sanitize(message)
                showingAlert = true
            }
        }
    }
}

// MARK: - Compact & Expandable Skin Card

private struct CompactSkinCard: View {
    let skin: SkinItem
    let isApplied: Bool
    let isExpanded: Bool
    let isProcessing: Bool
    let isAnyProcessing: Bool
    let onToggleExpand: () -> Void
    let onAction: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Collapsed Header (Always visible & interactive)
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    // Left: Compact 1:1 Thumbnail
                    SkinThumbnailView(imageName: skin.imageName)
                        .frame(width: 48, height: 48)
                        .background(Color.black.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isApplied ? AppTheme.accent.opacity(0.7) : AppTheme.borderSubtle,
                                    lineWidth: 1
                                )
                        )

                    // Center: Name & Compact Character Label
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(skin.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            if isApplied {
                                StatusBadge(text: "APPLIED", style: .active)
                            }
                        }

                        Text("Character: \(skin.characterName)")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    // Right: Subtle Animated Chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isExpanded ? AppTheme.accent : AppTheme.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75), value: isExpanded)
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // MARK: Expanded Content (Smooth appearance on expand)
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .background(AppTheme.borderSubtle)
                        .padding(.horizontal, 12)

                    // Full description & instructions
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.accent)
                            Text("Compatibility Details")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.accent)
                        }

                        Text(skin.description)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)

                    // Action Button (Apply or Remove)
                    Button(action: onAction) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(isApplied ? Color.red : .white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: isApplied ? "trash.fill" : "sparkles")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            
                            Text(isProcessing ? (isApplied ? "Removing Skin..." : "Applying Skin...") : (isApplied ? "Remove Skin" : "Apply Skin"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            isApplied
                                ? AnyView(Color.red.opacity(0.14))
                                : AnyView(AppTheme.gradientPurple)
                        )
                        .foregroundStyle(isApplied ? Color.red : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isApplied ? Color.red.opacity(0.35) : AppTheme.borderFocused,
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isApplied ? Color.clear : AppTheme.purpleGlow.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 3
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnyProcessing)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isExpanded
                                ? AppTheme.borderFocused
                                : (isApplied ? AppTheme.accent.opacity(0.4) : AppTheme.borderSubtle),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Skin Thumbnail

private struct SkinThumbnailView: View {
    let imageName: String

    var body: some View {
        Group {
            if let uiImage = loadUIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let assetImage = UIImage(named: imageName) {
                Image(uiImage: assetImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    AppTheme.bgElevated
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }

    private func loadUIImage(named: String) -> UIImage? {
        if let img = UIImage(named: named) {
            return img
        }
        let cleanName = named.replacingOccurrences(of: " ", with: "_")
        if let img = UIImage(named: cleanName) {
            return img
        }
        
        let candidates = [named, cleanName, named.replacingOccurrences(of: "_", with: " ")]
        for name in candidates {
            for ext in ["png", "jpg", "jpeg", "PNG", "JPG"] {
                if let path = Bundle.main.path(forResource: name, ofType: ext) {
                    if let img = UIImage(contentsOfFile: path) { return img }
                }
                if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "skins") {
                    if let img = UIImage(contentsOfFile: path) { return img }
                }
                let skinsUrl = URL(fileURLWithPath: Bundle.main.bundlePath)
                    .appendingPathComponent("skins")
                    .appendingPathComponent("\(name).\(ext)")
                if let img = UIImage(contentsOfFile: skinsUrl.path) {
                    return img
                }
            }
        }
        return nil
    }
}
