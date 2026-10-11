import SwiftUI
import UIKit

struct SkinsView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var skinService = SkinPatchService.shared
    
    @AppStorage("external_hub.target_bundle") private var targetBundle: String = "com.dts.freefiremax"
    
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var processingSkinID: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Status Card
                    headerSection
                        .staggeredAppearance(index: 0)

                    // Skins Cards List
                    if skinService.skins.isEmpty {
                        emptyStateSection
                            .staggeredAppearance(index: 1)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(skinService.skins.enumerated()), id: \.element.id) { index, skin in
                                SkinRowView(
                                    skin: skin,
                                    isApplied: skinService.isApplied(skinID: skin.id),
                                    isProcessing: processingSkinID == skin.id,
                                    isAnyProcessing: processingSkinID != nil || skinService.isProcessing,
                                    onAction: {
                                        handleSkinAction(skin: skin)
                                    }
                                )
                                .staggeredAppearance(index: index + 1)
                            }
                        }
                    }

                    // Notice / Instructions Footer
                    footerNotice
                        .staggeredAppearance(index: skinService.skins.count + 2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
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
                    .frame(width: 44, height: 44)
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Asset Modifier")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Inject custom outfits & textures directly into client cache")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            StatusBadge(
                text: "\(skinService.skins.filter { skinService.isApplied(skinID: $0.id) }.count) ACTIVE",
                style: .active
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                .font(.system(size: 14))
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
                .fill(AppTheme.bgElevated.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private func handleSkinAction(skin: SkinItem) {
        let isCurrentlyApplied = skinService.isApplied(skinID: skin.id)
        withAnimation(AppAnimation.springStandard) {
            processingSkinID = skin.id
        }
        
        if isCurrentlyApplied {
            skinService.removeSkin(skin: skin, targetBundle: targetBundle) { success, message in
                withAnimation(AppAnimation.springStandard) {
                    processingSkinID = nil
                }
                alertTitle = success ? "Skin Removed" : "Error Removing Skin"
                alertMessage = ErrorSanitizer.sanitize(message)
                showingAlert = true
            }
        } else {
            skinService.applySkin(skin: skin, targetBundle: targetBundle) { success, message in
                withAnimation(AppAnimation.springStandard) {
                    processingSkinID = nil
                }
                alertTitle = success ? "Skin Applied" : "Error Applying Skin"
                alertMessage = ErrorSanitizer.sanitize(message)
                showingAlert = true
            }
        }
    }
}

private struct SkinRowView: View {
    let skin: SkinItem
    let isApplied: Bool
    let isProcessing: Bool
    let isAnyProcessing: Bool
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                // Left Side: Skin Thumbnail Image
                SkinThumbnailView(imageName: skin.imageName)
                    .frame(width: 68, height: 68)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isApplied ? AppTheme.accent.opacity(0.6) : AppTheme.borderSubtle, lineWidth: 1)
                    )

                // Middle: Name & Description
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(skin.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        if isApplied {
                            StatusBadge(text: "APPLIED", style: .active)
                        }
                    }

                    Text(skin.description)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)
            }

            // Bottom action button full width inside card
            Button(action: onAction) {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(isApplied ? Color.red : AppTheme.accent)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isApplied ? "trash.fill" : "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    
                    Text(isProcessing ? (isApplied ? "Removing..." : "Applying...") : (isApplied ? "Remove Skin" : "Apply Skin"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    isApplied
                        ? Color.red.opacity(0.12)
                        : AppTheme.accentMuted
                )
                .foregroundStyle(isApplied ? Color.red : AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            isApplied ? Color.red.opacity(0.35) : AppTheme.borderFocused,
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isAnyProcessing)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isApplied ? AppTheme.borderFocused : AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }
}

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
                        .font(.system(size: 24))
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
