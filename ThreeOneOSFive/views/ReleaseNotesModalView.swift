import SwiftUI

public struct ReleaseNotesModalView: View {
    let release: PackageReleaseInfo
    @ObservedObject private var releasesService = ReleasesService.shared
    @Environment(\.dismiss) private var dismiss
    
    public init(release: PackageReleaseInfo) {
        self.release = release
    }
    
    public var body: some View {
        ZStack {
            AppTheme.bgBase.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header Badge
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.accent)
                        
                        Text("NEW UPDATE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(AppTheme.accent)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentMuted)
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.borderFocused, lineWidth: 1)
                            )
                    )
                    
                    Text(release.packageName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(release.filename)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("•")
                            .foregroundColor(AppTheme.textMuted)
                        
                        Text(release.versionTag)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppTheme.bgElevated)
                            )
                    }
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                
                Divider()
                    .background(AppTheme.borderSubtle)
                    .padding(.vertical, 20)
                
                // "What's New" Section
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What's New:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(parseBullets(release.releaseNotes), id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(AppTheme.accent)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 7)
                                    
                                    Text(bullet)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.bgCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                        
                        // Verification note
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.accent)
                            
                            Text("Latest patch payload verified & ready in cloud delivery.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 16)
                
                // Action Button: [Continue]
                Button {
                    releasesService.acknowledgeRelease(release: release) {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppTheme.gradientPurple)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func parseBullets(_ text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var bullets: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                let clean = trimmed.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty { bullets.append(clean) }
            } else {
                bullets.append(trimmed)
            }
        }
        return bullets.isEmpty ? ["Package updated with latest enhancements and optimizations."] : bullets
    }
}
