import SwiftUI
import UIKit

struct SkinsView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var skinService = SkinPatchService.shared
    
    @AppStorage("external_hub.target_bundle") private var targetBundle: String = "com.dts.freefiremax"
    
    @State private var statusMessage: String = "Ready"
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var processingSkinID: String? = nil

    var body: some View {
        NavigationStack {
            List {
                // Skins Catalog Section
                Section {
                    ForEach(skinService.skins) { skin in
                        SkinRowView(
                            skin: skin,
                            isApplied: skinService.isApplied(skinID: skin.id),
                            isProcessing: processingSkinID == skin.id || skinService.isProcessing,
                            onAction: {
                                handleSkinAction(skin: skin)
                            }
                        )
                    }
                } header: {
                    Text("Available Mod Skins")
                } footer: {
                    Text("Make sure the character or outfit is fully downloaded inside Free Fire before applying.")
                }
            }
            .navigationTitle("Skins")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func handleSkinAction(skin: SkinItem) {
        let isCurrentlyApplied = skinService.isApplied(skinID: skin.id)
        processingSkinID = skin.id
        
        if isCurrentlyApplied {
            skinService.removeSkin(skin: skin, targetBundle: targetBundle) { success, message in
                processingSkinID = nil
                alertTitle = success ? "Skin Removed" : "Error Removing Skin"
                alertMessage = message
                showingAlert = true
            }
        } else {
            skinService.applySkin(skin: skin, targetBundle: targetBundle) { success, message in
                processingSkinID = nil
                alertTitle = success ? "Skin Applied" : "Error Applying Skin"
                alertMessage = message
                showingAlert = true
            }
        }
    }
}

private struct SkinRowView: View {
    let skin: SkinItem
    let isApplied: Bool
    let isProcessing: Bool
    let onAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Left Side: Skin Thumbnail Image (Square 1:1 full-bleed card)
            SkinThumbnailView(imageName: skin.imageName)
                .frame(width: 76, height: 76)
                .background(Color.black.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isApplied ? AppTheme.accent.opacity(0.6) : Color.secondary.opacity(0.2), lineWidth: 1)
                )

            // Middle: Name & Description
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(skin.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if isApplied {
                        Text("Active")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.accent.opacity(0.18))
                            .foregroundStyle(AppTheme.accent)
                            .clipShape(Capsule())
                    }
                }

                Text(skin.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 4)

                // Action Button: Apply / Remove
                Button(action: onAction) {
                    HStack(spacing: 6) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: isApplied ? "trash.fill" : "arrow.down.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        
                        Text(isApplied ? "Remove" : "Apply")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        isApplied
                            ? Color.red.opacity(0.15)
                            : AppTheme.accent.opacity(0.18)
                    )
                    .foregroundStyle(isApplied ? Color.red : AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                isApplied ? Color.red.opacity(0.35) : AppTheme.accent.opacity(0.35),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            }
        }
        .padding(.vertical, 6)
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
                    Color.secondary.opacity(0.15)
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 26))
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
